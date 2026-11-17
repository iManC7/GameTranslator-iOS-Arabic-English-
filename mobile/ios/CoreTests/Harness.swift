// SPDX-License-Identifier: AGPL-3.0-only
// Core/*.swift için küçük doğrulama düzeneği (XCTest gerektirmez); run.sh ile derlenip çalıştırılır.
import Foundation

final class TestRun {
  nonisolated(unsafe) static var passed = 0
  nonisolated(unsafe) static var failed: [String] = []
  nonisolated(unsafe) static var current = ""
  nonisolated(unsafe) static var currentFailures = 0

  static func test(_ name: String, _ body: () throws -> Void) {
    current = name
    currentFailures = 0
    do { try body() } catch { fail("beklenmeyen hata: \(error)", #fileID, #line) }
    if currentFailures == 0 {
      passed += 1
      print("PASS \(name)")
    } else {
      failed.append(name)
      print("FAIL \(name)")
    }
  }

  static func fail(_ message: String, _ file: String, _ line: Int) {
    currentFailures += 1
    print("  \(file):\(line): \(message)")
  }

  static func finish() -> Never {
    print("\n\(passed) passed, \(failed.count) failed")
    if !failed.isEmpty { print("failed: " + failed.joined(separator: ", ")) }
    exit(failed.isEmpty ? 0 : 1)
  }
}

/// Kotlin'deki String eşitliği UTF-16 birimleriyle birebirdir; Swift'in kanonik eşdeğerliği değil.
private func same<T: Equatable>(_ a: T, _ b: T) -> Bool {
  if let x = a as? String, let y = b as? String { return Array(x.utf16) == Array(y.utf16) }
  return a == b
}

func assertEquals<T: Equatable>(_ expected: T, _ actual: T, _ message: String = "",
                                file: String = #fileID, line: Int = #line) {
  if !same(expected, actual) {
    TestRun.fail("\(message.isEmpty ? "" : message + ": ")beklenen <\(expected)>, gelen <\(actual)>", file, line)
  }
}

func assertTrue(_ value: Bool, _ message: String = "", file: String = #fileID, line: Int = #line) {
  if !value { TestRun.fail("doğru bekleniyordu \(message)", file, line) }
}

func assertFalse(_ value: Bool, _ message: String = "", file: String = #fileID, line: Int = #line) {
  if value { TestRun.fail("yanlış bekleniyordu \(message)", file, line) }
}

func assertNull<T>(_ value: T?, _ message: String = "", file: String = #fileID, line: Int = #line) {
  if let value = value { TestRun.fail("null bekleniyordu, gelen <\(value)> \(message)", file, line) }
}

func assertNotNull<T>(_ value: T?, _ message: String = "", file: String = #fileID, line: Int = #line) {
  if value == nil { TestRun.fail("null olmamalıydı \(message)", file, line) }
}

func assertNotEquals<T: Equatable>(_ unexpected: T, _ actual: T, _ message: String = "",
                                   file: String = #fileID, line: Int = #line) {
  let equal: Bool
  if let x = unexpected as? String, let y = actual as? String { equal = Array(x.utf16) == Array(y.utf16) } else { equal = unexpected == actual }
  if equal { TestRun.fail("\(message.isEmpty ? "" : message + ": ")farklı olmalıydı <\(actual)>", file, line) }
}

func assertEquals(_ expected: Double, _ actual: Double, accuracy: Double, _ message: String = "",
                  file: String = #fileID, line: Int = #line) {
  if !(abs(expected - actual) <= accuracy) {
    TestRun.fail("\(message.isEmpty ? "" : message + ": ")beklenen <\(expected)>, gelen <\(actual)>", file, line)
  }
}

/// JUnit assertThrows: [body] [E] türünde hata fırlatmalı.
func assertThrows<E: Error, T>(_ type: E.Type, _ message: String = "", file: String = #fileID, line: Int = #line,
                               _ body: () throws -> T) {
  do {
    _ = try body()
    TestRun.fail("\(E.self) bekleniyordu \(message)", file, line)
  } catch is E {
  } catch {
    TestRun.fail("\(E.self) bekleniyordu, gelen \(error) \(message)", file, line)
  }
}
