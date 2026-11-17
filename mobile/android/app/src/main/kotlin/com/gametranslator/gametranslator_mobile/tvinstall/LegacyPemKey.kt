// SPDX-License-Identifier: AGPL-3.0-only
package com.gametranslator.gametranslator_mobile.tvinstall

import java.security.GeneralSecurityException
import java.security.MessageDigest
import javax.crypto.Cipher
import javax.crypto.spec.IvParameterSpec
import javax.crypto.spec.SecretKeySpec
import kotlin.io.encoding.Base64

/**
 * LG Key Server'ın verdiği parolalı anahtarı (eski PEM biçimi: "Proc-Type: 4,ENCRYPTED") çözer ve parolasız PEM
 * döner (Windows'taki LegacyPemKey.cs). Parola, TV ekranındaki 6 karakterli "Passphrase"tir.
 */
object LegacyPemKey {
    fun isLegacyEncrypted(pem: String): Boolean = pem.contains("Proc-Type: 4,ENCRYPTED")

    /** Parola yanlışsa [TvError.WRONG_PASSPHRASE]. */
    fun decrypt(pem: String, passphrase: String): String {
        val header = Regex("-----BEGIN ([A-Z ]+?) PRIVATE KEY-----").find(pem)
        val info = Regex("DEK-Info:\\s*([A-Za-z0-9-]+),([0-9A-Fa-f]+)\\s*").find(pem)
        if (header == null || info == null) throw TvInstallException(TvError.INSTALL_FAILED, "PEM başlığı okunamadı")
        val kind = header.groupValues[1]
        val cipherName = info.groupValues[1].uppercase()
        val iv = hex(info.groupValues[2])
        val body = pem.substring(info.range.last + 1)
        val end = body.indexOf("-----END")
        if (end < 0) throw TvInstallException(TvError.INSTALL_FAILED, "PEM sonu bulunamadı")
        val encrypted = try {
            Base64.Default.decode(body.substring(0, end).filterNot { it.isWhitespace() })
        } catch (error: IllegalArgumentException) {
            throw TvInstallException(TvError.INSTALL_FAILED, "PEM gövdesi bozuk")
        }

        val (transformation, algorithm, keyLength) = when (cipherName) {
            "DES-EDE3-CBC" -> Triple("DESede/CBC/PKCS5Padding", "DESede", 24)
            "AES-128-CBC" -> Triple("AES/CBC/PKCS5Padding", "AES", 16)
            "AES-192-CBC" -> Triple("AES/CBC/PKCS5Padding", "AES", 24)
            "AES-256-CBC" -> Triple("AES/CBC/PKCS5Padding", "AES", 32)
            else -> throw TvInstallException(TvError.INSTALL_FAILED, "Desteklenmeyen şifre: $cipherName")
        }
        val key = deriveKey(passphrase.toByteArray(Charsets.UTF_8), iv.copyOfRange(0, 8), keyLength)
        val plain = try {
            Cipher.getInstance(transformation).run {
                init(Cipher.DECRYPT_MODE, SecretKeySpec(key, algorithm), IvParameterSpec(iv))
                doFinal(encrypted)
            }
        } catch (error: GeneralSecurityException) {
            // Yanlış parolada dolgu (padding) hemen hemen her zaman bozuk çıkar.
            throw TvInstallException(TvError.WRONG_PASSPHRASE)
        }
        // Dolgu tesadüfen tutsa bile çözülen veri bir ASN.1 dizisi (0x30) olmalı ve uzunluğu tutmalı.
        if (!looksLikeDer(plain)) throw TvInstallException(TvError.WRONG_PASSPHRASE)
        val base64 = Base64.Default.encode(plain)
        return buildString {
            append("-----BEGIN ").append(kind).append(" PRIVATE KEY-----\n")
            for (i in base64.indices step 64) append(base64, i, minOf(base64.length, i + 64)).append('\n')
            append("-----END ").append(kind).append(" PRIVATE KEY-----\n")
        }
    }

    /** TV parolayı büyük harfle gösterir; küçük harfle yazılmışsa büyük harfli hâli de denenir. */
    fun decryptWithCaseFallback(pem: String, passphrase: String): String {
        val typed = passphrase.trim()
        return try {
            decrypt(pem, typed)
        } catch (error: TvInstallException) {
            if (error.error != TvError.WRONG_PASSPHRASE || typed == typed.uppercase()) throw error
            decrypt(pem, typed.uppercase())
        }
    }

    /** OpenSSL'in EVP_BytesToKey'i (MD5, tek tur): eski PEM anahtarlarının parola türetmesi. */
    fun deriveKey(password: ByteArray, salt: ByteArray, length: Int): ByteArray {
        val key = java.io.ByteArrayOutputStream()
        var previous = ByteArray(0)
        while (key.size() < length) {
            val md5 = MessageDigest.getInstance("MD5")
            md5.update(previous)
            md5.update(password)
            md5.update(salt)
            previous = md5.digest()
            key.write(previous)
        }
        return key.toByteArray().copyOf(length)
    }

    fun looksLikeDer(data: ByteArray): Boolean {
        if (data.size < 4 || data[0] != 0x30.toByte()) return false
        val first = data[1].toInt() and 0xFF
        val length: Int
        val offset: Int
        if (first < 0x80) {
            length = first
            offset = 2
        } else {
            val bytes = first and 0x7F
            if (bytes == 0 || bytes > 3 || data.size < 2 + bytes) return false
            var value = 0
            for (i in 0 until bytes) value = (value shl 8) or (data[2 + i].toInt() and 0xFF)
            length = value
            offset = 2 + bytes
        }
        return offset + length == data.size
    }

    private fun hex(text: String): ByteArray = ByteArray(text.length / 2) { i -> text.substring(i * 2, i * 2 + 2).toInt(16).toByte() }
}
