import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Mac'ten deneme: `xcrun devicectl device process launch ... <paket> --gt-test-subtitle` altyazı sunucusunu açar ve
    // deneme altyazısını gönderir (Android'deki gt_test_subtitle hata ayıklama isteğinin karşılığı; kayıt bilgisi taşımaz).
    // TV telefonu çeviri başlamadan da bulsun diye altyazı sunucusu uygulama açılınca açılır.
    Engine.shared.openServer()
    if ProcessInfo.processInfo.arguments.contains("--gt-test-subtitle") {
      Engine.shared.sendTestSubtitle()
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // GameTranslator'ın kendi kanalları: gt/bridge, gt/events, gt/tv, gt/tv/events (Android'deki MainActivity karşılığı).
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "GameTranslatorBridge") {
      BridgeChannel.attach(registrar.messenger())
    }
  }
}
