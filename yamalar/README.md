# 🎮 GameTranslator Hazır Türkçe Oyun Yamaları

Bu klasör, **GameTranslator** uygulamasının **0 ms gecikmeyle (anında)** televizyona veya ekrana yansıtacağı resmi ve topluluk Türkçe oyun yamalarını barındırır.

GameTranslator motoru hem `yamalar/` hem de `patches/` klasörlerini otomatik olarak tarar. Buradaki hazır sözlükler ve GamePack formatlı indeksler sayesinde, yapay zeka veya sunucu bekleme süresi olmadan ekranda İngilizce replik göründüğü anda profesyonel Türkçe çevirisi TV'ye yansıtılır.

---

## 📦 Mevcut Hazır Oyun Yamaları Kataloğu (Toplam 629.000+ Replik)

| Oyun | Dosya Adı | Replik / Cümle Sayısı | Dosya Boyutu | Çeviri Kaynağı / Notlar |
| :--- | :--- | :--- | :--- | :--- |
| **Grand Theft Auto V** | `gta-v.json` | **190.566** satır | ~17.2 MB | GTA TR (TechnoGame) + Claude Haiku 5.5 |
| **Red Dead Redemption 2** | `red-dead-redemption-2.json` | **195.430** satır | ~16.7 MB | Claude Haiku 5.5 (Tüm ana ve yan görevler) |
| **Call of Duty: Modern Warfare (2019)** | `call-of-duty-modern-warfare-2019.json` | **51.147** satır | ~4.8 MB | Claude Haiku 5.5 |
| **Assassin's Creed Shadows** | `assassins-creed-shadows.json` | **39.615** satır | ~6.7 MB | Claude Haiku 5.5 |
| **Elden Ring + Shadow of the Erdtree** | `elden-ring.json` | **37.951** satır | ~4.0 MB | Carian Archive + Claude Haiku 5.5 |
| **Final Fantasy VII Rebirth** | `final-fantasy-vii-rebirth.json` | **33.238** satır | ~3.9 MB | Oyun İçi Metin Dökümü + AI Yerelleştirme |
| **Watch Dogs** | `watch-dogs.json` | **25.768** satır | ~3.1 MB | Topluluk Yaması (Tam Oyun) |
| **Death Stranding 2: On the Beach** | `death-stranding-2.json` | **23.132** satır | ~5.0 MB | Claude Haiku 5.5 |
| **Mafia: The Old Country** | `mafia-the-old-country.json` | **18.064** satır | ~2.5 MB | Claude Fable 5.1 |
| **Final Fantasy VII Remake** | `final-fantasy-vii-remake.json` | **5.758** satır | ~0.8 MB | Topluluk Yaması + Fuzzy Eşleme |
| **Marvel's Spider-Man 2** | `marvels-spider-man-2.json` | **2.349** satır | ~0.4 MB | Spider-Man Wiki + Subtitle Pool |
| **Death Stranding Director's Cut** | `death-stranding-directors-cut.json` | **1.334** satır | ~0.8 MB | Game Scripts Wiki + Claude Haiku 5.5 |

---

## ⚡ 0 ms Eşleme ve Akıllı Sistem Nasıl Çalışır?

1. **0 Gecikme:** OCR ile oyun ekranındaki İngilizce altyazı okunduğu anda, GameTranslator saniyenin binde biri süresinde yerel bellekten Türkçe karşılığı çeker.
2. **OCR Hata Toleransı (Fuzzy Match):** Harf veya karakter hataları olsa dahi (örn. `l` yerine `1`, `O` yerine `0`) dahili benzerlik indeksi sayesinde doğru çeviri bulunur.
3. **Konuşmacı Ayrıştırma:** Karakter isimleri (`Cloud:`, `Dutch:`, `Arthur:`) otomatik filtrelenir ve korunur.
4. **Hibrit Tamamlama:** Yamada yer almayan anlık NPC fısıltıları veya rastgele arka plan konuşmaları olursa, GameTranslator bunları Google Gemini veya yerel yapay zeka ile otomatik tamamlar.

---

## 🌐 Harici Yama Deposu

Sadece yamaları takip etmek veya projeyi klonlamadan yamaları bağımsız olarak indirmek isterseniz:
👉 **[GitLab Yamalar Deposu](https://gitlab.com/sefflex/yamalar)**
