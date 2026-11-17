// SPDX-License-Identifier: AGPL-3.0-only
import Foundation

/// Google Gemini ile yapay zekâ çevirisi, kullanıcının kendi (ücretsiz alınabilen) anahtarıyla. İstek, yönerge ve yanıt
/// okuma bilgisayar sürümüyle aynı (windows/src/GameTranslator.Translation/AiTranslator.cs → AiRequest; model listesi
/// windows/src/GameTranslator.Core/Resources/ai-models.json). Son birkaç satır bağlam olarak gider.
/// Ücretsiz anahtarın dakikalık sınırı vardır: sınıra yaklaşınca ya da Gemini "çok istek" deyince bu çevirmen bir süre
/// nil döner ve hat yedek motora (Google) geçer; altyazı beklemez.
final class GeminiTranslator: TextTranslator {
  /// ai-models.json'daki ilk (önerilen) model: hızlı, ücretsiz katmanda dakikada 15 istek.
  static let defaultModel = "gemini-3.5-flash-lite"
  static let requestsPerMinute = 15
  static let keyPage = "https://aistudio.google.com/apikey"

  static let systemPrompt =
    "You translate English video game subtitles into natural, spoken Turkish, the way people really talk. " +
    "Characters address each other informally (use \"sen\", not \"siz\") unless the line is clearly formal. " +
    "Keep character names, place names and speaker labels such as \"ATREUS:\" exactly as they are. " +
    "Keep line breaks. Keep the meaning and tone; do not add or leave out anything. " +
    "Reply with only the translation, no explanations, notes or quotes."

  private let key: String
  private let model: String
  private let log: (Int, String) -> Void
  private let lock = NSLock()
  private var sent: [Date] = []
  private var pausedUntil = Date.distantPast
  private var context: [(String, String)] = []
  private var warnedKey = false

  init(key: String, model: String = GeminiTranslator.defaultModel, log: @escaping (Int, String) -> Void) {
    self.key = key.trimmingCharacters(in: .whitespacesAndNewlines)
    self.model = model
    self.log = log
  }

  func translate(_ text: String) -> String? {
    guard !key.isEmpty, let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent") else { return nil }
    guard let previous = reserve() else { return nil }

    var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 6)
    request.httpMethod = "POST"
    request.setValue(key, forHTTPHeaderField: "x-goog-api-key")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    let body: [String: Any] = [
      "systemInstruction": ["parts": [["text": Self.systemPrompt]]],
      "contents": [["role": "user", "parts": [["text": Self.userMessage([text], context: previous)]]]],
      "generationConfig": ["maxOutputTokens": 1024],
    ]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    let semaphore = DispatchSemaphore(value: 0)
    var status = 0
    var data: Data?
    let task = URLSession.shared.dataTask(with: request) { d, response, _ in
      status = (response as? HTTPURLResponse)?.statusCode ?? 0
      data = d
      semaphore.signal()
    }
    task.resume()
    if semaphore.wait(timeout: .now() + 7) == .timedOut {
      task.cancel()
      return nil
    }
    switch status {
    case 200:
      break
    case 429:
      // Dakikalık ya da günlük hak doldu: bir dakika yedek motor kullanılır.
      pause(60, "Gemini sınırı doldu; bir dakika Google kullanılıyor")
      return nil
    case 400, 401, 403:
      lock.lock()
      let first = !warnedKey
      warnedKey = true
      lock.unlock()
      if first { log(0, "Gemini anahtarı kabul edilmedi (HTTP \(status)); anahtarı Ayarlar'dan kontrol edin") }
      pause(300, nil)
      return nil
    default:
      return nil
    }
    guard let data, let reply = Self.replyText(data), let translated = Self.translations(reply, count: 1)?.first,
          !translated.isEmpty else { return nil }
    remember(text, translated)
    return translated
  }

  /// Ayarlardaki "Kaydet ve dene": anahtarı tek bir deneme çevirisiyle sınar. (başarılı mı, kullanıcıya gösterilecek metin)
  static func check(key: String) -> (Bool, String) {
    let key = key.trimmingCharacters(in: .whitespacesAndNewlines)
    if key.isEmpty { return (false, "Önce anahtarı yapıştır.") }
    guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(defaultModel):generateContent") else {
      return (false, "Gemini adresi kurulamadı.")
    }
    var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
    request.httpMethod = "POST"
    request.setValue(key, forHTTPHeaderField: "x-goog-api-key")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    let body: [String: Any] = [
      "systemInstruction": ["parts": [["text": systemPrompt]]],
      "contents": [["role": "user", "parts": [["text": userMessage(["Let's get out of here before they find us."], context: [])]]]],
      "generationConfig": ["maxOutputTokens": 1024],
    ]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)
    let semaphore = DispatchSemaphore(value: 0)
    var status = 0
    var data: Data?
    let task = URLSession.shared.dataTask(with: request) { d, response, _ in
      status = (response as? HTTPURLResponse)?.statusCode ?? 0
      data = d
      semaphore.signal()
    }
    task.resume()
    if semaphore.wait(timeout: .now() + 12) == .timedOut {
      task.cancel()
      return (false, "Gemini yanıt vermedi. İnternet bağlantını kontrol et.")
    }
    switch status {
    case 200:
      if let data, let reply = replyText(data), let text = translations(reply, count: 1)?.first, !text.isEmpty {
        return (true, "Anahtar çalışıyor. Deneme çevirisi: \(text)")
      }
      return (false, "Gemini yanıt verdi ama çeviri okunamadı. Yeniden dene.")
    case 400, 401, 403:
      return (false, "Anahtar kabul edilmedi. Anahtarı eksiksiz kopyaladığından emin ol.")
    case 429:
      return (true, "Anahtar doğru, ama şu an sınır dolu. Bir dakika sonra çeviride kullanılır.")
    case 0:
      return (false, "Gemini'ye ulaşılamadı. İnternet bağlantını kontrol et.")
    default:
      return (false, "Gemini hata verdi (HTTP \(status)). Biraz sonra yeniden dene.")
    }
  }

  // MARK: - Sınır ve bağlam

  /// İstek hakkı varsa bağlamı döner; dakikalık sınıra gelindiyse nil (yedek motora geçilir).
  private func reserve() -> [(String, String)]? {
    lock.lock(); defer { lock.unlock() }
    let now = Date()
    if now < pausedUntil { return nil }
    sent.removeAll { now.timeIntervalSince($0) > 60 }
    if sent.count >= Self.requestsPerMinute { return nil }
    sent.append(now)
    return context
  }

  private func pause(_ seconds: TimeInterval, _ message: String?) {
    lock.lock()
    let wasPaused = Date() < pausedUntil
    pausedUntil = Date().addingTimeInterval(seconds)
    lock.unlock()
    if let message, !wasPaused { log(1, message) }
  }

  private func remember(_ source: String, _ translation: String) {
    lock.lock(); defer { lock.unlock() }
    context.append((source, translation))
    if context.count > 4 { context.removeFirst(context.count - 4) }
  }

  // MARK: - İstek ve yanıt (AiRequest ile aynı)

  /// Kullanıcı iletisi: önceki satırlar (yalnız bağlam) ve çevrilecek cümleler.
  static func userMessage(_ sentences: [String], context: [(String, String)]) -> String {
    var parts: [String] = []
    if !context.isEmpty {
      var lines = ["Previous subtitles, for context only (do not translate them again):"]
      for (source, translation) in context {
        lines.append("English: \(source)")
        lines.append("Turkish: \(translation)")
      }
      parts.append(lines.joined(separator: "\n"))
    }
    let list = (try? JSONSerialization.data(withJSONObject: sentences, options: [.withoutEscapingSlashes]))
      .map { String(decoding: $0, as: UTF8.self) } ?? "[]"
    parts.append("Translate each string in this JSON array into Turkish. Reply with only a JSON array of \(sentences.count) " +
                 "Turkish strings in the same order.\n\(list)")
    return parts.joined(separator: "\n\n")
  }

  /// candidates[0].content.parts[].text; "thought": true olan parçalar düşünmedir, alınmaz.
  static func replyText(_ data: Data) -> String? {
    guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let candidates = root["candidates"] as? [[String: Any]],
          let content = candidates.first?["content"] as? [String: Any],
          let parts = content["parts"] as? [[String: Any]] else { return nil }
    let text = parts.filter { ($0["thought"] as? Bool) != true }.compactMap { $0["text"] as? String }.joined()
    return text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : text
  }

  /// Yanıttaki JSON dizisi; tek cümlede model diziyi unutup düz metin dönerse o metin alınır.
  static func translations(_ text: String, count: Int) -> [String]? {
    var trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.hasPrefix("```") {
      trimmed = trimmed.split(separator: "\n", omittingEmptySubsequences: false).dropFirst()
        .filter { !$0.hasPrefix("```") }.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    if let start = trimmed.firstIndex(of: "["), let end = trimmed.lastIndex(of: "]"), start < end,
       let array = try? JSONSerialization.jsonObject(with: Data(trimmed[start...end].utf8)) as? [Any],
       array.allSatisfy({ $0 is String }) {
      guard array.count == count else { return nil }
      return array.map { ($0 as! String).trimmingCharacters(in: .whitespacesAndNewlines) }
    }
    guard count == 1 else { return nil }
    return [trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "\"“”"))]
  }
}
