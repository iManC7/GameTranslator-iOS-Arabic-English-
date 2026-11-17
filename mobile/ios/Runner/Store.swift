// SPDX-License-Identifier: AGPL-3.0-only
import Foundation
import Security

/// PS5'e kaydedilmiş bu telefonun bağlantı bilgileri.
struct Console: Equatable {
  var host: String
  var name: String
  var registKey: Data
  var morning: Data

  /// Uyandırma için kayıt anahtarının onaltılık değeri (anahtar ASCII onaltılık, sıfırla doldurulmuş).
  var wakeCredential: UInt64? {
    let end = registKey.firstIndex(of: 0) ?? registKey.endIndex
    guard let text = String(data: registKey[registKey.startIndex..<end], encoding: .ascii) else { return nil }
    return UInt64(text, radix: 16)
  }
}

/// Altyazının oyunda arandığı bölge, ekrana oranla (0–1).
struct Region: Equatable {
  var top = 0.62
  var bottom = 0.97
  var left = 0.14
  var right = 0.86
}

/// Uygulama ayarları; Android'deki Settings ile aynı alanlar ve aynı JSON biçimi.
struct Settings: Equatable {
  var region = Region()
  var sourceLanguage = "en"
  var targetLanguage = "tr"
  /// google (çevrimiçi, anahtarsız), mlkit (cihaz üstünde), deepl (kendi anahtarınla)
  var engine = "google"
  var deepLKey = ""
  /// Google Gemini anahtarı (aistudio.google.com/apikey; yalnız iOS'ta, bilgisayar sürümündeki gibi).
  var geminiKey = ""
  var style = SubtitleStyle()
  /// PS5 dinlenme modundaysa uyandır.
  var autoWake = true
  /// Terim sözlüğü, bilgisayardaki sözlük dosyalarıyla aynı JSON biçiminde; boşsa sözlük yok.
  var glossary = ""
  /// Oyun paketleri (İngilizce→Türkçe).
  var packsEnabled = true
  /// Satır sonundaki oyun düğmesi yazıları ("RESUME BA", "SKIP") çeviriye gitmez (yalnız iOS'ta, ayarlardan kapatılır).
  var hideButtonHints = true
  /// Elle seçilen oyunun paketi (bilgisayar sürümündeki "Oyun" seçimi); boş: otomatik.
  var packChoice = ""

  /// Sözlük metni çözülmüş hâliyle; boş ya da bozuksa boş sözlük (Android'deki parsedGlossary).
  func parsedGlossary() -> Glossary {
    if glossary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return .EMPTY }
    guard let data = glossary.data(using: .utf8),
          let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return .EMPTY }
    var terms: [(String, String)] = []
    if let map = root["terms"] as? [String: Any] {
      // JSON nesnesinin sırası korunmaz; Android'deki JSONObject de sıra garantisi vermez.
      for (key, value) in map { if let text = value as? String { terms.append((key, text)) } }
    }
    let keep = (root["keep"] as? [Any])?.compactMap { $0 as? String } ?? []
    return Glossary.of(pairs: terms, keep: keep)
  }

  func toJson() -> [String: Any] {
    [
      "region": ["top": region.top, "bottom": region.bottom, "left": region.left, "right": region.right],
      "sourceLanguage": sourceLanguage,
      "targetLanguage": targetLanguage,
      "engine": engine,
      "deepLKey": deepLKey,
      "geminiKey": geminiKey,
      "autoWake": autoWake,
      "glossary": glossary,
      "packsEnabled": packsEnabled,
      "hideButtonHints": hideButtonHints,
      "packChoice": packChoice,
      "style": [
        "fontSize": style.fontSize, "bottomPercent": style.bottomPercent, "placement": style.placement,
        "background": style.background, "bold": style.bold, "textColor": style.textColor,
        "displayMode": style.displayMode, "stackPrevious": style.stackPrevious, "speakerColor": style.speakerColor,
      ] as [String: Any],
    ]
  }

  func toJsonString() -> String {
    guard let data = try? JSONSerialization.data(withJSONObject: toJson(), options: [.sortedKeys]) else { return "{}" }
    return String(decoding: data, as: UTF8.self)
  }

  /// Eksik ya da hatalı alanlar varsayılanla dolar; bölge Android'deki gibi sınırlanır.
  static func fromJson(_ json: [String: Any]?) -> Settings {
    let d = Settings()
    guard let json else { return d }
    let r = json["region"] as? [String: Any]
    let s = json["style"] as? [String: Any]
    let top = clamp(double(r?["top"], d.region.top), 0, 0.95)
    let left = clamp(double(r?["left"], d.region.left), 0, 0.95)
    var out = d
    out.region = Region(
      top: top,
      bottom: clamp(double(r?["bottom"], d.region.bottom), top + 0.05, 1),
      left: left,
      right: clamp(double(r?["right"], d.region.right), left + 0.05, 1))
    out.sourceLanguage = string(json["sourceLanguage"], d.sourceLanguage)
    out.targetLanguage = string(json["targetLanguage"], d.targetLanguage)
    out.engine = string(json["engine"], d.engine)
    out.deepLKey = string(json["deepLKey"], "")
    out.geminiKey = string(json["geminiKey"], "")
    out.autoWake = bool(json["autoWake"], true)
    out.glossary = string(json["glossary"], "")
    out.packsEnabled = bool(json["packsEnabled"], true)
    out.hideButtonHints = bool(json["hideButtonHints"], true)
    out.packChoice = string(json["packChoice"], "")
    let ds = d.style
    out.style = SubtitleStyle(
      fontSize: int(s?["fontSize"], ds.fontSize),
      bottomPercent: int(s?["bottomPercent"], ds.bottomPercent),
      placement: string(s?["placement"], ds.placement),
      background: int(s?["background"], ds.background),
      bold: bool(s?["bold"], ds.bold),
      textColor: string(s?["textColor"], ds.textColor),
      displayMode: string(s?["displayMode"], ds.displayMode),
      stackPrevious: bool(s?["stackPrevious"], ds.stackPrevious),
      speakerColor: bool(s?["speakerColor"], ds.speakerColor))
    return out
  }

  static func fromJsonString(_ text: String?) -> Settings? {
    guard let data = text?.data(using: .utf8),
          let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
    return fromJson(object)
  }

  private static func clamp(_ value: Double, _ low: Double, _ high: Double) -> Double { min(max(value, low), high) }

  private static func double(_ value: Any?, _ fallback: Double) -> Double {
    if let n = value as? NSNumber, !(value is Bool) { let v = n.doubleValue; return v.isFinite ? v : fallback }
    if let t = value as? String, let v = Double(t) { return v }
    return fallback
  }

  private static func int(_ value: Any?, _ fallback: Int) -> Int {
    if let n = value as? NSNumber, !(value is Bool) { return n.intValue }
    if let t = value as? String, let v = Double(t) { return Int(v) }
    return fallback
  }

  private static func bool(_ value: Any?, _ fallback: Bool) -> Bool {
    if let b = value as? Bool { return b }
    if let t = value as? String { if t.lowercased() == "true" { return true }; if t.lowercased() == "false" { return false } }
    return fallback
  }

  private static func string(_ value: Any?, _ fallback: String) -> String {
    if let t = value as? String { return t }
    if let n = value as? NSNumber { return n.stringValue }
    return fallback
  }
}

/// Uygulamaya özel kayıtlar. PSN hesap kimliği ve PS5 kayıt anahtarı Anahtar Zinciri'nde (yalnız bu cihazda,
/// yedeklere gitmez), diğer ayarlar UserDefaults'ta.
final class Store {
  static let shared = Store()

  private let defaults = UserDefaults.standard
  private let service = "com.gametranslator.mobile"

  var accountId: Data? {
    get { keychain("accountId").flatMap { $0.count == 8 ? $0 : nil } }
    set { setKeychain("accountId", newValue) }
  }

  var console: Console? {
    get {
      guard let data = keychain("console"),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let host = json["host"] as? String, !host.isEmpty,
            let key = (json["registKey"] as? String).flatMap({ Data(base64Encoded: $0) }), key.count == 16,
            let morning = (json["morning"] as? String).flatMap({ Data(base64Encoded: $0) }), morning.count == 16
      else { return nil }
      return Console(host: host, name: json["name"] as? String ?? "PS5", registKey: key, morning: morning)
    }
    set {
      guard let value = newValue else { return setKeychain("console", nil) }
      let json: [String: Any] = ["host": value.host, "name": value.name,
                                 "registKey": value.registKey.base64EncodedString(), "morning": value.morning.base64EncodedString()]
      setKeychain("console", try? JSONSerialization.data(withJSONObject: json))
    }
  }

  /// Tanıtım ekranları bir kez gösterildi mi?
  var introSeen: Bool {
    get { defaults.bool(forKey: "introSeen") }
    set { defaults.set(newValue, forKey: "introSeen") }
  }

  var settings: Settings {
    get { Settings.fromJsonString(defaults.string(forKey: "settings")) ?? Settings() }
    set { defaults.set(newValue.toJsonString(), forKey: "settings") }
  }

  // MARK: - Anahtar Zinciri

  private func query(_ key: String) -> [String: Any] {
    [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: key]
  }

  private func keychain(_ key: String) -> Data? {
    var q = query(key)
    q[kSecReturnData as String] = true
    q[kSecMatchLimit as String] = kSecMatchLimitOne
    var result: AnyObject?
    guard SecItemCopyMatching(q as CFDictionary, &result) == errSecSuccess else { return nil }
    return result as? Data
  }

  private func setKeychain(_ key: String, _ value: Data?) {
    SecItemDelete(query(key) as CFDictionary)
    guard let value else { return }
    var q = query(key)
    q[kSecValueData as String] = value
    q[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    SecItemAdd(q as CFDictionary, nil)
  }
}
