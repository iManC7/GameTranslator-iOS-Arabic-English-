// SPDX-License-Identifier: AGPL-3.0-only
package com.gametranslator.gametranslator_mobile.tvinstall

import java.io.EOFException
import java.io.File
import java.io.IOException
import java.io.InputStream
import java.math.BigInteger
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.security.KeyFactory
import java.security.KeyPair
import java.security.KeyPairGenerator
import java.security.Signature
import java.security.interfaces.RSAPrivateCrtKey
import java.security.interfaces.RSAPrivateKey
import java.security.interfaces.RSAPublicKey
import java.security.spec.PKCS8EncodedKeySpec
import java.security.spec.RSAPublicKeySpec

/**
 * ADB'nin ağ protokolünün paket biçimi ve kimlik doğrulaması (AOSP packages/modules/adb, protocol.txt). Samsung'un
 * sdb'si aynı çerçeveyi kullanır. Windows'taki AdbConnection.cs'nin saf (soketsiz) kısmı.
 */
object Adb {
    const val CNXN = 0x4e584e43
    const val AUTH = 0x48545541
    const val OPEN = 0x4e45504f
    const val OKAY = 0x59414b4f
    const val CLSE = 0x45534c43
    const val WRTE = 0x45545257

    const val AUTH_TOKEN = 1
    const val AUTH_SIGNATURE = 2
    const val AUTH_PUBLICKEY = 3

    const val HEADER = 24
    private const val MAX_DATA = 1024 * 1024

    class Packet(val command: Int, val arg0: Int, val arg1: Int, val data: ByteArray) {
        override fun toString() = "${name(command)}($arg0, $arg1, ${data.size} bayt)"
    }

    fun name(command: Int): String = String(ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN).putInt(command).array(), Charsets.US_ASCII)

    fun encode(command: Int, arg0: Int, arg1: Int, data: ByteArray, offset: Int = 0, length: Int = data.size): ByteArray {
        val buffer = ByteBuffer.allocate(HEADER + length).order(ByteOrder.LITTLE_ENDIAN)
        var sum = 0
        for (i in offset until offset + length) sum += data[i].toInt() and 0xFF
        buffer.putInt(command).putInt(arg0).putInt(arg1).putInt(length).putInt(sum).putInt(command.inv())
        buffer.put(data, offset, length)
        return buffer.array()
    }

    /**
     * Bir paket okur. Sağlama toplamı denetlenmez: yeni ADB sürümleri (0x01000001) onu sıfır gönderir. Bozuk başlık
     * ya da aşırı uzunluk [IOException] verir.
     */
    fun read(input: InputStream): Packet {
        val header = readExactly(input, HEADER)
        val b = ByteBuffer.wrap(header).order(ByteOrder.LITTLE_ENDIAN)
        val command = b.getInt(0)
        val arg0 = b.getInt(4)
        val arg1 = b.getInt(8)
        val length = b.getInt(12)
        val magic = b.getInt(20)
        if (magic != command.inv() || length < 0 || length > MAX_DATA) throw IOException("ADB paketi bozuk (${Integer.toHexString(command)})")
        return Packet(command, arg0, arg1, readExactly(input, length))
    }

    fun readExactly(input: InputStream, count: Int): ByteArray {
        val bytes = ByteArray(count)
        var read = 0
        while (read < count) {
            val n = input.read(bytes, read, count - read)
            if (n < 0) throw EOFException("bağlantı kapandı")
            read += n
        }
        return bytes
    }

    private val SHA1_DIGEST_INFO = byteArrayOf(
        0x30, 0x21, 0x30, 0x09, 0x06, 0x05, 0x2b, 0x0e, 0x03, 0x02, 0x1a, 0x05, 0x00, 0x04, 0x14,
    )

    /**
     * adb, TV'nin gönderdiği 20 baytlık jetonu SHA-1 özeti yerine geçen değer olarak imzalar (RSA_sign NID_sha1): jeton
     * yeniden özetlenmez. Sağlayıcıdan bağımsız olsun diye PKCS#1 v1.5 dolgusu elle kurulur.
     */
    fun signToken(key: RSAPrivateKey, token: ByteArray): ByteArray {
        val k = (key.modulus.bitLength() + 7) / 8
        val t = SHA1_DIGEST_INFO + token
        require(t.size + 11 <= k) { "jeton çok uzun" }
        val em = ByteArray(k)
        em[1] = 0x01
        for (i in 2 until k - t.size - 1) em[i] = 0xFF.toByte()
        System.arraycopy(t, 0, em, k - t.size, t.size)
        val signature = BigInteger(1, em).modPow(key.privateExponent, key.modulus)
        return unsigned(signature, k)
    }

    /** sdb (Samsung) jetonu SHA-1 ile özetleyip imzalar (TizenSdb'deki SignData). */
    fun signSha1(key: RSAPrivateKey, token: ByteArray): ByteArray =
        Signature.getInstance("SHA1withRSA").run {
            initSign(key)
            update(token)
            sign()
        }

    /** Android'in kendi RSA açık anahtar biçimi (system/core/libcrypto_utils android_pubkey.c). */
    fun encodePublicKey(key: RSAPublicKey): ByteArray {
        val words = 64
        require(key.modulus.bitLength() == 2048) { "ADB yalnız 2048 bitlik RSA anahtarını kabul eder" }
        val n = key.modulus
        val r32 = BigInteger.ONE.shiftLeft(32)
        val n0inv = r32.subtract(n.mod(r32).modInverse(r32)).toLong()
        val rr = BigInteger.ONE.shiftLeft(words * 32).modPow(BigInteger.valueOf(2), n)
        val buffer = ByteBuffer.allocate(4 + 4 + words * 4 + words * 4 + 4).order(ByteOrder.LITTLE_ENDIAN)
        buffer.putInt(words).putInt(n0inv.toInt())
        buffer.put(littleEndian(n, words * 4))
        buffer.put(littleEndian(rr, words * 4))
        buffer.putInt(key.publicExponent.toInt())
        return buffer.array()
    }

    private fun littleEndian(value: BigInteger, length: Int): ByteArray = unsigned(value, length).reversedArray()

    /** İşaretsiz, büyük sonlu, tam [length] bayt. */
    private fun unsigned(value: BigInteger, length: Int): ByteArray {
        val raw = value.toByteArray()
        val out = ByteArray(length)
        val start = maxOf(0, raw.size - length)
        System.arraycopy(raw, start, out, length - (raw.size - start), raw.size - start)
        return out
    }

    /** Açık anahtar satırı: base64 + boşluk + ad + NUL. */
    fun publicKeyPayload(key: RSAPublicKey, name: String): ByteArray =
        (kotlin.io.encoding.Base64.Default.encode(encodePublicKey(key)) + " " + name + "\u0000").toByteArray(Charsets.US_ASCII)

    /**
     * Bu telefonun ADB anahtarı (PKCS#8). TV onayı bu anahtara verilir; anahtar değişirse TV yeniden sorar. Bozuk ya
     * da yoksa yenisi üretilir.
     */
    fun loadOrCreateKey(file: File): KeyPair {
        if (file.isFile) {
            try {
                val factory = KeyFactory.getInstance("RSA")
                val private = factory.generatePrivate(PKCS8EncodedKeySpec(file.readBytes())) as RSAPrivateCrtKey
                if (private.modulus.bitLength() == 2048) {
                    val public = factory.generatePublic(RSAPublicKeySpec(private.modulus, private.publicExponent))
                    return KeyPair(public, private)
                }
            } catch (error: Exception) {
                // bozuk dosya: yenisi üretilir
            }
        }
        val pair = KeyPairGenerator.getInstance("RSA").apply { initialize(2048) }.generateKeyPair()
        file.parentFile?.mkdirs()
        val temp = File(file.path + ".tmp")
        temp.writeBytes(pair.private.encoded)
        if (!temp.renameTo(file)) {
            file.delete()
            temp.renameTo(file)
        }
        return pair
    }
}
