// SPDX-License-Identifier: AGPL-3.0-only
// Android'deki core/PackTranslation.kt'nin Swift portu; onunla birebir aynı tutulmalıdır.
import Foundation

/// Hattın oyun paketi araması: baştaki konuşmacı işareti ("- ", ">>") [PrefixTranslator]'daki gibi ayrılır, gövde
/// pakette aranır ([PackLookup]: etiket, satır, cümle ve bulanık arama), işaret Türkçenin başına olduğu gibi geri konur.
/// Paket anahtarı noktalamayı yok saydığı için ">>" ayrılmazsa satır bulunur ama işaret Türkçeden düşerdi.
enum PackTranslation {
  /// Paketler yalnız İngilizce oyunlar ve Türkçe çeviri içindir.
  static func applies(_ sourceLanguage: String, _ targetLanguage: String) -> Bool {
    sourceLanguage == "en" && targetLanguage == "tr"
  }

  static func match(_ text: String, _ lookup: (String) -> PackMatch?) -> PackMatch? {
    let (prefix, rest) = SpeakerPrefix.split(text)
    if prefix.isEmpty { return lookup(KotlinText.trim(text)) }
    if rest.isEmpty { return nil }
    guard let found = lookup(rest) else { return nil }
    return PackMatch(text: prefix + found.text, packId: found.packId)
  }

  static func match(_ library: GamePackLibrary, _ text: String) -> PackMatch? {
    match(text) { PackLookup.match(library, $0) }
  }
}
