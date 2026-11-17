// SPDX-License-Identifier: AGPL-3.0-only
import AVFoundation
import UIKit

/// Ekran kilitliyken çeviri sürsün diye uygulamayı arka planda canlı tutar: Info.plist'teki "audio" arka plan kipi ve
/// sessiz bir ses akışı (Android'deki ön plan servisinin karşılığı). Başka uygulamaların sesine karışır, onları
/// durdurmaz. App Store kurallarına uymaz; uygulama App Store dışından (IPA) dağıtılır.
final class BackgroundKeeper {
  static let shared = BackgroundKeeper()

  private let engine = AVAudioEngine()
  private let player = AVAudioPlayerNode()
  private var running = false
  private var observers: [NSObjectProtocol] = []
  var log: ((Int, String) -> Void)?

  private init() {
    let center = NotificationCenter.default
    observers.append(center.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
      self?.log?(2, "uygulama arka planda (ekran kilitli ya da başka uygulama açık)")
    })
    observers.append(center.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
      self?.log?(2, "uygulama yeniden önde")
    })
    // Telefon görüşmesi gibi bir kesinti bitince sessiz akış yeniden başlar.
    observers.append(center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
      guard let self, self.running,
            let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
            AVAudioSession.InterruptionType(rawValue: raw) == .ended else { return }
      self.log?(2, "ses kesintisi bitti; arka plan akışı yeniden başlıyor")
      self.startAudio()
    })
  }

  func start() {
    DispatchQueue.main.async {
      guard !self.running else { return }
      self.running = true
      self.startAudio()
    }
  }

  func stop() {
    DispatchQueue.main.async {
      guard self.running else { return }
      self.running = false
      self.player.stop()
      self.engine.stop()
      try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
  }

  private func startAudio() {
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
      try session.setActive(true)
      if !engine.attachedNodes.contains(player) {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)
      }
      let format = engine.mainMixerNode.outputFormat(forBus: 0)
      // Bir saniyelik sessiz tampon döngüde çalar (sıfırlarla dolu; hoparlörden bir şey duyulmaz).
      guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(format.sampleRate)) else { return }
      buffer.frameLength = buffer.frameCapacity
      if !engine.isRunning { try engine.start() }
      player.stop()
      player.scheduleBuffer(buffer, at: nil, options: .loops)
      player.play()
      log?(2, "arka plan akışı açık")
    } catch {
      log?(1, "arka plan akışı açılamadı: \(error.localizedDescription)")
    }
  }
}
