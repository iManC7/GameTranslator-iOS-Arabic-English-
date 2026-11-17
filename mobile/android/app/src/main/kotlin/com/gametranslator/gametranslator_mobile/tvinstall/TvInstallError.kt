// SPDX-License-Identifier: AGPL-3.0-only
package com.gametranslator.gametranslator_mobile.tvinstall

/**
 * TV uygulamasını kurarken çıkan sorunlar (LG, Samsung ve Android TV ortak). Windows'taki DevModeError ile aynı
 * anlamlardadır; arayüz her birini Türkçe bir açıklama ve çözümle gösterir (lib/tv_install.dart).
 */
enum class TvError {
    /** TV yanıt vermedi: kapalı, başka ağda ya da geliştirici modu/hata ayıklama kapalı. */
    UNREACHABLE,
    /** LG: Developer Mode uygulamasında Key Server kapalı. */
    KEY_SERVER_OFF,
    /** LG: TV'deki parola yanlış yazıldı. */
    WRONG_PASSPHRASE,
    /** LG: TV anahtarı kabul etmedi (geliştirici modu yeniden açılmış, anahtar değişmiş). */
    KEY_REFUSED,
    INSTALL_FAILED,
    /** Samsung: TV Tizen 5.0'dan (2019) eski. */
    TOO_OLD,
    /** Samsung hesabıyla giriş tamamlanmadı. */
    SIGN_IN_FAILED,
    /** Samsung TV'ye özel sertifikayı vermedi. */
    CERTIFICATE_FAILED,
    /** Android: TV'de hata ayıklama izni verilmedi. */
    NOT_APPROVED,
    /** TV kurulumda yer kalmadığını söyledi. */
    NOT_ENOUGH_SPACE,
    /** Samsung: Geliştirici modunda girilen "Host PC IP" bu telefonun adresi değil. */
    WRONG_HOST_IP,
    /** Kurulum sırasında TV bağlantısı koptu. */
    CONNECTION_LOST,
    /** Uygulamanın içinde bu TV'nin paketi yok (derleme hatası). */
    PACKAGE_MISSING,
    /** Kullanıcı vazgeçti. */
    CANCELLED,
}

/** [detail]: sorunu bulmak için ayrıntı (TV'nin çıktısı); günlüğe yazılır, arayüzde "TV'nin söylediği" olarak görünür. */
class TvInstallException(val error: TvError, val detail: String? = null, cause: Throwable? = null) :
    Exception(if (detail == null) error.name else "${error.name}: $detail", cause)
