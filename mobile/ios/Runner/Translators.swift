// SPDX-License-Identifier: AGPL-3.0-only
import Foundation

/// Bloklayan HTTP isteği (çeviri iş parçacığında çağrılır). Zaman aşımında ya da hatada nil.
private func fetch(_ request: URLRequest) -> (Int, Data)? {
  let semaphore = DispatchSemaphore(value: 0)
  var result: (Int, Data)?
  let task = URLSession.shared.dataTask(with: request) { data, response, _ in
    if let data, let http = response as? HTTPURLResponse { result = (http.statusCode, data) }
    semaphore.signal()
  }
  task.resume()
  if semaphore.wait(timeout: .now() + request.timeoutInterval + 1) == .timedOut {
    task.cancel()
    return nil
  }
  return result
}

/// Google'ın anahtarsız çeviri ucu (Android'deki GoogleGtxTranslator ve Windows'taki GoogleGtxTranslator ile aynı).
/// Bir uç yanıt vermezse ya da hız sınırına takılırsa sıradaki yedek uç denenir; hiçbiri çevirmezse nil döner.
final class GoogleGtxTranslator: TextTranslator {
  private let source: String
  private let target: String

  init(source: String, target: String) {
    self.source = source
    self.target = target
  }

  func translate(_ text: String) -> String? {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty { return "" }
    // Java'daki URLEncoder gibi: yalnız ASCII harf/rakam ve "-._*" olduğu gibi kalır (Türkçe harfler kodlanır).
    let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._*")
    guard let query = trimmed.addingPercentEncoding(withAllowedCharacters: allowed) else { return nil }
    let endpoints = [
      "https://translate.googleapis.com/translate_a/single?client=gtx&sl=\(source)&tl=\(target)&dt=t&q=\(query)",
      "https://translate.googleapis.com/translate_a/single?client=dict-chrome-ex&sl=\(source)&tl=\(target)&dt=t&q=\(query)",
      "https://clients5.google.com/translate_a/t?client=dict-chrome-ex&sl=\(source)&tl=\(target)&q=\(query)",
    ]
    for endpoint in endpoints {
      guard let url = URL(string: endpoint) else { continue }
      // Üç uç sırayla denenebildiği için süreler kısa tutulur: altyazı ekrandan gitmeden yedeğe geçilsin.
      var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 3.5)
      request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1",
                       forHTTPHeaderField: "User-Agent")
      guard let (status, data) = fetch(request), status == 200, let translated = Self.parse(data), !translated.isEmpty else { continue }
      return translated
    }
    return nil
  }

  /// İki yanıt biçimi vardır: `[[["çeviri","kaynak",...],...],...]` (cümle parçaları birleştirilir) ve yedek uçtaki
  /// `["çeviri"]`.
  static func parse(_ data: Data) -> String? {
    guard let root = try? JSONSerialization.jsonObject(with: data) as? [Any], let first = root.first else { return nil }
    let text: String
    if let sentences = first as? [Any] {
      text = sentences.compactMap { ($0 as? [Any])?.first as? String }.filter { $0 != "null" }.joined()
        .trimmingCharacters(in: .whitespacesAndNewlines)
    } else {
      text = (first as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    return text.isEmpty ? nil : decodeEntities(text)
  }

  /// Yanıttaki HTML varlıkları (&amp;, &#39; ...) düz metne çevrilir (Android'deki Html.fromHtml karşılığı).
  static func decodeEntities(_ text: String) -> String {
    guard text.contains("&") else { return text }
    let named = ["amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'", "nbsp": "\u{00A0}"]
    var out = ""
    var index = text.startIndex
    while index < text.endIndex {
      if text[index] == "&", let semicolon = text[index...].prefix(10).firstIndex(of: ";") {
        let name = String(text[text.index(after: index)..<semicolon])
        var replacement: String?
        if name.hasPrefix("#x") || name.hasPrefix("#X"), let code = UInt32(name.dropFirst(2), radix: 16), let scalar = Unicode.Scalar(code) {
          replacement = String(Character(scalar))
        } else if name.hasPrefix("#"), let code = UInt32(name.dropFirst()), let scalar = Unicode.Scalar(code) {
          replacement = String(Character(scalar))
        } else {
          replacement = named[name]
        }
        if let replacement {
          out += replacement
          index = text.index(after: semicolon)
          continue
        }
      }
      out.append(text[index])
      index = text.index(after: index)
    }
    return out
  }
}

/// DeepL API (kullanıcının kendi anahtarıyla). ":fx" ile biten anahtar ücretsiz uca gider.
final class DeepLTranslator: TextTranslator {
  private let key: String
  private let source: String
  private let target: String

  init(key: String, source: String, target: String) {
    self.key = key.trimmingCharacters(in: .whitespacesAndNewlines)
    self.source = source
    self.target = target
  }

  func translate(_ text: String) -> String? {
    let host = key.hasSuffix(":fx") ? "api-free.deepl.com" : "api.deepl.com"
    guard let url = URL(string: "https://\(host)/v2/translate") else { return nil }
    var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 6)
    request.httpMethod = "POST"
    request.setValue("DeepL-Auth-Key \(key)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    let body: [String: Any] = ["text": [text], "source_lang": source.uppercased(), "target_lang": target.uppercased()]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)
    guard let (status, data) = fetch(request), status == 200,
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let translations = json["translations"] as? [[String: Any]],
          let translated = translations.first?["text"] as? String,
          !translated.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
    return translated
  }
}

/// Önce [primary]; başarısız olursa [fallback].
final class FallbackTranslator: TextTranslator {
  private let primary: TextTranslator
  private let fallback: TextTranslator

  init(_ primary: TextTranslator, _ fallback: TextTranslator) {
    self.primary = primary
    self.fallback = fallback
  }

  func translate(_ text: String) -> String? { primary.translate(text) ?? fallback.translate(text) }
}

#if canImport(Translation)
import Translation
#endif

/// Cihaz üstünde çeviri: Apple'ın Translation çatısı (Android'deki ML Kit'in karşılığı). İnternetsiz çalışır.
/// iOS 26+ gerekir ve dil modelleri telefonda indirilmiş olmalı (Ayarlar › Uygulamalar › Çeviri › İndirilen Diller);
/// uygulama ekran açmadan modeli indiremez. Kullanılamıyorsa her çağrı nil döner.
final class AppleTranslator: TextTranslator {
  private let source: String
  private let target: String
  private let lock = NSLock()
  private var session: AnyObject?
  private var checked = false
  private var usable = false
  private let log: (Int, String) -> Void

  init(source: String, target: String, log: @escaping (Int, String) -> Void) {
    self.source = source
    self.target = target
    self.log = log
  }

  /// Dil çifti indirilmiş mi, oturum kurulabiliyor mu (bloklar; ilk çağrıda bir kez bakılır).
  func prepare() -> Bool {
    lock.lock(); defer { lock.unlock() }
    if checked { return usable }
    checked = true
    #if canImport(Translation)
    if #available(iOS 26.0, *) {
      let from = Locale.Language(identifier: source)
      let to = Locale.Language(identifier: target)
      let semaphore = DispatchSemaphore(value: 0)
      var status: LanguageAvailability.Status = .unsupported
      Task.detached {
        status = await LanguageAvailability().status(from: from, to: to)
        semaphore.signal()
      }
      _ = semaphore.wait(timeout: .now() + 10)
      switch status {
      case .installed:
        session = TranslationSession(installedSource: from, target: to)
        usable = true
        log(2, "cihaz üstü çeviri hazır (Apple, \(source)→\(target))")
      case .supported:
        log(1, "cihaz üstü çeviri için dil indirilmemiş: Ayarlar › Uygulamalar › Çeviri › İndirilen Diller'den \(source) ve \(target) indirilmeli")
      default:
        log(1, "cihaz üstü çeviri bu dil çiftini desteklemiyor: \(source)→\(target)")
      }
    } else {
      log(1, "cihaz üstü çeviri iOS 26 ister")
    }
    #endif
    return usable
  }

  func translate(_ text: String) -> String? {
    guard prepare() else { return nil }
    #if canImport(Translation)
    if #available(iOS 26.0, *), let session = session as? TranslationSession {
      let semaphore = DispatchSemaphore(value: 0)
      var result: String?
      Task.detached {
        result = try? await session.translate(text).targetText
        semaphore.signal()
      }
      if semaphore.wait(timeout: .now() + 8) == .timedOut { return nil }
      let trimmed = result?.trimmingCharacters(in: .whitespacesAndNewlines)
      return trimmed?.isEmpty == false ? trimmed : nil
    }
    #endif
    return nil
  }
}
