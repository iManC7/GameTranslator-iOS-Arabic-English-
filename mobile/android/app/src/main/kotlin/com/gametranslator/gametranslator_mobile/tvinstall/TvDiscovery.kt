// SPDX-License-Identifier: AGPL-3.0-only
package com.gametranslator.gametranslator_mobile.tvinstall

import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.Inet4Address
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.NetworkInterface
import java.net.Socket
import java.net.SocketTimeoutException
import java.net.URI
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

enum class TvBrand { LG, SAMSUNG, ANDROID }

/** Ağda bulunan TV. [ready]: kurulum portu açık (LG: geliştirici modu, Android: hata ayıklama, Samsung: sdb). */
data class FoundTv(val brand: TvBrand, val host: String, val name: String, val ready: Boolean) {
    fun toMap(): Map<String, Any?> = mapOf("brand" to brand.name.lowercase(), "host" to host, "name" to name, "ready" to ready)
}

/** Telefonun yerel ağ adresleri ve TV arama (Windows'taki LocalNetwork, LgDiscovery, SamsungDiscovery). */
object LocalNetwork {
    fun isPrivate(address: String): Boolean {
        val b = address.split('.').mapNotNull { it.toIntOrNull() }
        if (b.size != 4) return false
        return b[0] == 10 || (b[0] == 172 && b[1] in 16..31) || (b[0] == 192 && b[1] == 168)
    }

    /** Telefonun özel IPv4 adresleri; Wi-Fi (wlan) önce. */
    fun privateAddresses(): List<String> {
        val wifi = ArrayList<String>()
        val other = ArrayList<String>()
        try {
            for (network in NetworkInterface.getNetworkInterfaces()) {
                if (!network.isUp || network.isLoopback) continue
                for (address in network.inetAddresses) {
                    if (address !is Inet4Address || address.isLoopbackAddress) continue
                    val text = address.hostAddress ?: continue
                    if (!isPrivate(text)) continue
                    if (network.name.startsWith("wlan")) wifi.add(text) else other.add(text)
                }
            }
        } catch (error: Exception) {
            // ağ bilgisi okunamadı
        }
        return (wifi + other).distinct()
    }

    /** Her yerel adresin /24 ağındaki diğer adresler (kendisi hariç), tekrarsız. */
    fun scanTargets(locals: List<String>): List<String> {
        val seen = LinkedHashSet<String>()
        for (local in locals) {
            val b = local.split('.')
            if (b.size != 4) continue
            for (last in 1..254) {
                if (last.toString() == b[3]) continue
                seen.add("${b[0]}.${b[1]}.${b[2]}.$last")
            }
        }
        return seen.toList()
    }

    fun isPortOpen(host: String, port: Int, timeoutMs: Int): Boolean = try {
        Socket().use { it.connect(InetSocketAddress(host, port), timeoutMs) }
        true
    } catch (error: Exception) {
        false
    }

    /** Verilen portu açık olan adresler (64 bağlantı aynı anda). */
    fun hostsWithOpenPort(port: Int, timeoutMs: Int, cancel: Cancel): List<String> {
        val targets = scanTargets(privateAddresses())
        val found = ConcurrentHashMap.newKeySet<String>()
        val pool = Executors.newFixedThreadPool(64)
        try {
            for (host in targets) pool.execute { if (!cancel.cancelled && isPortOpen(host, port, timeoutMs)) found.add(host) }
            pool.shutdown()
            while (!pool.awaitTermination(100, TimeUnit.MILLISECONDS)) cancel.check()
        } finally {
            pool.shutdownNow()
        }
        return found.sortedBy { it.substringAfterLast('.').toIntOrNull() ?: 0 }
    }
}

object TvDiscovery {
    const val LG_TARGET = "urn:lge-com:service:webos-second-screen:1"
    const val SAMSUNG_TARGET = "urn:samsung.com:device:RemoteControlReceiver:1"

    /** SSDP yanıtından TV'nin adresini çıkarır; aranan servis değilse null. */
    fun hostFromSsdpResponse(response: String, searchTarget: String): String? {
        var location: String? = null
        var matches = false
        for (line in response.split("\r\n", "\n")) {
            val colon = line.indexOf(':')
            if (colon < 0) continue
            val name = line.substring(0, colon).trim().uppercase()
            val value = line.substring(colon + 1).trim()
            if (name == "LOCATION") location = value
            else if (name == "ST" || name == "NT") matches = matches || value == searchTarget
        }
        if (!matches || location == null) return null
        return runCatching { URI(location).host }.getOrNull()?.takeIf { it.isNotEmpty() }
    }

    /** Cihaz tanımındaki <friendlyName> (LG: http://TV:1990/). */
    fun friendlyName(xml: String): String? {
        val start = xml.indexOf("<friendlyName>")
        val end = if (start < 0) -1 else xml.indexOf("</friendlyName>", start)
        return if (end < 0) null else xml.substring(start + "<friendlyName>".length, end).trim().ifEmpty { null }
    }

    /** Samsung'un http://TV:8001/api/v2/ yanıtındaki TV adı. */
    fun samsungName(json: String): String? = runCatching {
        org.json.JSONObject(json).optJSONObject("device")?.optString("name")?.replace("&quot;", "\"")?.ifEmpty { null }
    }.getOrNull()

    fun ssdp(searchTarget: String, timeoutMs: Int, cancel: Cancel): List<String> {
        val hosts = LinkedHashSet<String>()
        try {
            DatagramSocket().use { socket ->
                cancel.track(socket)
                socket.soTimeout = 300
                val request = "M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMAN: \"ssdp:discover\"\r\nMX: 2\r\nST: $searchTarget\r\n\r\n"
                    .toByteArray(Charsets.US_ASCII)
                val target = InetAddress.getByName("239.255.255.250")
                repeat(2) { runCatching { socket.send(DatagramPacket(request, request.size, target, 1900)) } }
                val end = System.currentTimeMillis() + timeoutMs
                val buffer = ByteArray(4096)
                while (System.currentTimeMillis() < end && !cancel.cancelled) {
                    val packet = DatagramPacket(buffer, buffer.size)
                    try {
                        socket.receive(packet)
                    } catch (error: SocketTimeoutException) {
                        continue
                    }
                    hostFromSsdpResponse(String(packet.data, 0, packet.length, Charsets.UTF_8), searchTarget)?.let { hosts.add(it) }
                }
                cancel.untrack(socket)
            }
        } catch (error: Exception) {
            // çok noktaya yayın engelli olabilir; port taraması devreye girer
        }
        return hosts.toList()
    }

    fun findLg(cancel: Cancel): List<FoundTv> {
        var hosts = ssdp(LG_TARGET, 3000, cancel)
        // Bazı modemler çok noktaya yayını geçirmez: LG TV'ler 3000 portunda ikinci ekran servisini sunar.
        if (hosts.isEmpty()) hosts = LocalNetwork.hostsWithOpenPort(3000, 600, cancel)
        return hosts.map { host ->
            val name = runCatching { friendlyName(LanHttp.get(host, 1990, "/", 2000).text) }.getOrNull() ?: "LG TV"
            FoundTv(TvBrand.LG, host, name, LocalNetwork.isPortOpen(host, LgInstaller.SSH_PORT, 800))
        }
    }

    fun findSamsung(cancel: Cancel): List<FoundTv> {
        var hosts = ssdp(SAMSUNG_TARGET, 3000, cancel)
        if (hosts.isEmpty()) hosts = LocalNetwork.hostsWithOpenPort(8001, 600, cancel)
        return hosts.mapNotNull { host ->
            val name = runCatching { samsungName(LanHttp.get(host, 8001, "/api/v2/", 2000).text) }.getOrNull()
            if (name == null && hosts.size > 1) null else FoundTv(TvBrand.SAMSUNG, host, name ?: "Samsung TV", false)
        }
    }

    /** Android TV: hata ayıklaması açık TV'ler 5555'te yanıt verir. */
    fun findAndroid(cancel: Cancel): List<FoundTv> =
        LocalNetwork.hostsWithOpenPort(AndroidTvInstaller.DEFAULT_PORT, 800, cancel).map { FoundTv(TvBrand.ANDROID, it, "Android TV", true) }

    fun find(brand: TvBrand, cancel: Cancel): List<FoundTv> = when (brand) {
        TvBrand.LG -> findLg(cancel)
        TvBrand.SAMSUNG -> findSamsung(cancel)
        TvBrand.ANDROID -> findAndroid(cancel)
    }

    /** Kurulum portu açık mı (adım ekranlarındaki canlı denetim). */
    fun isReady(brand: TvBrand, host: String): Boolean = when (brand) {
        TvBrand.LG -> LocalNetwork.isPortOpen(host, LgInstaller.SSH_PORT, 1500)
        TvBrand.ANDROID -> LocalNetwork.isPortOpen(host.substringBefore(':'), host.substringAfter(':', "5555").toIntOrNull() ?: 5555, 1500)
        TvBrand.SAMSUNG -> LocalNetwork.isPortOpen(host, 26101, 1500)
    }

    /** LG Key Server açık mı? */
    fun isKeyServerOn(host: String): Boolean = LocalNetwork.isPortOpen(host, LgInstaller.KEY_PORT, 1500)
}
