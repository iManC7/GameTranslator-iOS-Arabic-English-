// SPDX-License-Identifier: AGPL-3.0-only
import Foundation

/// libchiaki + VideoToolbox işlevleri (Native/gt_native.c); Android'deki Native.kt'nin karşılığı.
/// Hepsi bloklayabilir, ana iş parçacığında çağrılmaz.
enum Native {
  static let eventConnected: Int32 = 0
  static let eventQuit: Int32 = 1
  static let eventLoginPin: Int32 = 2

  static let quitStopped: Int32 = 0
  static let quitInUse: Int32 = 1
  static let quitRefused: Int32 = 2
  static let quitNetwork: Int32 = 3
  static let quitOther: Int32 = 4

  /// chiaki_lib_init başarılı mı (bir kez çalışır).
  static let available: Bool = cs_init() == 0

  // MARK: - Arama ve uyandırma

  private final class ConsoleBox {
    let callback: (String, String, Bool) -> Void
    init(_ callback: @escaping (String, String, Bool) -> Void) { self.callback = callback }
  }

  /// Bulunan her PS5 için [callback] (aynı PS5 birden çok kez gelebilir). Bloklar.
  @discardableResult
  static func discover(targets: [String], timeoutMs: Int, callback: @escaping (_ host: String, _ name: String, _ awake: Bool) -> Void) -> Int32 {
    let box = Unmanaged.passRetained(ConsoleBox(callback))
    defer { box.release() }
    let strings = targets.map { strdup($0) }
    defer { strings.forEach { free($0) } }
    var pointers = strings.map { UnsafePointer<CChar>($0) }
    return pointers.withUnsafeMutableBufferPointer { buffer in
      cs_discover(buffer.baseAddress, Int32(buffer.count), Int32(timeoutMs), { host, name, awake, user in
        guard let host, let user else { return }
        let box = Unmanaged<ConsoleBox>.fromOpaque(user).takeUnretainedValue()
        box.callback(String(cString: host), name.map { String(cString: $0) } ?? "PS5", awake != 0)
      }, box.toOpaque())
    }
  }

  @discardableResult
  static func wake(host: String, credential: UInt64) -> Int32 { cs_wake(host, credential) }

  // MARK: - Kayıt

  private final class LogBox {
    let callback: (Int, String) -> Void
    init(_ callback: @escaping (Int, String) -> Void) { self.callback = callback }
  }

  private static let logTrampoline: cs_log_cb = { level, message, user in
    guard let message, let user else { return }
    Unmanaged<LogBox>.fromOpaque(user).takeUnretainedValue().callback(Int(level), String(cString: message))
  }

  struct Registered {
    var name: String
    var registKey: Data
    var morning: Data
  }

  /// Dönüş: 0 başarı, 1 başarısız ([reason] PS5'in nedeni), 2 iptal, <0 başlatılamadı. En çok ~30 sn bloklar.
  static func register(host: String, accountId: Data, pin: UInt32, log: @escaping (Int, String) -> Void)
    -> (result: Int32, registered: Registered?, reason: UInt32) {
    let box = Unmanaged.passRetained(LogBox(log))
    defer { box.release() }
    var out = cs_registered_console()
    var reason: UInt32 = 0
    let account = [UInt8](accountId)
    let result = cs_register(host, account, pin, &out, &reason, logTrampoline, box.toOpaque())
    guard result == 0 else { return (result, nil, reason) }
    let name = withUnsafeBytes(of: out.nickname) { raw -> String in
      let bytes = raw.prefix { $0 != 0 }
      return String(decoding: bytes, as: UTF8.self)
    }
    let key = withUnsafeBytes(of: out.regist_key) { Data($0) }
    let morning = withUnsafeBytes(of: out.morning) { Data($0) }
    return (0, Registered(name: name, registKey: key, morning: morning), 0)
  }

  // MARK: - Oturum

  /// Oturum dinleyicisi; çağrılar libchiaki'nin iş parçacıklarından gelir.
  protocol Listener: AnyObject {
    /// BGRA kare; [base] yalnız çağrı süresince geçerlidir, içinde kopyalanmalıdır.
    func onFrame(base: UnsafePointer<UInt8>, width: Int, height: Int, stride: Int)
    /// event: 0 bağlandı, 1 kapandı ([quitReason]: quit*), 2 PS5 giriş şifresi istiyor.
    func onEvent(_ event: Int32, quitReason: Int32, reasonText: String?)
    /// level: 0 hata, 1 uyarı, 2 bilgi.
    func onLog(_ level: Int, _ message: String)
  }

  final class Session {
    private let handle: OpaquePointer
    private let box: Unmanaged<ListenerBox>

    fileprivate init(handle: OpaquePointer, box: Unmanaged<ListenerBox>) {
      self.handle = handle
      self.box = box
    }

    /// Oturumu durdurur ve iş parçacıklarını bekler; dinleyici geri çağrısının içinden çağrılmamalı. Bir kez çağrılır.
    func stop() {
      cs_session_stop(handle)
      box.release()
    }
  }

  fileprivate final class ListenerBox {
    weak var listener: Listener?
    init(_ listener: Listener) { self.listener = listener }
  }

  /// Ses ve kol girdisi kapalı 1080p/30 H.264 akışı. Kareler en çok [maxFps] kez verilir. Başlamazsa nil.
  static func startSession(host: String, registKey: Data, morning: Data, accountId: Data, maxFps: Int,
                           listener: Listener) -> Session? {
    let box = Unmanaged.passRetained(ListenerBox(listener))
    let key = [UInt8](registKey)
    let morningBytes = [UInt8](morning)
    let account = [UInt8](accountId)
    let handle = cs_session_start(host, key, morningBytes, account, Int32(maxFps), { base, width, height, stride, user in
      guard let base, let user else { return }
      Unmanaged<ListenerBox>.fromOpaque(user).takeUnretainedValue().listener?
        .onFrame(base: base, width: Int(width), height: Int(height), stride: Int(stride))
    }, { event, reason, text, user in
      guard let user else { return }
      Unmanaged<ListenerBox>.fromOpaque(user).takeUnretainedValue().listener?
        .onEvent(event, quitReason: reason, reasonText: text.map { String(cString: $0) })
    }, { level, message, user in
      guard let message, let user else { return }
      Unmanaged<ListenerBox>.fromOpaque(user).takeUnretainedValue().listener?.onLog(Int(level), String(cString: message))
    }, box.toOpaque())
    guard let handle else {
      box.release()
      return nil
    }
    return Session(handle: handle, box: box)
  }
}
