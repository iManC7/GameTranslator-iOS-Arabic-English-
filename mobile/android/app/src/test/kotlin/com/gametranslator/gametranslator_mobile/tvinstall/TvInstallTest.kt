// SPDX-License-Identifier: AGPL-3.0-only
package com.gametranslator.gametranslator_mobile.tvinstall

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.PipedInputStream
import java.io.PipedOutputStream
import java.math.BigInteger
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.security.KeyPairGenerator
import java.security.MessageDigest
import java.security.Signature
import java.security.interfaces.RSAPrivateKey
import java.security.interfaces.RSAPublicKey
import kotlin.concurrent.thread

class VersionsAndAddressTest {
    @Test
    fun comparesNumerically() {
        assertTrue(Versions.isNewer("0.10.0", "0.9.9"))
        assertTrue(Versions.isNewer("1.0.5", "1.0.0"))
        assertFalse(Versions.isNewer("1.0.0", "1.0.0"))
        assertFalse(Versions.isNewer("1.0", "1.0.0"))
    }

    @Test
    fun readsBundledVersions() {
        assertEquals("1.0.0", Versions.ofBundledFile("gametranslator-androidtv_1.0.0.apk"))
        assertEquals("1.0.5", Versions.ofBundledFile("tv-app/com.gametranslator.tv_1.0.5_all.ipk"))
        assertEquals("1.0.5", Versions.ofBundledFile("gametranslator-samsung_1.0.5.wgt"))
        assertNull(Versions.ofBundledFile("app.apk"))
    }

    @Test
    fun cleansTypedAddresses() {
        assertEquals("192.168.1.5", ManualAddress.normalize(" http://192.168.1.5:3000/x "))
        assertEquals("192.168.1.5", ManualAddress.normalize("192,168,1,5"))
        assertEquals("10.0.0.1", ManualAddress.normalize("010.0.0.1."))
        assertEquals("lgwebostv.local", ManualAddress.normalize("LGwebOSTV.local"))
        assertNull(ManualAddress.normalize("192.168.1.256"))
        assertNull(ManualAddress.normalize("192.168.1"))
        assertNull(ManualAddress.normalize("fe80::1"))
        assertNull(ManualAddress.normalize("1.2.3.4:abc"))
        assertNull(ManualAddress.normalize(""))
    }

    @Test
    fun scanTargetsSkipSelf() {
        val targets = LocalNetwork.scanTargets(listOf("192.168.1.20"))
        assertEquals(253, targets.size)
        assertFalse("192.168.1.20" in targets)
        assertTrue("192.168.1.254" in targets)
        assertEquals(253 + 253, LocalNetwork.scanTargets(listOf("192.168.1.20", "10.0.0.5")).size)
        assertTrue(LocalNetwork.isPrivate("172.20.1.1"))
        assertFalse(LocalNetwork.isPrivate("8.8.8.8"))
    }
}

class DiscoveryParsingTest {
    @Test
    fun readsLgSsdpReply() {
        val reply = "HTTP/1.1 200 OK\r\nCACHE-CONTROL: max-age=1800\r\nLOCATION: http://192.168.1.44:1990/abc\r\n" +
            "ST: urn:lge-com:service:webos-second-screen:1\r\nUSN: uuid:x\r\n\r\n"
        assertEquals("192.168.1.44", TvDiscovery.hostFromSsdpResponse(reply, TvDiscovery.LG_TARGET))
        assertNull(TvDiscovery.hostFromSsdpResponse(reply, TvDiscovery.SAMSUNG_TARGET))
    }

    @Test
    fun readsNames() {
        assertEquals("[LG] webOS TV UK7550", TvDiscovery.friendlyName("<root><device><friendlyName>[LG] webOS TV UK7550</friendlyName></device></root>"))
        assertEquals("Samsung \"Q\"", TvDiscovery.samsungName("{\"device\":{\"name\":\"Samsung &quot;Q&quot;\"}}"))
        assertNull(TvDiscovery.samsungName("bozuk"))
    }

    @Test
    fun parsesHttpReplies() {
        val chunked = "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n5\r\nhello\r\n3\r\nabc\r\n0\r\n\r\n"
        val response = LanHttp.parse(ByteArrayInputStream(chunked.toByteArray()))
        assertEquals(200, response.status)
        assertEquals("helloabc", response.text)
        val sized = LanHttp.parse(ByteArrayInputStream("HTTP/1.0 404 Not Found\r\nContent-Length: 2\r\n\r\nnoEXTRA".toByteArray()))
        assertEquals(404, sized.status)
        assertEquals("no", sized.text)
    }
}

class AdbProtocolTest {
    private val key = KeyPairGenerator.getInstance("RSA").apply { initialize(2048) }.generateKeyPair()

    @Test
    fun framesPackets() {
        val data = "host::\u0000".toByteArray()
        val packet = Adb.encode(Adb.CNXN, 0x01000001, 4096, data)
        val b = ByteBuffer.wrap(packet).order(ByteOrder.LITTLE_ENDIAN)
        assertEquals(Adb.CNXN, b.getInt(0))
        assertEquals(data.size, b.getInt(12))
        assertEquals(data.sumOf { it.toInt() and 0xFF }, b.getInt(16))
        assertEquals(Adb.CNXN.inv(), b.getInt(20))
        val read = Adb.read(ByteArrayInputStream(packet))
        assertEquals(Adb.CNXN, read.command)
        assertEquals(4096, read.arg1)
        assertArrayEquals(data, read.data)
        assertEquals("CNXN", Adb.name(Adb.CNXN))
    }

    @Test
    fun rejectsBrokenHeader() {
        val packet = Adb.encode(Adb.OKAY, 1, 2, ByteArray(0))
        packet[20] = 0
        try {
            Adb.read(ByteArrayInputStream(packet))
            fail()
        } catch (error: java.io.IOException) {
            // beklenen
        }
    }

    @Test
    fun signsTokenAsDigest() {
        // adb jetonu SHA-1 özeti yerine geçen değer olarak imzalar: SHA1(x) imzası, x'in SHA1withRSA imzasıyla aynıdır.
        val message = "jeton".toByteArray()
        val token = MessageDigest.getInstance("SHA-1").digest(message)
        val expected = Signature.getInstance("SHA1withRSA").run {
            initSign(key.private)
            update(message)
            sign()
        }
        assertArrayEquals(expected, Adb.signToken(key.private as RSAPrivateKey, token))
    }

    @Test
    fun encodesAndroidPublicKey() {
        val public = key.public as RSAPublicKey
        val blob = Adb.encodePublicKey(public)
        assertEquals(524, blob.size)
        val b = ByteBuffer.wrap(blob).order(ByteOrder.LITTLE_ENDIAN)
        assertEquals(64, b.getInt(0))
        val n0inv = b.getInt(4).toLong() and 0xFFFFFFFFL
        val modulus = BigInteger(1, blob.copyOfRange(8, 264).reversedArray())
        assertEquals(public.modulus, modulus)
        // n0inv = -1/n mod 2^32
        val r32 = BigInteger.ONE.shiftLeft(32)
        assertEquals(r32.subtract(BigInteger.ONE), BigInteger.valueOf(n0inv).multiply(public.modulus).mod(r32))
        val rr = BigInteger(1, blob.copyOfRange(264, 520).reversedArray())
        assertEquals(BigInteger.ONE.shiftLeft(4096).mod(public.modulus), rr)
        assertEquals(65537, b.getInt(520))
    }

    @Test
    fun syncFraming() {
        val packet = AdbClient.syncPacket("SEND", "/tmp/a,33188".toByteArray())
        assertEquals("SEND", String(packet, 0, 4))
        assertEquals(12, ByteBuffer.wrap(packet, 4, 4).order(ByteOrder.LITTLE_ENDIAN).int)
        assertEquals(8, AdbClient.syncHeader("DONE", 5).size)
    }

    /** Sahte TV ile uçtan uca: karşılaşma (onay sorusu dahil), komut ve veri akıtma. */
    @Test
    fun talksToFakeDevice() {
        val toDevice = PipedOutputStream()
        val deviceIn = PipedInputStream(toDevice, 1 shl 20)
        val fromDevice = PipedOutputStream()
        val clientIn = PipedInputStream(fromDevice, 1 shl 20)
        val received = ByteArrayOutputStream()
        val device = thread {
            fun send(command: Int, a0: Int, a1: Int, data: ByteArray = ByteArray(0)) {
                fromDevice.write(Adb.encode(command, a0, a1, data))
                fromDevice.flush()
            }
            assertEquals(Adb.CNXN, Adb.read(deviceIn).command)
            send(Adb.AUTH, Adb.AUTH_TOKEN, 0, ByteArray(20) { 7 })
            assertEquals(Adb.AUTH_SIGNATURE, Adb.read(deviceIn).arg0)
            send(Adb.AUTH, Adb.AUTH_TOKEN, 0, ByteArray(20) { 8 }) // imza tanınmadı
            val publicKey = Adb.read(deviceIn)
            assertEquals(Adb.AUTH_PUBLICKEY, publicKey.arg0)
            assertTrue(String(publicKey.data).endsWith("gametranslator@GameTranslator\u0000"))
            send(Adb.CNXN, 0x01000001, 8, "device::".toByteArray()) // küçük paket boyu: veri parçalara bölünmeli

            val open = Adb.read(deviceIn)
            assertEquals(Adb.OPEN, open.command)
            assertEquals("exec:cat\u0000", String(open.data))
            send(Adb.OKAY, 99, open.arg0)
            while (received.size() < 20) {
                val write = Adb.read(deviceIn)
                assertEquals(Adb.WRTE, write.command)
                assertTrue(write.data.size <= 8)
                received.write(write.data)
                send(Adb.OKAY, 99, open.arg0)
            }
            send(Adb.WRTE, 99, open.arg0, "Success\n".toByteArray())
            assertEquals(Adb.OKAY, Adb.read(deviceIn).command)
            send(Adb.CLSE, 99, open.arg0)
        }
        var approval = false
        val client = AdbClient(clientIn, toDevice, AdbOptions.ADB)
        client.handshake(key, onApprovalNeeded = { approval = true })
        assertTrue(approval)
        assertEquals(8, client.maxPayload)
        assertEquals("device::", client.banner)
        val payload = ByteArray(20) { it.toByte() }
        assertEquals("Success\n", client.run("exec:cat", payload))
        device.join(5000)
        assertArrayEquals(payload, received.toByteArray())
    }

    @Test
    fun readsDumpsysVersion() {
        assertEquals("1.0.0", AndroidTvInstaller.versionFromDumpsys("Packages:\n  versionCode=100 minSdk=21\n    versionName=1.0.0\n"))
        assertNull(AndroidTvInstaller.versionFromDumpsys("Unable to find package"))
        assertTrue(AndroidTvInstaller.isStorageProblem("Failure [INSTALL_FAILED_INSUFFICIENT_STORAGE]"))
        assertTrue(AndroidTvInstaller.needsLegacyInstall("/system/bin/sh: cmd: not found"))
        assertFalse(AndroidTvInstaller.needsLegacyInstall("Success"))
    }
}

class LgTest {
    private val aesKey = """
-----BEGIN RSA PRIVATE KEY-----
Proc-Type: 4,ENCRYPTED
DEK-Info: AES-128-CBC,AA662CDF46D1C77EFDF879AD733AD05F

minEkIZFLzDW4MKhHMm78YLlU5juIDfzxlukiHY8Hjj4zaGg44p2SNkAiEPqaELS
OxbsKzqZLnbH6NtvnadfaQFwx5os5WXZ/2jCBpuxPGlEpR/EN9ov9TxEWchKN06/
7Lpl6wDfxTlkkzLC/+K0FHPvi5mkrRPAjUAXKHNqVhhpL8SBHJZfyqafOifo+2Gb
o+oRR0pSiu6GtFePiBJu3vx37l4fADiRsYiEunauxZqWUDmhUc08oPL5Xvjkt7Ta
nMdTJwKOjK1raQv/EMnLbn7RompTcJ4z/sz14TBD4794mNXdFRjBEiPxJPXvwz5N
E7hMLryyy+2k5wuLuHYmpEmYLeVD8Z7aYuL0HduSjH2gqKJjh9eHNWU3RWqET0uL
9h62yOzX6tmGIOFIyykq6vrZaaCGQ0sfrPj1amAv2dpqn+yiTxjRcsOs/TzDnb2X
TS17jDKAF4lsIjNwLZQBE/apHk2ve69vUYgJ8wNRkw+Hj1a+r9hsuBeByv8o2th8
NW5o5y8buwBjHyVYaDUgaYGeBMJx9Zz7gVW9D4ai4LaJyI8nFTw61rEb9VooGjo7
w/rwvV6bmJMS9GSOfIrpvYp+ThGUO+yyj6wSyPGRrgH7o9atTikaSyMHIXsMgt9c
BenxGs0tYWsGSyYO2wreH4EFLXzOmaDNa3KiS1aeCmBbPDxj34XVYWcHh/mMAqZb
MrqK8gEmwCfNjv4YYiHFywQk+v7GYHIySCHe5v0Y6HGXBXD1ZUwb0Qh/v/Vf3fxu
ewX+DaXdj5u+qGmPtNGCxpuwEiv9w6G2dhP/VCTjU9HCqJ10r4Jf6XQxX439Ha2T
-----END RSA PRIVATE KEY-----
"""

    private val desKey = """
-----BEGIN RSA PRIVATE KEY-----
Proc-Type: 4,ENCRYPTED
DEK-Info: DES-EDE3-CBC,7C4E75EE9CCC14BA

GoQI3C3wNYZmACNrWBLIepmueNP2095KkjB2XOu/dIbRVNwLVK52lfEUR5Yh/6kc
u1FnbFAkui4oaqiYzEJ+nJJo2Wi1iSHq+TVposM+MC2JLfnXaIYp09226owmKH9G
Th841RUYwubP+lDjoe8BbUflbzmrdkXqfcXzVxmwHRrI3AahJyx1wXBERyW6D6WT
SszipsrbJovzFD5oMm06WSPsyeB1XqCaMFxlrT2TMmHH9Gq09KMFmuKGnrTYei0y
11Aep9rCKp2uex+RYhu3lUalV4HEXAbi4QpqxBy4Urln318/ZlfKSkDM/I7e8qU9
+CqtCWWxkr8ushM1k5t5FQtNEdOutXy13kaF8aG32sJwv9lQJLEmpW8s1rYZuXT8
90B4q99z5AFzn26658e4ArjTMxQYTl6Axic4qb2qJ3DggZezv4QL9t5lkaNx2Y3X
gpIxMFY1fWUmKq3CaAnboFIsCHMfdgkZFPoHFTjDlsoBdVVVoI1m7NLVTqDweuCa
LbfUsSNFqMwAS3VNULDT1qc5eLt45jyard45oC51b1ilfGKbstHYxo3acLGZfbiF
07dPUIW0ujRL8IbD7kQ9mJyN12IYHTYNG/1O6j/UFqSSqFzgY0Wxv3Hm67lt9Pg3
rJbeb9zmwOSHoCJAF8bg1Fpi0mkNhMueYqoIjPeMeZsMZ/eJ4NLxfIz2j9QDiux4
98/d4E4d3HLtoes+ayQ+w1yUiQO43+BpWqEebHiGwIe/1e+3nVQTA7OKGhKygg7U
+/yzTtqWwr+me8RfhjAfAupYx+cUZ+0iBc/XBmrwbkI7Bfn2YcIcUQ==
-----END RSA PRIVATE KEY-----
"""

    private fun derMd5(pem: String): String {
        val body = pem.lines().filterNot { it.startsWith("-----") }.joinToString("")
        val der = kotlin.io.encoding.Base64.Default.decode(body)
        return MessageDigest.getInstance("MD5").digest(der).joinToString("") { "%02x".format(it) }
    }

    @Test
    fun decryptsKeyServerKeys() {
        // Windows'taki LegacyPemKeyTests ile aynı anahtarlar ve beklenen sonuçlar (parola 2FEEB2).
        assertTrue(LegacyPemKey.isLegacyEncrypted(aesKey))
        val aes = LegacyPemKey.decrypt(aesKey.trimIndent(), "2FEEB2")
        assertTrue(aes.startsWith("-----BEGIN RSA PRIVATE KEY-----\n"))
        assertEquals("7924a944e4baf8734c2f9f9e9787edac", derMd5(aes))
        assertEquals("0ad305359ea07357d79b39fc083242fd", derMd5(LegacyPemKey.decrypt(desKey, "2FEEB2")))
    }

    @Test
    fun wrongPassphraseIsReported() {
        try {
            LegacyPemKey.decrypt(aesKey, "ABCDEF")
            fail()
        } catch (error: TvInstallException) {
            assertEquals(TvError.WRONG_PASSPHRASE, error.error)
        }
        // Küçük harfle yazılmış parola da kabul edilir.
        assertEquals("7924a944e4baf8734c2f9f9e9787edac", derMd5(LegacyPemKey.decryptWithCaseFallback(aesKey, " 2feeb2 ")))
    }

    @Test
    fun readsInstallReplies() {
        val ok = LgInstaller.parseInstallReplies("{\"returnValue\":true}\n{\"details\":{\"state\":\"installing\"}}\n{\"details\":{\"state\":\"installed\"}}\n")
        assertTrue(ok.installed)
        assertFalse(ok.failed)
        val failed = LgInstaller.parseInstallReplies("Error: x\n{\"details\":{\"state\":\"install failed\",\"reason\":\"no space\",\"errorCode\":-5}}")
        assertTrue(failed.failed)
        assertEquals("no space (errorCode -5)", failed.reason)
        val split = LgInstaller.parseInstallReplies("{\"returnValue\":\n false, \"errorText\":\"bad ipk\"}")
        assertTrue(split.failed)
        assertEquals("bad ipk", split.reason)
        assertFalse(LgInstaller.parseInstallReplies("").failed)
    }

    @Test
    fun buildsInstallCommand() {
        val command = LgInstaller.installCommand("/media/developer/temp/com.gametranslator.tv_1.0.5_all.ipk", 180)
        assertTrue(command.contains("luna-send-pub -i 'luna://com.webos.appInstallService/dev/install'"))
        assertTrue(command.contains("\"ipkUrl\":\"/media/developer/temp/com.gametranslator.tv_1.0.5_all.ipk\""))
        assertTrue(command.contains("sleep 210"))
        assertTrue(command.contains("while [ \$i -lt 180 ]"))
    }

    @Test
    fun smallHelpers() {
        assertEquals("1.0.5", LgInstaller.versionFromAppInfo("{ \"id\": \"com.gametranslator.tv\", \"version\" : \"1.0.5\" }"))
        assertEquals(999, LgInstaller.remainingHours("{\"remain\":\"999:58:40\"}"))
        assertEquals("a,b,ssh-rsa", JschShell.append("a,b", "b,ssh-rsa"))
        assertTrue(LgInstaller.isStorageProblem("ENOSPC"))
        assertEquals(LgInstaller.APP_INFO_PATH, "/media/developer/apps/usr/palm/applications/com.gametranslator.tv/appinfo.json")
    }

    /** Sahte kabuk: yükleme, boyut denetimi, kurulum ve sürüm doğrulaması sırası. */
    @Test
    fun installsThroughShell() {
        val commands = ArrayList<String>()
        var uploaded: ByteArray? = null
        val shell = object : RemoteShell {
            override fun run(command: String, input: ByteArray?): CommandResult {
                commands.add(command)
                return when {
                    command.contains("cat > ") -> { uploaded = input; CommandResult(0, "") }
                    command.startsWith("wc -c") -> CommandResult(0, "${uploaded?.size}\n")
                    command.contains("appInstallService") -> CommandResult(0, "{\"details\":{\"state\":\"installed\"}}")
                    command.startsWith("cat /media") -> CommandResult(0, "{\"version\":\"1.0.5\"}")
                    else -> CommandResult(0, "")
                }
            }

            override fun close() {}
        }
        LgInstaller(shell, Cancel(), pollIntervalMs = 1).install(ByteArray(1000) { 1 }, "com.gametranslator.tv_1.0.5_all.ipk", "1.0.5")
        assertEquals(1000, uploaded?.size)
        assertTrue(commands.last().startsWith("rm -f '/media/developer/temp/com.gametranslator.tv_1.0.5_all.ipk'"))
    }
}
