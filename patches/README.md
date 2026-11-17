# 🎮 GameTranslator Topluluk Oyun Yamaları (Community Game Patches)

Bu dizin, **GameTranslator** için topluluk tarafından hazırlanan veya popüler Türkçe yama gruplarının metinlerinden uyarlanan **resmi ve topluluk oyun yamalarını** barındırır.

---

## ⚡ Neden Oyun Yaması Modu?

1. **0 ms Gecikme:** Yapay zeka veya sunucu bekleme süresi olmadan, ekranınızdaki İngilizce replik anında %100 profesyonel Türkçe çevirisiyle televizyonunuza basılır.
2. **%100 İnsan Çevirisi Kalitesi:** Oyunu yerelleştiren profesyonel çevirmenlerin replikleri doğrudan kullanılır.
3. **Sıfır API / Kota Tüketimi:** İnternet bağlantısı veya ücretli API gerektirmez.
4. **Hibrit Tamamlama (Yapay Zeka Yedeği):** Yamada henüz yer almayan yan replikler veya rastgele diyaloglar varsa, GameTranslator bunları otomatik olarak Google Gemini / Apple NPU motoru ile anında tamamlar.

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

> 💡 Yamalar hem bu `patches/` klasöründen hem de ana dizindeki `yamalar/` klasöründen otomatik olarak taranır. Ayrılmış bağımsız repo için: [gitlab.com/sefflex/yamalar](https://gitlab.com/sefflex/yamalar)

---

## 📁 Desteklenen Dosya Formatları

GameTranslator uygulamasında **Çeviri & Modeller** sekmesinden ya da **Özel Altyazı** sekmesinden `.json`, `.txt` veya `.srt` uzantılı yama dosyalarını doğrudan içe aktarabilirsiniz.
