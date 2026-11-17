// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'guide_page.dart';
import 'main.dart';
import 'tv_install.dart';
import 'ui.dart';

/// TV uygulamasını telefondan kurma sihirbazı: marka → TV'yi bul → geliştirici modu adımları (her ekranda tek iş)
/// → kurulum → TV'de aç. Kurulum Android tarafında yapılır (tvinstall/); bu sayfa yalnız yol gösterir.
class TvInstallPage extends StatefulWidget {
  const TvInstallPage({super.key});

  @override
  State<TvInstallPage> createState() => _TvInstallPageState();
}

enum _Step { brand, samsung, find, guide, install, done }

/// Geliştirici modu adımlarından biri. [check]: adım yapılınca TV'de açılan port (canlı denetim).
class _GuideStep {
  const _GuideStep(this.title, this.body, {this.different, this.check = _Check.none, this.copy});

  final String title;
  final String body;

  /// "Menü farklı görünüyorsa" açıklaması.
  final String? different;
  final _Check check;

  /// Kopyalanabilecek yazı (ör. web adresi).
  final String? copy;
}

enum _Check { none, ready, keyServer }

const _androidSteps = [
  _GuideStep(
    'TV\'de Ayarlar\'ı aç',
    'TV kumandasındaki dişli (Ayarlar) tuşuna bas. Kumandada yoksa ana ekranın sağ üstündeki dişli simgesini seç.',
    different: 'Google TV\'de (yeni Sony, TCL, Philips, Xiaomi modelleri) sağ üstteki profil resmini ya da dişliyi seç, '
        'sonra "Ayarlar"a gir.',
  ),
  _GuideStep(
    '"Hakkında" ekranına gir',
    'Android TV: Ayarlar › Cihaz Tercihleri › Hakkında.\nGoogle TV: Ayarlar › Sistem › Hakkında.',
    different: 'Philips: Ayarlar › Android Ayarları › Cihaz Tercihleri › Hakkında.\n'
        'Sony: Ayarlar › Sistem › Hakkında (eski modellerde Cihaz Tercihleri › Hakkında).\n'
        'TCL ve Xiaomi: Ayarlar › Sistem › Hakkında ya da Cihaz Tercihleri › Hakkında.\n'
        'Bulamazsan ayarlarda arama varsa "Hakkında" yaz.',
  ),
  _GuideStep(
    'Yapı satırına 7 kez bas',
    'Listenin altındaki "Android TV OS yapısı" satırını seç ve kumandanın Tamam tuşuna art arda 7 kez bas. '
        '"Artık bir geliştiricisiniz" yazısı çıkar.',
    different: 'Satırın adı modele göre "Yapı numarası", "Derleme" ya da "Build" olabilir. TV PIN isterse TV\'nin kilit '
        'PIN\'ini gir. "Zaten geliştiricisiniz" yazıyorsa bu adım tamam.',
  ),
  _GuideStep(
    'Geliştirici seçenekleri\'ni aç',
    'Geri tuşuyla bir ekran geri dön. Android TV\'de Cihaz Tercihleri, Google TV\'de Sistem altında yeni bir '
        '"Geliştirici seçenekleri" satırı belirdi; ona gir.',
    different: 'Satırı göremiyorsan Ayarlar\'dan tamamen çıkıp yeniden gir. Hâlâ yoksa önceki adımda 7 kez basmayı yinele.',
  ),
  _GuideStep(
    '"USB hata ayıklama"yı aç',
    'Geliştirici seçenekleri listesinde "USB hata ayıklama"yı bul ve aç; çıkan uyarıda "Tamam"ı seç. Listede '
        '"Ağ üzerinden hata ayıklama" ya da "ADB ağ hata ayıklama" varsa onu da aç.\n\nTV açıldığında burası kendiliğinden yeşile döner.',
    different: 'Seçeneğin adı "Hata ayıklama (ADB)" ya da İngilizce "USB debugging" olabilir. Yalnız "Kablosuz hata ayıklama" '
        'olup eşleştirme kodu isteyen modeller (ör. Google TV Streamer) telefondan henüz kurulamıyor; bunlarda '
        'Rehber\'deki USB bellek yolunu kullan.',
    check: _Check.ready,
  ),
];

const _lgSteps = [
  _GuideStep(
    'Ücretsiz LG geliştirici hesabı aç',
    'Telefonun tarayıcısında aşağıdaki adrese gir, sağ üstten "SIGN IN", sonra "Create Account" ile ücretsiz hesap aç. '
        'E-postanı ve şifreni bir sonraki adımda TV\'de yazacaksın.',
    different: 'LG hesabın zaten varsa (ör. LG ThinQ) aynı e-posta ve şifreyle giriş yapabilirsin; bu adımı geç.',
    copy: 'https://webostv.developer.lge.com',
  ),
  _GuideStep(
    'TV\'ye "Developer Mode" uygulamasını kur',
    'TV\'de LG Content Store\'u (Uygulamalar) aç, arama kutusuna "Developer Mode" yaz ve uygulamayı yükle.',
    different: 'Mağaza açılmıyorsa TV internete bağlı mı kontrol et. Eski modellerde mağazanın adı "LG Store" ya da '
        '"Uygulamalar"dır. Uygulama ekranda İngilizce görünür.',
  ),
  _GuideStep(
    'Giriş yap ve "Dev Mode Status"u aç',
    'Developer Mode uygulamasını aç, LG hesabının e-postası ve şifresiyle giriş yap. "Dev Mode Status" anahtarını aç. '
        'TV kendiliğinden yeniden başlar; açılmasını bekle.\n\nGeliştirici modu açıldığında burası kendiliğinden yeşile döner.',
    different: '"Dev Mode Status" gri ve seçilemiyorsa önce giriş yapılmamıştır. Giriş "Login failed" diyorsa hesabının '
        'e-postasını doğruladığından emin ol.',
    check: _Check.ready,
  ),
  _GuideStep(
    '"Key Server"ı aç',
    'TV açıldıktan sonra Developer Mode uygulamasını yeniden aç ve "Key Server" anahtarını aç. Uygulamayı ekranda bırak; '
        'kapatırsan Key Server da kapanır.\n\nKey Server açıldığında burası kendiliğinden yeşile döner.',
    different: 'Ekranın sol altında 6 karakterlik "Passphrase" görünür; bir sonraki adımda onu yazacaksın.',
    check: _Check.keyServer,
  ),
];

class _TvInstallPageState extends State<TvInstallPage> {
  _Step step = _Step.brand;
  TvKind? kind;
  String? host;
  String tvName = '';
  bool force = false;

  SavedTv? saved;
  Map<TvKind, String> bundled = {};
  String? phone;

  List<FoundTv> found = [];
  bool searching = false;
  bool searched = false;
  final manualController = TextEditingController();
  String? manualError;

  int guideIndex = 0;
  TvCheck? check;
  Timer? poll;
  bool polling = false;

  final passController = TextEditingController();
  bool installing = false;
  String stage = '';
  TvInstallResult? result;
  StreamSubscription<String>? stages;

  @override
  void initState() {
    super.initState();
    stages = TvBridge.stages.listen((value) {
      if (mounted) setState(() => stage = value);
    });
    () async {
      final values = await Future.wait([TvBridge.saved(), TvBridge.bundled(), TvBridge.phoneAddress()]);
      if (!mounted) return;
      setState(() {
        saved = values[0] as SavedTv?;
        bundled = values[1] as Map<TvKind, String>;
        phone = values[2] as String?;
      });
    }();
  }

  @override
  void dispose() {
    poll?.cancel();
    stages?.cancel();
    if (installing || searching) TvBridge.cancel();
    manualController.dispose();
    passController.dispose();
    super.dispose();
  }

  List<_GuideStep> get guideSteps => switch (kind) {
        TvKind.android => _androidSteps,
        // Anahtarı kayıtlı TV'de Key Server adımı gerekmez.
        TvKind.lg => check?.hasKey == true ? _lgSteps.sublist(0, 3) : _lgSteps,
        _ => const [],
      };

  // ------------------------------------------------------------------------------------------- gezinme

  void go(_Step next) {
    poll?.cancel();
    setState(() {
      step = next;
      if (next != _Step.install) result = null;
    });
    if (next == _Step.find) search();
    if (next == _Step.guide) startPolling();
  }

  void chooseBrand(TvKind value) {
    setState(() {
      kind = value;
      host = null;
      found = [];
      searched = false;
      check = null;
      guideIndex = 0;
      force = false;
    });
    go(value == TvKind.samsung ? _Step.samsung : _Step.find);
  }

  /// Kayıtlı TV'ye doğrudan kurulum (güncelleme ya da yeniden kurulum).
  Future<void> reinstallSaved(SavedTv tv) async {
    setState(() {
      kind = tv.kind;
      host = tv.host;
      tvName = tv.name;
      force = true;
      guideIndex = 0;
    });
    final status = await TvBridge.check(tv.kind, tv.host);
    if (!mounted) return;
    setState(() => check = status);
    if (status.ready && (tv.kind != TvKind.lg || status.hasKey)) {
      go(_Step.install);
      install();
    } else {
      go(_Step.guide);
    }
  }

  void back() {
    switch (step) {
      case _Step.brand:
        Navigator.of(context).pop();
      case _Step.samsung || _Step.find:
        go(_Step.brand);
      case _Step.guide:
        if (guideIndex > 0) {
          setState(() => guideIndex--);
          startPolling();
        } else {
          go(_Step.find);
        }
      case _Step.install:
        if (installing) {
          TvBridge.cancel();
          return;
        }
        setState(() => guideIndex = guideSteps.length - 1);
        go(_Step.guide);
      case _Step.done:
        Navigator.of(context).pop();
    }
  }

  // ------------------------------------------------------------------------------------------- arama

  Future<void> search() async {
    final current = kind;
    if (current == null || searching) return;
    setState(() {
      searching = true;
      manualError = null;
    });
    final list = await TvBridge.find(current);
    if (!mounted || kind != current) return;
    setState(() {
      searching = false;
      searched = true;
      found = list;
    });
  }

  Future<void> useManual() async {
    final address = await TvBridge.normalize(manualController.text);
    if (!mounted) return;
    if (address == null) {
      setState(() => manualError = 'Bu bir IP adresine benzemiyor. Örnek: 192.168.1.40');
      return;
    }
    FocusScope.of(context).unfocus();
    selectTv(address, kind?.title ?? 'TV');
  }

  Future<void> selectTv(String address, String name) async {
    setState(() {
      host = address;
      tvName = name;
      guideIndex = 0;
      manualError = null;
    });
    final status = await TvBridge.check(kind!, address);
    if (!mounted) return;
    setState(() => check = status);
    // Geliştirici modu zaten açıksa adımlar atlanır.
    if (status.ready && (kind == TvKind.android || status.hasKey)) {
      go(_Step.install);
    } else {
      if (status.ready && kind == TvKind.lg) guideIndex = 3; // yalnız Key Server kaldı
      go(_Step.guide);
    }
  }

  // ------------------------------------------------------------------------------------------- canlı denetim

  void startPolling() {
    poll?.cancel();
    final current = guideSteps.elementAtOrNull(guideIndex);
    if (current == null || current.check == _Check.none) return;
    poll = Timer.periodic(const Duration(seconds: 3), (_) => probe());
    probe();
  }

  Future<void> probe() async {
    final current = kind;
    if (polling || current == null) return;
    polling = true;
    try {
      var address = host;
      if (address == null && current == TvKind.android) {
        // TV hata ayıklama açılmadan ağda görünmez: açılınca burada bulunur.
        final list = await TvBridge.find(current);
        if (list.isNotEmpty) {
          address = list.first.host;
          if (mounted) setState(() => host = address);
        }
      }
      if (address == null) return;
      final status = await TvBridge.check(current, address);
      if (mounted) setState(() => check = status);
    } finally {
      polling = false;
    }
  }

  bool stepDone(_GuideStep s) => switch (s.check) {
        _Check.none => false,
        _Check.ready => check?.ready == true,
        _Check.keyServer => check?.keyServer == true,
      };

  void nextGuide() {
    if (guideIndex + 1 < guideSteps.length) {
      setState(() => guideIndex++);
      startPolling();
    } else {
      go(_Step.install);
    }
  }

  // ------------------------------------------------------------------------------------------- kurulum

  bool get needsPassphrase => kind == TvKind.lg && check?.hasKey != true;

  Future<void> install() async {
    final current = kind;
    final address = host;
    if (current == null || address == null || installing) return;
    final pass = passController.text.trim();
    if (current == TvKind.lg && needsPassphrase && pass.isEmpty) {
      setState(() => result = const TvInstallResult(ok: false, error: 'WRONG_PASSPHRASE', detail: 'parola boş'));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      installing = true;
      result = null;
      stage = 'connecting';
    });
    final outcome = await TvBridge.install(current, address, name: tvName, passphrase: needsPassphrase ? pass : null, force: force);
    if (!mounted) return;
    setState(() {
      installing = false;
      result = outcome;
      if (outcome.ok) step = _Step.done;
      // Kayıtlı anahtar geçmediyse parola yeniden sorulur.
      if (outcome.error == 'KEY_REFUSED' || outcome.error == 'WRONG_PASSPHRASE') check = TvCheck(check?.ready ?? false, check?.keyServer ?? false, false);
    });
    if (outcome.ok) TvBridge.saved().then((value) => mounted ? setState(() => saved = value) : null);
  }

  // ------------------------------------------------------------------------------------------- görünüm

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: step == _Step.brand || step == _Step.done,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) back();
      },
      child: GlassScaffold(
        title: 'TV Uygulamasını Kur',
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(
            key: ValueKey('$step-$guideIndex'),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: switch (step) {
                _Step.brand => brandView(),
                _Step.samsung => samsungView(),
                _Step.find => findView(),
                _Step.guide => guideView(),
                _Step.install => installView(),
                _Step.done => doneView(),
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget progress(int index, String title) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (var i = 0; i < 4; i++)
                  Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: i <= index ? Tokens.accent : Tokens.surfaceHigh,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text('ADIM ${index + 1} / 4', style: Txt.footnote.copyWith(color: Tokens.textSecondary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(title, style: Txt.title2),
          ],
        ),
      );

  // ----- 1. marka

  List<Widget> brandView() {
    final tv = saved;
    return [
      progress(0, 'TV\'nin markası ne?'),
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
        child: Text('Altyazıyı TV\'de gösteren GameTranslator uygulamasını telefondan TV\'ne kuracağız. Telefon ve TV aynı Wi-Fi '
            'ağında olsun.', style: Txt.subhead.copyWith(color: Tokens.textSecondary)),
      ),
      if (tv != null) ...[
        const GroupHeader('KAYITLI TV'),
        Group(
          inset: 60,
          children: [
            Cell(
              icon: CupertinoIcons.tv_fill,
              iconColor: Tokens.success,
              title: tv.name.isEmpty ? tv.kind.title : tv.name,
              subtitle: '${tv.host} · TV\'de ${tv.version ?? '?'} · telefonda ${bundled[tv.kind] ?? '?'}',
              trailing: tv.version != null && bundled[tv.kind] != null && _newer(bundled[tv.kind]!, tv.version!)
                  ? const Pill(text: 'Güncelleme var', color: Tokens.warning)
                  : null,
            ),
            Cell(
              title: tv.version != null && bundled[tv.kind] != null && _newer(bundled[tv.kind]!, tv.version!) ? 'Güncelle' : 'Yeniden kur',
              titleColor: Tokens.accent,
              onTap: () => reinstallSaved(tv),
            ),
          ],
        ),
      ],
      const GroupHeader('MARKA'),
      Group(
        inset: 60,
        children: [
          Cell(
            icon: CupertinoIcons.tv,
            iconColor: Tokens.success,
            title: 'Android TV / Google TV',
            subtitle: 'TCL, Sony, Philips, Xiaomi, Vestel, Arçelik, Beko, Grundig… Ana ekranda Google Play ya da "Google TV" yazar.',
            chevron: true,
            onTap: () => chooseBrand(TvKind.android),
          ),
          Cell(
            icon: CupertinoIcons.tv,
            iconColor: Tokens.danger,
            title: 'LG',
            subtitle: 'webOS. Ana ekranda "LG Content Store" ve alt şeritte renkli uygulama kartları bulunur.',
            chevron: true,
            onTap: () => chooseBrand(TvKind.lg),
          ),
          Cell(
            icon: CupertinoIcons.tv,
            iconColor: Tokens.accent,
            title: 'Samsung',
            subtitle: 'Tizen, 2019 ve sonrası. Ana ekranda "Samsung TV Plus" ve "Smart Hub" bulunur.',
            chevron: true,
            onTap: () => chooseBrand(TvKind.samsung),
          ),
        ],
      ),
      const GroupFooter('Emin değil misin? TV\'nin Ayarlar › Destek (ya da Hakkında) ekranında model ve işletim sistemi yazar. '
          'Vestel/Arçelik/Beko/Grundig\'in Linux modelleri, Philips Saphi ve Titan OS desteklenmiyor.'),
    ];
  }

  // ----- Samsung: şimdilik bilgisayardan

  List<Widget> samsungView() => [
        progress(0, 'Samsung: bilgisayardan kur'),
        const Notice(
          icon: CupertinoIcons.desktopcomputer,
          color: Tokens.warning,
          title: 'Samsung TV\'ye kurulum şimdilik bilgisayardan',
          text: 'Samsung, uygulamanın her TV için Samsung hesabıyla ayrıca imzalanmasını istiyor. Telefondan kurulum henüz hazır '
              'değil; bilgisayardaki GameTranslator bunu kendisi yapar. Kurulum bir kez yapılır, sonra bilgisayar gerekmez.',
        ),
        const SizedBox(height: 14),
        SectionCard(
          icon: CupertinoIcons.list_number,
          title: 'Kısaca adımlar',
          children: const [
            _Numbered(1, 'TV\'de Uygulamalar ekranını aç, kumandayla 1 2 3 4 5 tuşlarına bas.'),
            _Numbered(2, '"Developer mode"u "On" yap, "Host PC IP" alanına BİLGİSAYARIN adresini yaz, OK\'e bas.'),
            _Numbered(3, 'TV\'yi güç tuşunu basılı tutarak tam kapatıp aç.'),
            _Numbered(4, 'Bilgisayarda GameTranslator\'ın TV adımında Samsung TV\'ni seç ve açılan sayfada Samsung hesabınla giriş yap.'),
          ],
        ),
        const SizedBox(height: 16),
        GlowButton(
          icon: CupertinoIcons.book_fill,
          label: 'Rehberde ayrıntılı göster',
          onPressed: () => Navigator.of(context).push(appleRoute<void>((_) => const GuideChapterPage(index: 3))),
        ),
        const SizedBox(height: 10),
        OutlinedButton(onPressed: () => go(_Step.brand), child: const Text('Başka marka seç')),
      ];

  // ----- 2. TV'yi bul

  List<Widget> findView() {
    final current = kind!;
    final android = current == TvKind.android;
    return [
      progress(1, 'TV\'ni bul'),
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
        child: Text(
          android
              ? 'Ağda hata ayıklaması açık Android TV\'ler aranıyor. Hata ayıklamayı henüz açmadıysan TV burada görünmez; '
                  'sorun değil, "Adımları göster" ile devam et.'
              : 'Telefonla aynı ağdaki LG TV\'ler aranıyor. TV açık olsun.',
          style: Txt.subhead.copyWith(color: Tokens.textSecondary),
        ),
      ),
      GroupHeader(searching ? 'ARANIYOR…' : 'BULUNAN TV\'LER'),
      Group(
        inset: 60,
        children: [
          if (searching)
            const Cell(title: 'Ağ taranıyor, birkaç saniye sürer…', trailing: CupertinoActivityIndicator())
          else if (found.isEmpty)
            Cell(title: searched ? 'TV bulunamadı' : 'Henüz aranmadı', subtitle: searched ? 'Yenile\'ye dokun ya da adresi elle yaz.' : null),
          for (final tv in found)
            Cell(
              icon: CupertinoIcons.tv_fill,
              iconColor: tv.ready ? Tokens.success : Tokens.gray,
              title: tv.name,
              subtitle: tv.host,
              trailing: tv.ready ? const Pill(text: 'Hazır', color: Tokens.success) : null,
              chevron: true,
              onTap: () => selectTv(tv.host, tv.name),
            ),
          Cell(title: 'Yenile', titleColor: Tokens.accent, onTap: searching ? null : search),
        ],
      ),
      const GroupHeader('ADRESİ ELLE YAZ'),
      Glass(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: manualController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: ipAddressFormatters,
              decoration: InputDecoration(hintText: 'ör. 192.168.1.40', errorText: manualError),
              onSubmitted: (_) => useManual(),
            ),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: useManual, child: const Text('Bu adresi kullan')),
          ],
        ),
      ),
      GroupFooter(android
          ? 'TV\'nin adresi: Ayarlar › Ağ ve İnternet › bağlı olduğun Wi-Fi ağının adı (Google TV: Ayarlar › Ağ ve İnternet). '
              '${phone == null ? '' : 'Telefonun adresi $phone; TV\'ninki ilk üç bölümde aynı olmalı.'}'
          : 'TV\'nin adresi: Ayarlar › Genel › Ağ › Wi-Fi Bağlantısı › Gelişmiş Wi-Fi Ayarları (modele göre Ayarlar › Ağ). '
              '${phone == null ? '' : 'Telefonun adresi $phone; TV\'ninki ilk üç bölümde aynı olmalı.'}'),
      if (android) ...[
        const SizedBox(height: 16),
        GlowButton(
          label: 'Adımları göster',
          icon: CupertinoIcons.list_number,
          onPressed: () {
            setState(() => guideIndex = 0);
            go(_Step.guide);
          },
        ),
      ],
    ];
  }

  // ----- 3. geliştirici modu

  List<Widget> guideView() {
    final steps = guideSteps;
    final index = guideIndex.clamp(0, steps.length - 1);
    final s = steps[index];
    final done = stepDone(s);
    final waiting = s.check != _Check.none && !done;
    return [
      progress(2, kind == TvKind.android ? 'Hata ayıklamayı aç' : 'Geliştirici modunu aç'),
      Glass(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: done ? Tokens.success : Tokens.accent, shape: BoxShape.circle),
                  child: done
                      ? const Icon(CupertinoIcons.checkmark_alt, size: 20, color: Colors.white)
                      : Text('${index + 1}', style: Txt.headline.copyWith(color: Colors.white)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(s.title, style: Txt.title3)),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 46),
              child: Text('${index + 1}. adım, toplam ${steps.length}', style: Txt.footnote.copyWith(color: Tokens.textSecondary)),
            ),
            const SizedBox(height: 14),
            Text(s.body, style: Txt.callout),
            if (s.copy != null) ...[
              const SizedBox(height: 12),
              Glass(
                radius: 14,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(child: SelectableText(s.copy!, style: Txt.subhead.copyWith(fontWeight: FontWeight.w600))),
                    IconButton(
                      tooltip: 'Kopyala',
                      icon: const Icon(CupertinoIcons.doc_on_clipboard, color: Tokens.accent),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: s.copy!));
                        toast(context, 'Adres kopyalandı');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      if (s.check != _Check.none) ...[
        const SizedBox(height: 12),
        done
            ? Notice(
                icon: CupertinoIcons.checkmark_circle_fill,
                color: Tokens.success,
                compact: true,
                text: s.check == _Check.keyServer ? 'Key Server açık. Devam edebilirsin.' : 'TV hazır. Devam edebilirsin.',
              )
            : Glass(
                radius: 18,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    const CupertinoActivityIndicator(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        host == null ? 'TV ağda aranıyor…' : 'TV bekleniyor ($host)…',
                        style: Txt.subhead.copyWith(color: Tokens.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
      ],
      if (s.different != null) ...[
        const SizedBox(height: 12),
        _Expandable(title: 'Menü farklı görünüyorsa', text: s.different!),
      ],
      const SizedBox(height: 18),
      GlowButton(
        label: waiting ? 'Bunu yaptım' : (index + 1 < steps.length ? 'Bunu yaptım' : 'Kuruluma geç'),
        icon: CupertinoIcons.checkmark_alt,
        // Canlı denetimde TV henüz görünmüyorsa yine de geçilebilir: bazı ağlar denetimi engeller, kurulum kendisi dener.
        onPressed: (s.check == _Check.ready && host == null && waiting) ? null : nextGuide,
      ),
      if (s.check == _Check.ready && host == null && waiting)
        const GroupFooter('TV ağda görünene kadar bekleniyor. Görünmüyorsa geri dönüp TV\'nin adresini elle yaz.'),
    ];
  }

  // ----- 4. kurulum

  List<Widget> installView() {
    final current = kind!;
    final failure = result != null && !result!.ok ? result : null;
    final text = failure == null ? null : tvErrorText(failure.error, current);
    return [
      progress(3, 'Kur'),
      Group(
        inset: 60,
        children: [
          Cell(icon: CupertinoIcons.tv_fill, iconColor: Tokens.purple, title: tvName.isEmpty ? current.title : tvName, subtitle: host),
          Cell(icon: CupertinoIcons.cube_box_fill, iconColor: Tokens.indigo, title: 'Kurulacak sürüm', value: bundled[current] ?? '?'),
        ],
      ),
      if (current == TvKind.lg && needsPassphrase) ...[
        const GroupHeader('TV EKRANINDAKİ PAROLA'),
        Glass(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: passController,
                enabled: !installing,
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                maxLength: 10,
                style: Txt.title2.copyWith(letterSpacing: 6),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(hintText: 'ör. 2FEEB2', counterText: ''),
                onSubmitted: (_) => install(),
              ),
            ],
          ),
        ),
        const GroupFooter('Developer Mode uygulamasında Key Server açıkken ekranın sol altında "Passphrase" olarak görünen 6 karakter. '
            'Yalnız bu ilk kurulumda sorulur.'),
      ],
      if (current == TvKind.android && !installing && failure == null)
        const Padding(
          padding: EdgeInsets.only(top: 14),
          child: Notice(
            icon: CupertinoIcons.hand_raised_fill,
            title: 'TV\'de bir soru çıkacak',
            text: '"USB hata ayıklamaya izin verilsin mi?" sorusunda "Bu bilgisayardan her zaman izin ver"i işaretle ve "İzin ver"i seç. '
                'Soru yalnız ilk kurulumda çıkar.',
          ),
        ),
      if (installing) ...[
        const SizedBox(height: 14),
        Glass(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const CupertinoActivityIndicator(),
                  const SizedBox(width: 12),
                  Expanded(child: Text(tvStageText(stage), style: Txt.headline)),
                ],
              ),
              if (stage.startsWith('uploading:')) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(value: (int.tryParse(stage.substring(10)) ?? 0) / 100, borderRadius: BorderRadius.circular(4)),
              ],
            ],
          ),
        ),
        if (stage == 'approve') ...[
          const SizedBox(height: 12),
          const Notice(
            icon: CupertinoIcons.tv,
            color: Tokens.warning,
            title: 'Şimdi TV\'ye bak',
            text: 'TV "USB hata ayıklamaya izin verilsin mi?" diye soruyor. "Bu bilgisayardan her zaman izin ver"i işaretle ve '
                '"İzin ver"i seç. Kurulum sonra kendiliğinden sürer.',
          ),
        ],
        const SizedBox(height: 10),
        const GroupFooter('Telefonun ekranını açık tut. Kurulum genellikle bir dakikadan kısa sürer.'),
      ],
      if (failure != null) ...[
        const SizedBox(height: 14),
        Notice(icon: CupertinoIcons.exclamationmark_triangle_fill, color: Tokens.danger, title: text!.title, text: text.fix),
        if ((failure.detail ?? '').isNotEmpty && failure.error != 'CANCELLED') ...[
          const SizedBox(height: 10),
          _Expandable(title: 'TV\'nin söylediği', text: failure.detail!),
        ],
      ],
      const SizedBox(height: 18),
      if (installing)
        OutlinedButton(onPressed: TvBridge.cancel, child: const Text('Durdur'))
      else ...[
        GlowButton(
          icon: failure == null ? CupertinoIcons.arrow_down_circle_fill : CupertinoIcons.arrow_clockwise,
          label: failure == null ? 'TV\'ye kur' : 'Tekrar dene',
          onPressed: install,
        ),
        if (failure != null) ...[
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () {
              setState(() => guideIndex = failure.error == 'KEY_SERVER_OFF' ? guideSteps.length - 1 : 0);
              go(_Step.guide);
            },
            child: const Text('Adımlara dön'),
          ),
        ],
      ],
    ];
  }

  // ----- 5. tamam

  List<Widget> doneView() {
    final r = result!;
    return [
      const SizedBox(height: 24),
      const Center(child: Icon(CupertinoIcons.checkmark_seal_fill, size: 84, color: Tokens.success)),
      const SizedBox(height: 16),
      Center(child: Text(r.installed ? 'TV uygulaması kuruldu' : 'TV uygulaması zaten güncel', style: Txt.title2, textAlign: TextAlign.center)),
      const SizedBox(height: 6),
      Center(child: Text('Sürüm ${r.version ?? '?'}', style: Txt.subhead.copyWith(color: Tokens.textSecondary))),
      const SizedBox(height: 22),
      Notice(
        icon: CupertinoIcons.tv_fill,
        color: r.launched ? Tokens.success : Tokens.accent,
        title: r.launched ? 'TV\'de GameTranslator açıldı' : 'TV\'de GameTranslator\'ı aç',
        text: r.launched
            ? 'Çeviriyi telefonda başlattığında TV uygulaması telefonu ağda kendisi bulur.'
            : 'TV\'nin uygulamalar listesinde GameTranslator\'ı bul ve aç. Çeviriyi başlattığında telefonu kendisi bulur.',
      ),
      if (kind == TvKind.lg) ...[
        const SizedBox(height: 12),
        Notice(
          icon: CupertinoIcons.clock_fill,
          color: Tokens.warning,
          title: 'LG geliştirici modu süresi',
          text: '${r.hoursLeft != null ? 'Kalan süre: ${r.hoursLeft} saat. ' : ''}Süre dolarsa TV uygulaması silinir. Uzun süre '
              'kullanmayacaksan TV\'deki Developer Mode uygulamasında "EXTEND"e bas; bu sayfadan yeniden kurmak da süreyi uzatır.',
        ),
      ],
      if (kind == TvKind.android) ...[
        const SizedBox(height: 12),
        const Notice(
          icon: CupertinoIcons.info_circle_fill,
          text: 'İstersen artık TV\'de USB hata ayıklamayı kapatabilirsin. Yeni bir sürümü kurmak için yeniden açman gerekir.',
        ),
      ],
      const SizedBox(height: 22),
      GlowButton(label: 'Bitti', onPressed: () => Navigator.of(context).pop()),
    ];
  }
}

bool _newer(String a, String b) {
  List<int> parts(String v) => v.split(RegExp(r'[.-]')).map((p) => int.tryParse(p) ?? 0).toList();
  final x = parts(a), y = parts(b);
  for (var i = 0; i < (x.length > y.length ? x.length : y.length); i++) {
    final l = i < x.length ? x[i] : 0, r = i < y.length ? y[i] : 0;
    if (l != r) return l > r;
  }
  return false;
}

class _Numbered extends StatelessWidget {
  const _Numbered(this.number, this.text);

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Tokens.accentSoft, shape: BoxShape.circle),
              child: Text('$number', style: Txt.footnote.copyWith(fontWeight: FontWeight.w700, color: Tokens.accent)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: Txt.subhead)),
          ],
        ),
      );
}

/// Dokununca açılan ek açıklama.
class _Expandable extends StatefulWidget {
  const _Expandable({required this.title, required this.text});

  final String title;
  final String text;

  @override
  State<_Expandable> createState() => _ExpandableState();
}

class _ExpandableState extends State<_Expandable> {
  bool open = false;

  @override
  Widget build(BuildContext context) => Glass(
        radius: 18,
        clip: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Cell(
              icon: CupertinoIcons.question_circle_fill,
              iconColor: Tokens.gray,
              title: widget.title,
              trailing: Icon(open ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down, size: 16, color: Tokens.textSecondary),
              onTap: () => setState(() => open = !open),
            ),
            if (open)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: SelectableText(widget.text, style: Txt.subhead.copyWith(color: const Color(0xD9EBEBF5))),
              ),
          ],
        ),
      );
}
