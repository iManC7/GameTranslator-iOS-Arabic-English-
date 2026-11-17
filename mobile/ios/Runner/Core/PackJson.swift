// SPDX-License-Identifier: AGPL-3.0-only
// CouchSubs'tan uyarlandı: CouchSubs (Copyright (C) 2026 Sinan Yorulmaz), AGPL-3.0, yazarının izniyle.
// Android'deki core/PackJson.kt'nin Swift portu; onunla birebir aynı tutulmalıdır.
import Foundation

/// Oyun paketi JSON'unun akış hâlinde okunması: `entries` nesnesindeki her satır nesne ağacı kurulmadan [parse]'ın geri
/// çağrısına verilir (GTA V paketi tek başına ~190 bin satır). Kökteki dize alanları (`id`, `title` ya da düz biçimde
/// satırların kendisi) ayrıca döner.
enum PackJson {
  struct Result {
    /// Kökte `entries` nesnesi vardı (sarılı biçim).
    let wrapped: Bool
    let format: Double?
    let id: String?
    let title: String?
    /// Kökteki dize alanları sırayla (düz biçimde satırlar).
    let rootStrings: [(String, String)]
    /// Biçim 2'deki "fuzzy" nesnesi (bulanık imzalar); yoksa null.
    let fuzzy: Fuzzy?
  }

  /// "fuzzy" nesnesi: base64 alanlar doğrudan baytlara açılır (ara String yok); eksik ya da bozuk alan null.
  struct Fuzzy {
    let version: Double?
    let count: Double?
    let mask: [UInt8]?
    let lengths: [UInt8]?
    let blooms: [UInt8]?
  }

  /// [onSegment]: biçim 2'deki "segments" nesnesinin satırları (oyunun ayrı gösterdiği parçalar).
  /// Kotlin'de dizinin sonunu aşan okuma (IndexOutOfBoundsException) InvalidPackException olur; burada her okuma
  /// sınır denetimlidir ve aynı hatayı fırlatır.
  static func parse(
    _ data: UnsafeBufferPointer<UInt8>, _ onEntry: (String, String) -> Void,
    _ onSegment: (String, String) -> Void = { _, _ in }
  ) throws -> Result {
    try Reader(data).root(onEntry, onSegment)
  }

  static func parse(
    _ data: [UInt8], _ onEntry: (String, String) -> Void, _ onSegment: (String, String) -> Void = { _, _ in }
  ) throws -> Result {
    try data.withUnsafeBufferPointer { try parse($0, onEntry, onSegment) }
  }

  private static let QUOTE: Int = 0x22
  private static let BACKSLASH: Int = 0x5C

  private final class Reader {
    private let data: UnsafeBufferPointer<UInt8>
    private var position = 0
    private var buffer: [UInt8] = []

    init(_ data: UnsafeBufferPointer<UInt8>) {
      self.data = data
      buffer.reserveCapacity(256)
    }

    func root(_ onEntry: (String, String) -> Void, _ onSegment: (String, String) -> Void) throws -> Result {
      skipSpace()
      if peek() != 0x7B {
        throw InvalidPackException(peek() == 0x5B ? "Paket JSON nesnesi değil" : "Paket JSON değil")
      }
      position += 1
      var wrapped = false
      var format: Double?
      var fuzzy: Fuzzy?
      var strings: [(String, String)] = []
      try members { name in
        if name == "fuzzy" && peek() == 0x7B {
          position += 1
          fuzzy = try self.fuzzy()
        } else if name == "entries" && peek() == 0x7B {
          wrapped = true
          position += 1
          try members { key in if peek() == QUOTE { onEntry(key, try string()) } else { try skipValue() } }
        } else if name == "segments" && peek() == 0x7B {
          position += 1
          try members { key in if peek() == QUOTE { onSegment(key, try string()) } else { try skipValue() } }
        } else if name == "format" && isNumberStart(peek()) {
          format = try number()
        } else if peek() == QUOTE {
          strings.append((name, try string()))
        } else {
          try skipValue()
        }
      }
      skipSpace()
      if position != data.count { throw InvalidPackException("Paket JSON değil") }
      let id = strings.last { $0.0 == "id" }?.1
      let title = strings.last { $0.0 == "title" }?.1
      return Result(wrapped: wrapped, format: format, id: id, title: title, rootStrings: strings, fuzzy: fuzzy)
    }

    /// `{` okunmuş "fuzzy" nesnesi.
    private func fuzzy() throws -> Fuzzy {
      var version: Double?
      var count: Double?
      var bytes: [String: [UInt8]?] = [:]
      try members { name in
        if (name == "version" || name == "count") && isNumberStart(peek()) {
          let value = try number()
          if name == "version" { version = value } else { count = value }
        } else if (name == "mask" || name == "lengths" || name == "blooms") && peek() == QUOTE {
          bytes[name] = .some(try base64())
        } else {
          try skipValue()
        }
      }
      return Fuzzy(version: version, count: count, mask: bytes["mask"] ?? nil, lengths: bytes["lengths"] ?? nil,
                   blooms: bytes["blooms"] ?? nil)
    }

    /// base64 dize: kaçış yoksa kaynak baytlardan doğrudan açılır; bozuksa null.
    private func base64() throws -> [UInt8]? {
      let begin = position + 1
      var end = begin
      while end < data.count && data[end] != 0x22 && data[end] != 0x5C { end += 1 }
      if end < data.count && data[end] == 0x22 {
        position = end + 1
        return Base64.decode(UnsafeBufferPointer(rebasing: data[begin..<end]))
      }
      let text = try string()
      // String sürümü ISO-8859-1 baytlarıyla çözülür; 255'ten büyük karakter '?' olur (geçersiz base64 karakteri).
      let latin1 = text.utf16.map { $0 <= 0xFF ? UInt8($0) : 0x3F }
      return latin1.withUnsafeBufferPointer { Base64.decode($0) }
    }

    /// `{` okunmuş nesnenin üyeleri: her ad için [value] değeri okumalıdır; `}` ile biter.
    private func members(_ value: (String) throws -> Void) throws {
      skipSpace()
      if peek() == 0x7D {
        position += 1
        return
      }
      while true {
        skipSpace()
        if peek() != QUOTE { throw fail() }
        let name = try string()
        skipSpace()
        try expect(0x3A)
        skipSpace()
        try value(name)
        skipSpace()
        switch try next() {
        case 0x2C: continue
        case 0x7D: return
        default: throw fail()
        }
      }
    }

    private func skipValue() throws {
      skipSpace()
      let c = peek()
      switch c {
      case QUOTE:
        _ = try string()
      case 0x7B:
        position += 1
        try members { _ in try skipValue() }
      case 0x5B:
        position += 1
        skipSpace()
        if peek() == 0x5D {
          position += 1
          return
        }
        while true {
          try skipValue()
          skipSpace()
          switch try next() {
          case 0x2C: continue
          case 0x5D: return
          default: throw fail()
          }
        }
      case 0x74: try literal("true")
      case 0x66: try literal("false")
      case 0x6E: try literal("null")
      default:
        if isNumberStart(c) { _ = try number() } else { throw fail() }
      }
    }

    private func string() throws -> String {
      try expect(0x22)
      // Hızlı yol: kaçışsız dize kaynak baytlardan doğrudan çözülür (sonuç bayt bayt kopyalamayla aynı).
      var scan = position
      while scan < data.count {
        let b = data[scan]
        if b == 0x22 || b == 0x5C || b < 0x20 { break }
        scan += 1
      }
      if scan < data.count && data[scan] == 0x22 {
        let text = String(decoding: UnsafeBufferPointer(rebasing: data[position..<scan]), as: UTF8.self)
        position = scan + 1
        return text
      }
      buffer.removeAll(keepingCapacity: true)
      var pendingHigh = -1
      while true {
        let b = Int(try next())
        if b == 0x22 { break }
        if b == 0x5C {
          let escape = try next()
          let unit: Int
          switch escape {
          case 0x22: unit = 0x22
          case 0x5C: unit = 0x5C
          case 0x2F: unit = 0x2F
          case 0x62: unit = 8
          case 0x66: unit = 12
          case 0x6E: unit = 10
          case 0x72: unit = 13
          case 0x74: unit = 9
          case 0x75:
            guard position + 4 <= data.count else { throw fail() }
            let hex = UnsafeBufferPointer(rebasing: data[position..<(position + 4)])
            position += 4
            unit = try hexValue(hex)
          default:
            throw fail()
          }
          if unit >= 0xD800 && unit <= 0xDBFF {
            pendingHigh = unit
            continue
          }
          let codePoint: Int
          if pendingHigh >= 0 && unit >= 0xDC00 && unit <= 0xDFFF {
            codePoint = 0x10000 + ((pendingHigh - 0xD800) << 10) + (unit - 0xDC00)
          } else {
            codePoint = unit
          }
          pendingHigh = -1
          appendUtf8(codePoint)
          continue
        }
        if b < 0x20 { throw fail() }
        buffer.append(UInt8(b))
        pendingHigh = -1
      }
      return String(decoding: buffer, as: UTF8.self)
    }

    /// `String(Character.toChars(cp)).toByteArray(UTF_8)`: tek başına vekil '?' olur.
    private func appendUtf8(_ cp: Int) {
      if cp >= 0xD800 && cp <= 0xDFFF {
        buffer.append(0x3F)
      } else if cp < 0x80 {
        buffer.append(UInt8(cp))
      } else if cp < 0x800 {
        buffer.append(UInt8(0xC0 | (cp >> 6)))
        buffer.append(UInt8(0x80 | (cp & 0x3F)))
      } else if cp < 0x10000 {
        buffer.append(UInt8(0xE0 | (cp >> 12)))
        buffer.append(UInt8(0x80 | ((cp >> 6) & 0x3F)))
        buffer.append(UInt8(0x80 | (cp & 0x3F)))
      } else {
        buffer.append(UInt8(0xF0 | (cp >> 18)))
        buffer.append(UInt8(0x80 | ((cp >> 12) & 0x3F)))
        buffer.append(UInt8(0x80 | ((cp >> 6) & 0x3F)))
        buffer.append(UInt8(0x80 | (cp & 0x3F)))
      }
    }

    /// Kotlin `String.toIntOrNull(16)`: isteğe bağlı + ya da - işareti, sonra onaltılık rakamlar.
    /// (Eksi değer Kotlin'de Character.toChars'ta IllegalArgumentException olurdu; burada bozuk paket sayılır.)
    private func hexValue(_ hex: UnsafeBufferPointer<UInt8>) throws -> Int {
      var index = 0
      var negative = false
      if hex[0] == 0x2B || hex[0] == 0x2D {
        negative = hex[0] == 0x2D
        index = 1
      }
      var value = 0
      while index < hex.count {
        let c = hex[index]
        let digit: Int
        switch c {
        case 0x30...0x39: digit = Int(c) - 0x30
        case 0x61...0x66: digit = Int(c) - 0x61 + 10
        case 0x41...0x46: digit = Int(c) - 0x41 + 10
        default: throw fail()
        }
        value = value * 16 + digit
        index += 1
      }
      if negative && value != 0 { throw fail() }
      return value
    }

    private func number() throws -> Double {
      let start = position
      while position < data.count {
        let c = data[position]
        let ok = (c >= 0x30 && c <= 0x39) || c == 0x2B || c == 0x2D || c == 0x2E || c == 0x65 || c == 0x45
        if !ok { break }
        position += 1
      }
      let text = String(decoding: UnsafeBufferPointer(rebasing: data[start..<position]), as: UTF8.self)
      guard let value = Double(text) else { throw fail() }
      return value
    }

    private func literal(_ word: String) throws {
      for c in word.utf8 where try next() != c { throw fail() }
    }

    private func isNumberStart(_ c: Int) -> Bool { c == 0x2D || (c >= 0x30 && c <= 0x39) }

    private func skipSpace() {
      while position < data.count {
        let c = data[position]
        if c == 0x20 || c == 0x0A || c == 0x0D || c == 0x09 { position += 1 } else { break }
      }
      // UTF-8 BOM
      if position == 0 && data.count >= 3 && data[0] == 0xEF && data[1] == 0xBB && data[2] == 0xBF {
        position = 3
        skipSpace()
      }
    }

    private func peek() -> Int { position < data.count ? Int(data[position]) : -1 }

    private func next() throws -> UInt8 {
      guard position < data.count else { throw fail() }
      let value = data[position]
      position += 1
      return value
    }

    private func expect(_ c: UInt8) throws {
      if try next() != c { throw fail() }
    }

    private func fail() -> InvalidPackException { InvalidPackException("Paket JSON değil") }
  }
}

/// java.util.Base64.getDecoder() (RFC 4648 temel alfabe): '=' dolgusu isteğe bağlı ama varsa doğru olmalı, alfabe
/// dışı karakter ve dolgudan sonra gelen bayt hatadır (null).
enum Base64 {
  private static let table: [Int8] = {
    var t = [Int8](repeating: -1, count: 256)
    let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".utf8)
    for (i, c) in alphabet.enumerated() { t[Int(c)] = Int8(i) }
    t[Int(UInt8(ascii: "="))] = -2
    return t
  }()

  static func decode(_ src: UnsafeBufferPointer<UInt8>) -> [UInt8]? {
    var out = [UInt8]()
    out.reserveCapacity(src.count / 4 * 3 + 3)
    var bits = 0
    var shiftto = 18
    var sp = 0
    let sl = src.count
    while sp < sl {
      let b = Int(table[Int(src[sp])])
      sp += 1
      if b < 0 {
        if b == -2 {
          if (shiftto == 6 && (sp == sl || src[sp] != 0x3D)) || shiftto == 18 { return nil }
          if shiftto == 6 { sp += 1 }
          break
        }
        return nil
      }
      bits |= b << shiftto
      shiftto -= 6
      if shiftto < 0 {
        out.append(UInt8(truncatingIfNeeded: bits >> 16))
        out.append(UInt8(truncatingIfNeeded: bits >> 8))
        out.append(UInt8(truncatingIfNeeded: bits))
        shiftto = 18
        bits = 0
      }
    }
    if shiftto == 6 {
      out.append(UInt8(truncatingIfNeeded: bits >> 16))
    } else if shiftto == 0 {
      out.append(UInt8(truncatingIfNeeded: bits >> 16))
      out.append(UInt8(truncatingIfNeeded: bits >> 8))
    } else if shiftto == 12 {
      return nil
    }
    if sp < sl { return nil }
    return out
  }
}
