// SPDX-License-Identifier: AGPL-3.0-only
import 'package:material_ui/material_ui.dart';

import 'bridge.dart';
import 'main.dart';
import 'tv_install_page.dart';
import 'ui.dart';

/// Ayrıntılı kullanım rehberi: PS5 hazırlığından sorun gidermeye kadar her adım. iOS ayarlarındaki gibi bölüm
/// listesi ve her bölümün kendi sayfası. TV kurulum adımları docs/tv-kurulum.md ile aynıdır.
class GuideChapter {
  const GuideChapter({required this.icon, required this.color, required this.title, required this.subtitle, required this.children});

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final List<Widget> children;
}

/// Rehber sekmesi: bölüm listesi.
class GuideTab extends StatelessWidget {
  const GuideTab({super.key});

  @override
  Widget build(BuildContext context) {
    return LargeTitleList(
      title: 'Rehber',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
          child: Text('Kurulumdan sorun gidermeye kadar her şey, adım adım.', style: Txt.body.copyWith(color: Tokens.textSecondary)),
        ),
        const GuideList(),
      ],
    );
  }
}

/// Bölümlerin gruplu listesi; satıra dokununca bölüm sayfası açılır.
class GuideList extends StatelessWidget {
  const GuideList({super.key});

  @override
  Widget build(BuildContext context) {
    final chapters = guideChapters(null);
    Widget cell(int index) => Cell(
          icon: chapters[index].icon,
          iconColor: chapters[index].color,
          title: chapters[index].title,
          subtitle: chapters[index].subtitle,
          chevron: true,
          onTap: () => Navigator.of(context).push(appleRoute<void>((_) => GuideChapterPage(index: index))),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GroupHeader('BAŞLANGIÇ'),
        Group(inset: 60, children: [for (var i = 0; i < 5; i++) cell(i)]),
        const GroupHeader('KULLANIM'),
        Group(inset: 60, children: [for (var i = 5; i < 8; i++) cell(i)]),
        const GroupHeader('YARDIM'),
        Group(inset: 60, children: [cell(8)]),
      ],
    );
  }
}

/// Tek bir bölümün sayfası. Kurulumdaki yardım düğmesi doğrudan ilgili bölümü açar.
class GuideChapterPage extends StatefulWidget {
  const GuideChapterPage({super.key, required this.index});

  final int index;

  @override
  State<GuideChapterPage> createState() => _GuideChapterPageState();
}

class _GuideChapterPageState extends State<GuideChapterPage> {
  String? address;

  @override
  void initState() {
    super.initState();
    Bridge.state().then((state) {
      if (mounted) setState(() => address = state.localAddress);
    });
  }

  @override
  Widget build(BuildContext context) {
    final chapters = guideChapters(address);
    final chapter = chapters[widget.index];
    final next = widget.index + 1 < chapters.length ? widget.index + 1 : null;
    return GlassScaffold(
      title: 'Rehber',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
            child: Row(
              children: [
                IconTile(chapter.icon, chapter.color, size: 44),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(chapter.title, style: Txt.title2),
                      Text(chapter.subtitle, style: Txt.subhead.copyWith(color: Tokens.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Glass(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: chapter.children),
          ),
          if (next != null) ...[
            const GroupHeader('SONRAKİ BÖLÜM'),
            Group(
              inset: 60,
              children: [
                Cell(
                  icon: chapters[next].icon,
                  iconColor: chapters[next].color,
                  title: chapters[next].title,
                  subtitle: chapters[next].subtitle,
                  chevron: true,
                  onTap: () => Navigator.of(context).pushReplacement(appleRoute<void>((_) => GuideChapterPage(index: next))),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Bölümlerin içeriği. [address]: telefonun ağ adresi (OBS adresini tam yazmak için); bilinmiyorsa genel yazılır.
List<GuideChapter> guideChapters(String? address) {
  final phone = address ?? 'telefonun adresi';
  return [
    const GuideChapter(
      icon: CupertinoIcons.arrow_right_arrow_left,
      color: Tokens.accent,
      title: 'Nasıl çalışır?',
      subtitle: 'Bir bakışta bütün düzen',
      children: [
        _P('GameTranslator üç cihazı birbirine bağlar. Oyun PS5\'te çalışır, sen TV\'de oynarsın; telefon arada çevirmenlik yapar:'),
        _Steps([
          'Telefon, oyun görüntüsünü PS5\'ten Remote Play (Uzaktan Oynatma) ile alır. Kamera kullanılmaz.',
          'Görüntüde altyazının çıktığı bölgeyi okur ve yazıyı çevirir.',
          'Çeviriyi aynı Wi-Fi\'deki TV\'ye gönderir. TV\'deki GameTranslator uygulaması onu oyunun üstünde gösterir.',
        ]),
        _Sub('Neler gerekli?'),
        _Bullets([
          'PS5 ve üzerinde ikinci bir kullanıcı (aşağıda anlatılıyor).',
          'GameTranslator TV uygulamasının kurulu olduğu bir TV: LG, Samsung ya da Android TV / Google TV.',
          'Telefon, PS5 ve TV\'nin bağlı olduğu tek bir ev ağı (Wi-Fi).',
          'Çevrimiçi çeviri için internet. İnternetsiz çalışan bir çeviri seçeneği de var.',
        ]),
        _Tip('Kurulum bir kez yapılır. Sonrasında tek yapacağın: çeviriyi başlatmak ve TV\'de uygulamayı açmak.'),
      ],
    ),
    const GuideChapter(
      icon: CupertinoIcons.gamecontroller_fill,
      color: Tokens.indigo,
      title: 'PS5\'i hazırla',
      subtitle: 'İkinci kullanıcı ve Uzaktan Oynatma',
      children: [
        _Sub('1. İkinci bir kullanıcı ekle'),
        _P('PS5, Uzaktan Oynatma ile bağlanan cihazı o kullanıcının kumandası sayar. Telefon senin hesabınla bağlanırsa '
            'elindeki kumanda TV\'den kopar. Bu yüzden telefon ayrı bir kullanıcıyla bağlanır; sen kendi hesabınla oynamaya devam edersin.'),
        _Steps([
          'PS5\'te yeni bir kullanıcı ekle (ana ekrandaki profil resminden Kullanıcı Değiştir › Kullanıcı Ekle).',
          'Bu kullanıcıya bir PSN hesabıyla giriş yap. Hesabın yoksa ücretsiz açabilirsin; PS Plus gerekmez.',
          'Telefonda PSN girişini de bu ikinci hesapla yapacaksın.',
        ]),
        _Sub('2. Uzaktan Oynatmayı aç'),
        _Steps([
          'PS5\'te ikinci kullanıcıya geç.',
          'Ayarlar › Sistem › Uzaktan Oynatma\'ya gir.',
          '"Uzaktan Oynatmayı Etkinleştir"i aç.',
        ]),
        _Sub('3. Dinlenme modundan uyandırma (isteğe bağlı)'),
        _P('PS5 dinlenme modundayken çeviriyi başlattığında telefonun onu uyandırabilmesi için:'),
        _Steps([
          'Ayarlar › Sistem › Güç Tasarrufu › Dinlenme Modunda Kullanılabilen Özellikler\'e gir.',
          '"İnternete Bağlı Kal" ve "PS5\'in Ağdan Açılmasını Etkinleştir" seçeneklerini aç.',
        ]),
        _Tip('Uyandırmayı istemiyorsan telefonda Ayarlar › PS5 › "Dinlenme modundaysa uyandır"ı kapatabilirsin.'),
      ],
    ),
    const GuideChapter(
      icon: CupertinoIcons.link,
      color: Tokens.success,
      title: 'Telefonu PS5 ile eşleştir',
      subtitle: 'PSN girişi ve 8 haneli kod',
      children: [
        _Sub('1. PSN ile giriş yap'),
        _Steps([
          'Kurulum ekranında "PSN ile giriş yap"a dokun. Sony\'nin kendi giriş sayfası açılır.',
          'PS5\'teki ikinci kullanıcının hesabıyla giriş yap.',
          'Giriş bitince uygulama kuruluma kendiliğinden döner ve "PSN hesabı bağlandı" yazar.',
        ]),
        _Tip('Şifren doğrudan Sony\'ye gider; uygulama yalnızca hesabının kimlik numarasını saklar.'),
        _Sub('2. Eşleştirme kodunu gir'),
        _Steps([
          'PS5\'te ikinci kullanıcıdayken Ayarlar › Sistem › Uzaktan Oynatma › "Cihaz Eşleştir"e gir.',
          'Ekranda 8 haneli bir kod ve geri sayım görünür. Kod yaklaşık 5 dakika geçerlidir.',
          'Telefonda "Bulunan konsol" listesinden PS5\'ini seç.',
          'Kodu kutulara yaz ve "Eşleştir"e dokun.',
        ]),
        _Sub('PS5 listede yoksa'),
        _Bullets([
          'Telefon ve PS5 aynı Wi-Fi ağında mı kontrol et; misafir ağı ya da mobil veri olmamalı.',
          '"Yenile"ye dokun.',
          'Yine çıkmazsa "IP adresini elle yaz"a dokun. Adres PS5\'te Ayarlar › Ağ › Bağlantı Durumu › Bağlantı Durumunu Görüntüle\'de yazar.',
        ]),
        _Tip('Eşleştirme bir kez yapılır. PS5\'in adresi değişirse uygulama onu ağda yeniden bulur.'),
      ],
    ),
    GuideChapter(
      icon: CupertinoIcons.tv_fill,
      color: Tokens.purple,
      title: 'TV\'yi hazırla',
      subtitle: 'Desteklenen TV\'ler ve TV uygulaması',
      children: [
        const _P('Altyazıyı TV\'de gösteren ayrı bir GameTranslator TV uygulaması vardır. Henüz mağazalarda olmadığı için TV\'ye '
            'bir kez kurulur. LG ve Android TV\'ye bu telefondan kurabilirsin; Samsung\'a kurulum şimdilik bilgisayardan yapılır.'),
        const InstallTvButton(),
        const _Sub('Hangi TV\'ler destekleniyor?'),
        const _Table([
          ('LG', 'webOS 4 ve üstü', true),
          ('Samsung', 'Tizen, 2019 ve sonrası', true),
          ('Android TV / Google TV', 'Vestel, Arçelik, Beko, Grundig, Philips, Sony, TCL ve diğerleri', true),
          ('Diğerleri', 'Vestel/Arçelik/Beko/Grundig\'in Linux modelleri, Philips Saphi, Titan OS', false),
        ]),
        const _Tip('TV\'n Android mi? Ana ekranında Google Play Store ya da "Google TV" yazıyorsa Android\'dir.'),
        const _Sub('LG'),
        const _Steps([
          'Bilgisayardan webostv.developer.lge.com adresinde ücretsiz bir LG geliştirici hesabı aç.',
          'TV\'de LG Content Store\'dan "Developer Mode" uygulamasını kur, hesabınla giriş yap ve "Dev Mode Status"u aç. TV yeniden başlar.',
          'TV\'de Developer Mode uygulamasında "Key Server"ı aç.',
          'Telefonda "TV uygulamasını kur" sihirbazında LG\'yi seç, TV\'ni bul ve ekrandaki 6 karakterli parolayı yaz '
              '(bilgisayardaki GameTranslator\'ın TV adımı da aynısını yapar).',
        ]),
        const _P('LG\'de geliştirici modu en çok 1000 saat açık kalır. Uzun süre kullanmayacaksan süre dolmadan Developer Mode '
            'uygulamasında "EXTEND"e bas; süre dolarsa TV uygulaması silinir ve baştan kurman gerekir.'),
        const _Sub('Samsung'),
        const _Steps([
          'TV\'de Uygulamalar ekranını aç ve kumandayla 1 2 3 4 5 tuşlarına bas. Geliştirici modu penceresi açılır.',
          '"Developer mode"u aç, "Host PC IP" alanına bilgisayarının adresini yaz.',
          'TV\'yi güç tuşunu basılı tutarak tam kapatıp aç.',
          'Bilgisayardaki GameTranslator\'ın TV adımında TV\'ni seç. Açılan sayfada ücretsiz bir Samsung hesabıyla giriş yap; uygulama imzalanıp kurulur.',
        ]),
        const _Sub('Android TV / Google TV'),
        const _Steps([
          'TV\'de Ayarlar › Cihaz Tercihleri › Hakkında\'ya gir (Google TV\'de Ayarlar › Sistem › Hakkında).',
          '"Yapı numarası"nın üstünde Tamam tuşuna 7 kez bas.',
          'Geliştirici seçenekleri\'nden "USB hata ayıklama"yı (varsa "Ağ hata ayıklama"yı da) aç.',
          'Telefonda "TV uygulamasını kur" sihirbazında "Android TV / Google TV"yi seç ve TV\'deki izin sorusunu onayla.',
        ]),
        const _P('TV ağdan hata ayıklamaya izin vermiyorsa USB bellekle de kurabilirsin: GameTranslator\'ın sürümler sayfasından '
            'TV uygulamasının APK dosyasını indir, belleğe kopyala ve TV\'de bir dosya yöneticisiyle açıp kur.'),
        const _Sub('Kurulduktan sonra'),
        const _P('TV uygulaması telefonu ağda kendisi bulur; telefona TV\'nin adresini yazman gerekmez. Samsung\'da bilgisayara '
            'yalnızca kurulum için ihtiyaç var; sonrasında kapalı kalabilir.'),
        const _Sub('Yayın yapanlar için: OBS'),
        _P('Çeviri açıkken altyazılar bir web sayfası olarak da sunulur. OBS\'te "Tarayıcı Kaynağı" ekleyip adres olarak '
            'http://$phone:8787/obs yaz (1920×1080). Sayfanın zemini saydamdır; TV\'nin tarayıcısında oyunun üstünde göstermez, '
            'yalnızca yayın ve kayıt düzenleri içindir.'),
      ],
    ),
    const GuideChapter(
      icon: CupertinoIcons.play_fill,
      color: Tokens.accent,
      title: 'İlk kullanım',
      subtitle: 'Çeviriyi başlat ve TV\'de gör',
      children: [
        _Steps([
          'PS5\'te oyunu kendi hesabınla aç ve oyunun ayarlarından altyazıları aç.',
          'Telefonda ana ekrandaki büyük düğmeye dokun. İlk seferde bildirim izni sorulur; izin ver ki çeviri arka planda sürsün.',
          'Durum "Çeviri açık" olunca PS5 kartı "Bağlı" yazar. İlk bağlantı birkaç saniye sürer.',
          'TV\'de GameTranslator uygulamasını aç. Birkaç saniye içinde telefondaki TV kartı "Bağlı" olur.',
          'TV\'de oyun görüntüsü gelmezse Tamam tuşuyla paneli aç, sol ve sağ tuşlarıyla PS5\'in bağlı olduğu HDMI girişini seç.',
          'TV\'den ses gelmezse PS5 sesi Remote Play\'e yönlendirmiştir: PS tuşuna bas, alttaki menüden Ses › Çıkış Cihazı\'nı aç ve HDMI\'ı seç. Bu bir kez yapılır.',
          'Telefonda "TV\'ye deneme altyazısı gönder"e dokun. TV\'de yazıyı görüyorsan her şey hazır.',
        ]),
        _Tip('Çeviri açıkken telefonun ekranını kapatabilirsin. Durdurmak için uygulamadaki düğmeye ya da bildirimdeki "Durdur"a dokun.'),
        _Sub('Sonraki seferler'),
        _P('Yalnızca iki adım: telefonda çeviriyi başlat, TV\'de GameTranslator\'ı aç.'),
        _Sub('Pil ve ısınma'),
        _P('Telefon sürekli video çözüp yazı okur; uzun oturumlarda şarja takılı kullan.'),
      ],
    ),
    const GuideChapter(
      icon: CupertinoIcons.dot_radiowaves_left_right,
      color: Tokens.gray,
      title: 'TV kumandası',
      subtitle: 'TV uygulamasındaki tuşlar',
      children: [
        _P('TV\'de GameTranslator açıkken kumandanın tuşları şunları yapar:'),
        _Keys([
          ('Tamam', 'Durum panelini açar ve kapatır (HDMI girişi, bağlantı durumu).'),
          ('Sol / Sağ', 'Panel açıkken HDMI girişini değiştirir.'),
          ('1 – 4', 'HDMI girişini doğrudan seçer.'),
          ('Yukarı / Aşağı', 'Altyazıyı ekranda yukarı ya da aşağı kaydırır.'),
          ('Kırmızı', 'TV\'nin kendi deneme yazısını gösterir.'),
          ('Yeşil', 'Durum panelini açar ve kapatır.'),
          ('Mavi', 'Örnek altyazılarla tanıtımı başlatır ya da durdurur.'),
          ('Geri', 'Uygulamadan çıkar.'),
        ]),
        _Tip('Oyunu PS5 kumandasıyla oynarsın; TV kumandası yalnızca bu ayarlar için gerekir.'),
      ],
    ),
    const GuideChapter(
      icon: CupertinoIcons.crop,
      color: Tokens.teal,
      title: 'Altyazı bölgesini ayarla',
      subtitle: 'Telefonun ekranda nereye bakacağı',
      children: [
        _P('Telefon bütün ekranı değil, yalnızca altyazının çıktığı bölgeyi okur. Bölge yanlış yerdeyse çeviri gelmez ya da '
            'ekrandaki başka yazılar çevrilir.'),
        _Steps([
          'Çeviri açıkken oyunda bir altyazı çıkmasını bekle.',
          'Ana ekrandaki önizlemede mavi çerçeveye bak: altyazının tamamı çerçevenin içinde olmalı.',
          'Değilse "Altyazı bölgesini ayarla"ya dokun. Üst, Alt, Sol ya da Sağ kenarı seç ve sürgüyle yerini değiştir.',
          'Ana ekrandaki "Çerçevede okunan" satırı telefonun o anda ne okuduğunu gösterir; altyazının tamamı orada görünmeli.',
        ]),
        _Bullets([
          'Cümlenin başı ya da sonu kesiliyorsa çerçeveyi genişlet.',
          'İki satırlı altyazılarda üst satır kayboluyorsa üst kenarı yukarı al.',
          'Görev yazıları, harita adları gibi başka yazılar çevriliyorsa çerçeveyi daralt.',
        ]),
        _Tip('Her oyun altyazıyı farklı yere koyar; yeni bir oyuna başladığında bölgeye bir kez bakmak yeter.'),
      ],
    ),
    const GuideChapter(
      icon: CupertinoIcons.textformat,
      color: Tokens.warning,
      title: 'Çeviri ve görünüm',
      subtitle: 'Motor, sözlük ve TV\'deki yazı',
      children: [
        _Sub('Çeviri motoru'),
        _Keys([
          ('Google', 'İnternet ister, anahtar gerekmez. Çoğu oyun için en iyi başlangıç.'),
          ('DeepL', 'Daha doğal cümleler kurar. DeepL\'den aldığın kendi API anahtarını yazman gerekir.'),
          ('Cihazda', 'İnternetsiz çalışır; kalitesi diğerlerinden düşüktür. İlk kullanımda dil modeli bir kez iner.'),
        ]),
        _P('İnternet koparsa çeviri kendiliğinden cihazdaki modele geçer ve bağlantı gelince geri döner.'),
        _Sub('Terim sözlüğü'),
        _P('Çevirinin bozduğu karakter adlarını ve oyun terimlerini sabitlemek içindir (yalnız İngilizce → Türkçe). '
            'Ayarlar › Çeviri › Terim sözlüğü\'nden açılır. "terms" içindeki terimler yazdığın Türkçeyle çevrilir, '
            '"keep" içindeki adlar olduğu gibi kalır.'),
        _Sub('TV\'deki görünüm'),
        _Bullets([
          'Yazı boyutu ve rengi: Ayarlar › TV\'de görünüm.',
          'Altyazının yeri: oyunun altyazısını örterek, üstünde, altında ya da ekranın altında sabit.',
          'Zemin koyuluğu: yazının arkasındaki siyah kutunun koyuluğu. Oyunun altyazısını örtüyorsan yüksek tut.',
        ]),
      ],
    ),
    const GuideChapter(
      icon: CupertinoIcons.wrench_fill,
      color: Tokens.danger,
      title: 'Sorun giderme',
      subtitle: 'Sık karşılaşılan durumlar',
      children: [
        _Qa('Çeviri başlamıyor, "PS5\'e bağlanılıyor"da kalıyor', [
          'PS5 açık mı? Dinlenme modundaysa uyandırma ayarlarını "PS5\'i hazırla" bölümündeki gibi aç.',
          'Telefon Wi-Fi\'ye bağlı ve PS5 ile aynı ağda mı?',
          'PS5\'te Uzaktan Oynatma açık mı?',
        ]),
        _Qa('"Uzaktan Oynatma başka bir cihaz tarafından kullanılıyor"', [
          'PS5 aynı anda tek bir Uzaktan Oynatma bağlantısı kabul eder. Bilgisayardaki GameTranslator ya da başka bir Remote Play uygulaması açıksa kapat.',
          'Az önce durdurduysan birkaç saniye bekle; uygulama kendiliğinden yeniden dener.',
        ]),
        _Qa('Kumandam TV\'den koptu', [
          'Telefon senin oynadığın hesapla bağlanmış. Ayarlar › PS5 › "PSN hesabını değiştir" ile ikinci kullanıcının hesabına geç.',
        ]),
        _Qa('TV kartı "Bekleniyor"da kalıyor', [
        'TV\'de GameTranslator uygulaması açık mı?',
        'TV, telefonla aynı ağda mı? Misafir ağı ya da farklı bir modem olmamalı.',
        'Bilgisayardaki GameTranslator açıksa kapat; TV ağda ilk bulduğuna bağlanır.',
        'TV uygulaması daha önce bilgisayara bağlandıysa o adreste takılı kalmış olabilir. Aşağıdaki "TV telefonu bulamıyorsa" adımlarını uygula.',
      ]),
      _Sub('TV telefonu bulamıyorsa'),
      ...tvRecoverySteps,
      _Qa('TV\'de oyun görüntüsü yok, ekran siyah', [
          'Tamam ile paneli aç ve sol/sağ ile PS5\'in bağlı olduğu HDMI girişini seç.',
          'Bazı Android TV\'ler HDMI görüntüsünü başka uygulamaya vermez; o TV\'lerde altyazı görünür ama arkası siyah kalır.',
        ]),
        _Qa('Altyazı hiç gelmiyor', [
          'Oyunun kendi altyazıları açık mı?',
          'Ana ekrandaki "Çerçevede okunan" boşsa bölge yanlış yerdedir; "Altyazı bölgesini ayarla" bölümüne bak.',
          'Oyunun dili ile Ayarlar › Çeviri\'deki kaynak dil aynı mı?',
          '"TV\'ye deneme altyazısı gönder" çalışıyorsa TV bağlantısı sağlamdır; sorun okumadadır.',
        ]),
        _Qa('Çeviri yarım ya da anlamsız', [
          'Cümlenin başı ya da sonu eksikse bölgeyi genişlet.',
          'Motor "Cihazda" ise Google ya da DeepL\'e geç.',
          'Çok süslü ya da çok küçük yazı tiplerinde okuma zorlaşır; oyunda altyazı boyutunu büyütmek ve arka plan eklemek yardımcı olur.',
        ]),
        _Qa('Çeviri geç geliyor', [
          'Telefon ve PS5 mümkünse modeme yakın olsun; zayıf Wi-Fi görüntüyü geciktirir.',
          'Çevrimiçi motorlarda internet hızı da etkiler.',
        ]),
        _Qa('Ekranı kapatınca çeviri duruyor', [
          'Telefonun pil tasarrufu uygulamayı durduruyor olabilir. Telefonun Ayarlar › Uygulamalar › GameTranslator › Pil bölümünden "Kısıtlanmamış"ı seç.',
          'Bildirim iznini kapattıysan aç; arka plan servisi bildirimle çalışır.',
        ]),
        _Tip('Çözemediğin bir sorun olursa Ayarlar › Hakkında › Günlük\'teki kayıtları kopyalayıp paylaşabilirsin.'),
      ],
    ),
  ];
}

/// Paragraf.
class _P extends StatelessWidget {
  const _P(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(text, style: const TextStyle(color: Tokens.textSecondary, fontSize: 15.5, height: 1.45, letterSpacing: -0.2)),
      );
}

/// Bölüm içi ara başlık.
class _Sub extends StatelessWidget {
  const _Sub(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 18),
        child: Text(text, style: Txt.headline),
      );
}

/// Numaralı adımlar.
class _Steps extends StatelessWidget {
  const _Steps(this.items);

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Tokens.accentSoft, shape: BoxShape.circle),
                    child: Text('${i + 1}', style: const TextStyle(color: Tokens.accentText, fontSize: 12.5, fontWeight: FontWeight.w800, height: 1.1)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(items[i], style: const TextStyle(fontSize: 15.5, height: 1.42, letterSpacing: -0.2)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Sırasız liste.
class _Bullets extends StatelessWidget {
  const _Bullets(this.items);

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 9, right: 12),
                    child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Tokens.accentText, shape: BoxShape.circle)),
                  ),
                  Expanded(child: Text(item, style: const TextStyle(color: Tokens.textSecondary, fontSize: 15.5, height: 1.42, letterSpacing: -0.2))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// İpucu kutusu.
class _Tip extends StatelessWidget {
  const _Tip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Notice(icon: CupertinoIcons.lightbulb_fill, text: text),
      );
}

/// Ad ve açıklama çiftleri: kumanda tuşları, çeviri motorları.
class _Keys extends StatelessWidget {
  const _Keys(this.items);

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          for (final (name, text) in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 104,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Tokens.inset,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Tokens.border),
                    ),
                    child: Text(name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(text, style: const TextStyle(color: Tokens.textSecondary, fontSize: 14, height: 1.4)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Desteklenen TV'ler: marka, ayrıntı ve destek durumu.
class _Table extends StatelessWidget {
  const _Table(this.rows);

  final List<(String, String, bool)> rows;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        decoration: BoxDecoration(color: Tokens.inset, borderRadius: BorderRadius.circular(16), border: Border.all(color: Tokens.border, width: 0.8)),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      rows[i].$3 ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.xmark_circle_fill,
                      size: 20,
                      color: rows[i].$3 ? Tokens.success : Tokens.danger,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rows[i].$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(rows[i].$2, style: const TextStyle(color: Tokens.textSecondary, fontSize: 13.5, height: 1.35)),
                          if (!rows[i].$3)
                            const Text('Desteklenmiyor: bu TV\'lere uygulama kurulamıyor.', style: TextStyle(color: Tokens.danger, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Sorun ve denenecekler.
class _Qa extends StatelessWidget {
  const _Qa(this.question, this.answers);

  final String question;
  final List<String> answers;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2, right: 10),
                child: Icon(CupertinoIcons.question_circle_fill, size: 18, color: Tokens.warning),
              ),
              Expanded(child: Text(question, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.35))),
            ],
          ),
          _Bullets(answers),
        ],
      ),
    );
  }
}

/// TV uygulaması eski bir adrese (ör. kapalı bilgisayara) takılı kaldığında yapılacaklar. Sorun gidermede ve
/// ana ekrandaki uyarıdan açılan sayfada aynı metin kullanılır.
const tvRecoverySteps = <Widget>[
  _P('TV uygulaması en son bağlandığı adresi hatırlar. Daha önce bilgisayara bağlandıysa, telefonu aramak yerine o '
      'adresi denemeye devam edebilir. Kayıtlı adresi silince uygulama ağı baştan tarar ve telefonu bulur.'),
  _Sub('Android TV / Google TV (TCL, Sony, Philips, Vestel…)'),
  _Steps([
    'TV\'de Ayarlar › Uygulamalar\'a gir ve listeden GameTranslator\'ı seç ("Tüm uygulamaları göster" gerekebilir).',
    '"Verileri temizle"yi seç ve onayla. Uygulama silinmez, yalnızca kayıtlı adres ve ayarlar sıfırlanır.',
    'Telefonda çeviri açıkken TV\'de GameTranslator\'ı yeniden aç.',
    'Bir dakikaya kadar bekle; telefondaki TV karosu "Bağlı" olur.',
  ]),
  _Sub('Samsung ve LG'),
  _Steps([
    'Bu TV\'lerde uygulama verisi ayrı silinemez: GameTranslator\'ı TV\'den kaldır.',
    'Bilgisayardaki GameTranslator ile yeniden kur ("TV\'yi hazırla" bölümündeki adımlar).',
    'Bilgisayardaki GameTranslator\'ı kapat, telefonda çeviriyi başlat ve TV\'de uygulamayı aç.',
  ]),
  _Sub('Yine olmazsa'),
  _Bullets([
    'Bilgisayardaki GameTranslator kapalı mı? Açıksa TV ona bağlanır.',
    'Telefon ve TV aynı Wi-Fi ağında mı? Modemde "istemci yalıtımı" (AP isolation) açıksa cihazlar birbirini göremez.',
    'TV\'de HDMI ayarı da sıfırlandığı için Tamam ile paneli açıp PS5\'in girişini yeniden seç.',
  ]),
];

/// Ana ekrandaki "TV hâlâ bağlanmadı" uyarısından açılan yardım sayfası.
class TvHelpPage extends StatelessWidget {
  const TvHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      title: 'TV Bağlanmıyor',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: const [
          Glass(
            padding: EdgeInsets.fromLTRB(18, 10, 18, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: tvRecoverySteps),
          ),
        ],
      ),
    );
  }
}

/// Rehberdeki "TV uygulamasını kur" düğmesi: telefondan kurulum sihirbazını açar.
class InstallTvButton extends StatelessWidget {
  const InstallTvButton({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: GlowButton(
          icon: CupertinoIcons.tv_fill,
          label: 'TV uygulamasını kur',
          onPressed: () => Navigator.of(context).push(appleRoute<void>((_) => const TvInstallPage())),
        ),
      );
}
