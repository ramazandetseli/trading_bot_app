import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:trading_bot_app/constants/app_constants.dart';
import 'package:trading_bot_app/constants/piyasaSaatler.dart';
import 'package:trading_bot_app/models/hisse_model.dart';
import 'package:trading_bot_app/models/piyasa_varlik_model.dart';
import 'package:trading_bot_app/screens/dashboard/piyasa_saatleri_screen.dart';
import 'package:trading_bot_app/screens/dashboard/widgets/app_drawer.dart';
import 'package:trading_bot_app/screens/dashboard/widgets/canli_fiyat_text.dart';
import 'package:trading_bot_app/screens/dashboard/widgets/market_search_screen.dart';
import 'package:trading_bot_app/screens/dashboard/widgets/varlik_avatar.dart';
import 'package:trading_bot_app/screens/hisse/stock_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool yukleniyor = false;
  bool kategoriYukleniyor = false; // Sadece Günün Enleri sekmesi değişirken lokal loading
  String seciliKategori = 'Hisseler';

  // Backend Veri Havuzu
  List<dynamic> tabelaVerileri = [];
  List<dynamic> altinPiyasasi = [];
  List<dynamic> _rawHisseResults = [];
  List<Hissemodel> _parsedHisseler = [];

  // Günün Enleri Listeleri
  List<PiyasaVarlikModel> kazananlar = [];
  List<PiyasaVarlikModel> kaybedenler = [];

  // Önbellekler
  final Map<String, List<PiyasaVarlikModel>> _kazananCache = {};
  final Map<String, List<PiyasaVarlikModel>> _kaybedenCache = {};

  Timer? _canliPiyasaTimer;
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _tumVerileriCek();
    _canliAkisiBaslat();
  }

  @override
  void dispose() {
    _canliPiyasaTimer?.cancel();
    super.dispose();
  }

  void _canliAkisiBaslat() {
    _canliPiyasaTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || yukleniyor) return;
      _dinamikFiyatGuncelle();
    });
  }

  Future<void> _dinamikFiyatGuncelle() async {
    final bool bistAcik = PiyasaSaatleri.isBistAcik();
    final bool forexAcik = PiyasaSaatleri.isForexAltinAcik();
    final bool abdAcik = PiyasaSaatleri.isAbdBorsaAcik();

    // 1. Sadece açık olan piyasaların API'sini arka planda sessizce tazele
    final List<Future> istekler = [];
    if (bistAcik || forexAcik) istekler.add(_tabelaCek());
    if (forexAcik) istekler.add(_altinCek());
    if (bistAcik && seciliKategori == 'Hisseler') istekler.add(_hisseleriCek());

    if (istekler.isNotEmpty) {
      await Future.wait(istekler);
    }

    if (!mounted) return;

    // 2. SADECE AÇIK OLAN PİYASALARDA fiyat değişimi ve parlama (tick) uygula!
    setState(() {
      // Üst Tabela: BIST endeksleri sadece BIST açıkken, Döviz/Altın ise Forex açıkken oynar
      for (var item in tabelaVerileri) {
        final String tip = item['tip']?.toString() ?? '';
        final bool buKalemAcik = (tip == 'endeks') ? bistAcik : forexAcik;

        if (buKalemAcik && _rnd.nextDouble() < 0.45 && item['raw_price'] != null) {
          final double raw = (item['raw_price'] as num).toDouble();
          final double delta = raw * ((_rnd.nextDouble() - 0.49) * 0.0012);
          final double yeniFiyat = raw + delta;
          item['raw_price'] = yeniFiyat;

          final String prefix = item['price'].toString().startsWith('₺')
              ? '₺'
              : (item['price'].toString().startsWith('\$') ? '\$' : '');
          item['price'] = '$prefix${yeniFiyat.toStringAsFixed(2)}';
        }
      }

      // Altın Piyasası: Sadece hafta içi Forex açıkken çalışır
      if (forexAcik) {
        for (var altin in altinPiyasasi) {
          if (_rnd.nextDouble() < 0.45 && altin['raw_price'] != null) {
            final double raw = (altin['raw_price'] as num).toDouble();
            if (raw <= 0) continue;
            final double delta = raw * ((_rnd.nextDouble() - 0.49) * 0.0010);
            final double yeniFiyat = raw + delta;
            altin['raw_price'] = yeniFiyat;
            altin['price'] = '₺${yeniFiyat.toStringAsFixed(2)}';
          }
        }
      }

      // Günün Enleri (Seçili Kategoriye Göre Akıllı Kontrol!)
      bool aktifSekmeAcikMi = false;
      if (seciliKategori == 'Kripto') {
        aktifSekmeAcikMi = PiyasaSaatleri.isKriptoAcik(); // 7/24 True
      } else if (seciliKategori == 'Hisseler') {
        aktifSekmeAcikMi = bistAcik; // Hafta sonu, akşam ve 29 Ekim'de False!
      } else if (seciliKategori.contains('Yabancı')) {
        aktifSekmeAcikMi = abdAcik; // Sadece 16:30 - 23:59 arası True!
      } else if (seciliKategori == 'Fonlar') {
        aktifSekmeAcikMi = PiyasaSaatleri.isFonCanli(); // Her zaman False (Fonlar anlık değişmez)
      }

      // Eğer o an baktığın sekmenin borsası AÇIKSA fiyatları canlı oynat, KAPALIYSA dokunma!
      if (aktifSekmeAcikMi) {
        kazananlar = kazananlar.map((v) => _tickVarlik(v)).toList();
        kaybedenler = kaybedenler.map((v) => _tickVarlik(v)).toList();
      }
    });
  }

  PiyasaVarlikModel _tickVarlik(PiyasaVarlikModel v) {
    if (_rnd.nextDouble() > 0.45) return v; // Her saniye hepsi birden yanmasın, doğal dursun
    final String sembolHarf = v.fiyat.startsWith('\$') ? '\$' : '₺';
    final String temiz = v.fiyat.replaceAll(RegExp(r'[^0-9.]'), '');
    final double? mevcut = double.tryParse(temiz);
    if (mevcut == null || mevcut <= 0) return v;

    final double delta = mevcut * ((_rnd.nextDouble() - 0.49) * 0.0015);
    final double yeni = mevcut + delta;

    return PiyasaVarlikModel(
      sembol: v.sembol,
      baslik: v.baslik,
      fiyat: '$sembolHarf${yeni.toStringAsFixed(2)}',
      degisim: v.degisim,
      rawDegisim: v.rawDegisim,
      isPositive: v.isPositive,
    );
  }
  /// Tüm ana servisleri PARALEL ve BİRBİRİNDEN BAĞIMSIZ çalıştırır.
  /// Biri hata verse bile diğerleri ekrana sorunsuz çizilir.
  Future<void> _tumVerileriCek() async {
    if (!mounted) return;
    setState(() {
      yukleniyor = true;
      _kazananCache.clear();
      _kaybedenCache.clear();
    });

    await Future.wait([
      _tabelaCek(),
      _altinCek(),
      _hisseleriCek(),
    ]);

    // Eğer kullanıcı yenileme yaptığında 'Hisseler' dışında bir sekmedeyse onu da tazele
    if (seciliKategori != 'Hisseler') {
      await _kategoriDegistir(seciliKategori);
    }

    if (mounted) {
      setState(() => yukleniyor = false);
    }
  }

  // 1A. Sadece Üst Tabela Verisi (Bağımsız)
  Future<void> _tabelaCek() async {
    try {
      final response = await http
          .get(AppConstants.piyasaGet)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            tabelaVerileri = data['veriler'] ?? data['veri'] ?? [];
          });
        }
      }
    } catch (e) {
      debugPrint("Tabela verisi çekilemedi: $e");
    }
  }

  // 1B. Sadece Altın Piyasası Verisi (Bağımsız - Tabela çökse de altın gelir)
  Future<void> _altinCek() async {
    try {
      final altinResponse = await http
          .get(AppConstants.altinGet)
          .timeout(const Duration(seconds: 12));
      if (altinResponse.statusCode == 200) {
        final Map<String, dynamic> altinData = json.decode(altinResponse.body);
        if (mounted) {
          setState(() {
            altinPiyasasi = altinData['veri'] ?? altinData['altin_piyasasi'] ?? [];
          });
        }
      }
    } catch (e) {
      debugPrint("Altın verisi çekilemedi: $e");
    }
  }

  // 2. Kategori Çipleri Değişimi
  Future<void> _kategoriDegistir(String kat) async {
    setState(() => seciliKategori = kat);

    // Önbellekte varsa anında göster
    if (_kazananCache.containsKey(kat) && _kazananCache[kat]!.isNotEmpty) {
      setState(() {
        kazananlar = _kazananCache[kat]!;
        kaybedenler = _kaybedenCache[kat] ?? [];
      });
      return;
    }

    // Hisseler seçildiyse ve cache boşsa tekrar hisse çek
    if (kat == 'Hisseler') {
      await _hisseleriCek();
      return;
    }

    Uri? hedefUri;
    if (kat == 'Kripto') hedefUri = AppConstants.kriptoGet;
    if (kat == 'Fonlar') hedefUri = AppConstants.fonEnleriGet;
    if (kat == 'Yabancı') hedefUri = AppConstants.yabanciPiyasaGet;

    if (hedefUri == null) return;

    setState(() => kategoriYukleniyor = true);

    try {
      final response = await http
          .get(hedefUri)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        final kList = (data['kazananlar'] as List? ?? [])
            .map((e) => PiyasaVarlikModel.fromJson(e))
            .toList();
        final dList = (data['kaybedenler'] as List? ?? [])
            .map((e) => PiyasaVarlikModel.fromJson(e))
            .toList();

        if (mounted) {
          setState(() {
            _kazananCache[kat] = kList;
            _kaybedenCache[kat] = dList;
            if (seciliKategori == kat) {
              kazananlar = kList;
              kaybedenler = dList;
            }
          });
        }
      }
    } catch (e) {
      debugPrint("$kat çekilirken hata oluştu: $e");
    } finally {
      if (mounted) {
        setState(() => kategoriYukleniyor = false);
      }
    }
  }

  // 3. BIST Hisselerini Çekme ve Sıralama
  Future<void> _hisseleriCek() async {
    try {
      final res = await http
          .get(AppConstants.taraUri)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final decoded = json.decode(res.body);
        final List<dynamic> results = decoded['hisseler'] ?? [];
        if (!mounted) return;

        final parseEdilenler = results.map((v) => Hissemodel.fromMap(v)).toList();

        final sirali = List<Hissemodel>.from(parseEdilenler)
          ..sort((a, b) {
            final double degisimA = (a.change as num).toDouble();
            final double degisimB = (b.change as num).toDouble();
            return degisimB.compareTo(degisimA);
          });

        final bKazanan = sirali.take(5).map((h) {
          final chg = (h.change as num).toDouble();
          return PiyasaVarlikModel(
            sembol: h.symbol,
            baslik: h.symbol,
            fiyat: '₺${h.price}',
            degisim: '${chg >= 0 ? '+' : ''}%${chg.toStringAsFixed(2)}',
            rawDegisim: chg,
            isPositive: chg >= 0,
          );
        }).toList();

        final bKaybeden = sirali.reversed.take(5).map((h) {
          final chg = (h.change as num).toDouble();
          return PiyasaVarlikModel(
            sembol: h.symbol,
            baslik: h.symbol,
            fiyat: '₺${h.price}',
            degisim: '%${chg.toStringAsFixed(2)}',
            rawDegisim: chg,
            isPositive: chg >= 0,
          );
        }).toList();

        setState(() {
          _rawHisseResults = results;
          _parsedHisseler = parseEdilenler;
          _kazananCache['Hisseler'] = bKazanan;
          _kaybedenCache['Hisseler'] = bKaybeden;
          if (seciliKategori == 'Hisseler') {
            kazananlar = bKazanan;
            kaybedenler = bKaybeden;
          }
        });
      }
    } catch (e) {
      debugPrint("Hisseler çekilirken hata: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: colorScheme.surface,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu_rounded, color: colorScheme.onSurface),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          'TRADING TERMINAL',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            fontSize: 17,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none_rounded, color: colorScheme.onSurface),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context)=> PiyasaSaatleriScreen()));
            },
          ),
          IconButton(
            icon: Icon(Icons.support_agent_rounded, color: colorScheme.onSurface),
            onPressed: () {},
          ),
        ],
      ),
      body: yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _tumVerileriCek,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAramaButonu(colorScheme),
                    const SizedBox(height: 16),
                    

                    if (tabelaVerileri.isNotEmpty) ...[
                      _buildTabelaSeridi(colorScheme),
                      const SizedBox(height: 24),
                    ],

                    _buildGununEnleriBolumu(colorScheme),
                    const SizedBox(height: 28),

                    if (altinPiyasasi.isNotEmpty) ...[
                      _buildAltinPiyasasiBolumu(colorScheme),
                      const SizedBox(height: 28),
                    ],

                    _buildEkonomikTakvimBolumu(colorScheme),
                    const SizedBox(height: 28),

                    _buildHalkaArzBolumu(colorScheme),
                    const SizedBox(height: 28),

                    _buildTemettuBolumu(colorScheme),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
    );
  }

  // --- WIDGET BÖLÜMLERİ ---

  Widget _buildAramaButonu(ColorScheme colorScheme) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MarketSearchScreen(
              hisseler: _parsedHisseler,
              rawHisseResults: _rawHisseResults,
            ),
          ),
        );
      },
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: colorScheme.onSurfaceVariant, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Hisse, Fon, Altın veya Kripto ara...',
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabelaSeridi(ColorScheme colorScheme) {
    return SizedBox(
      height: 76, // 50px'den 76px'e çıkarıldı (Overflow önlendi)
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabelaVerileri.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = tabelaVerileri[index];
          final bool isPos = item['is_positive'] ?? false;
          return Container(
            width: 118,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item['name']?.toString() ?? '',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                CanliFiyatText(
                  fiyatMetni: item['price']?.toString() ?? '',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['change']?.toString() ?? '',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: isPos ? const Color(0xFF00C853) : const Color(0xFFFF3D00),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGununEnleriBolumu(ColorScheme colorScheme) {
    final kategoriler = ['Hisseler', 'Fonlar', 'Kripto', 'Yabancı'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.bolt_rounded, color: Colors.amber, size: 20),
                const SizedBox(width: 6),
                Text(
                  'Günün Enleri',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                // 1. Parlayan kutunun arka plan rengi (Kategoriye göre dinamik)
                color: seciliKategori == 'Hisseler' 
                    ? Colors.orange.shade800 
                    : Colors.blue.shade900,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    // 2. Parlama (Gölge) Rengi
                    color: seciliKategori == 'Hisseler'
                        ? Colors.orange.withValues(alpha: .6)
                        : Colors.blue.withValues(alpha: .6),
                    blurRadius: 7,       // Parlamanın genişliği (Ne kadar dağılacağı)
                    spreadRadius: 2,      // Parlamanın yoğunluğu
                    offset: const Offset(0, 0), // Parlama merkeze odaklansın
                  ),
                ],
              ),
              child: Text(
                seciliKategori == 'Hisseler' ? '15 Dk Gecikmeli' : 'Canlı veri',
                style: const TextStyle(
                  fontSize: 10.5, 
                  color: Colors.white, // Parlayan arka planda beyaz yazı daha okunaklı olur
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: kategoriler.map((kat) {
              final active = seciliKategori == kat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(kat),
                  selected: active,
                  onSelected: (_) => _kategoriDegistir(kat),
                  selectedColor: colorScheme.primary,
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    color: active ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  showCheckmark: false,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        if (kategoriYukleniyor)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))),
          )
        else if (kazananlar.isEmpty && kaybedenler.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              '$seciliKategori kategorisi için şu an veri bulunamadı.',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📈 Kazananlar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00C853))),
                    const SizedBox(height: 6),
                    ...kazananlar.map((v) => _buildVarlikTile(colorScheme, v)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📉 Kaybedenler', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFF3D00))),
                    const SizedBox(height: 6),
                    ...kaybedenler.map((v) => _buildVarlikTile(colorScheme, v)),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

 Widget _buildVarlikTile(ColorScheme colorScheme, PiyasaVarlikModel varlik) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        // 1. Fonlar için farklı bir detay ekranın varsa oraya yönlendirirsin
        if (seciliKategori == 'Fonlar') return;

        // 2. BIST Hissesi ise ve elinde zaten detaylı raw veri varsa onu gönder
        if (seciliKategori == 'Hisseler') {
          final rawHisse = _rawHisseResults.firstWhere(
            (r) => (r['symbol']?.toString().toUpperCase().trim() ?? '') == varlik.sembol.toUpperCase().trim(),
            orElse: () => null,
          );
          if (rawHisse != null) {
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => HisseDetayScreen(hisse: rawHisse))
            );
            return;
          }
        }

        // 3. KRİPTO, NASDAQ veya raw verisi o an elinde olmayan herhangi bir varlık için:
        // Doğrudan seciliKategori bilgisini de içeriye basıyoruz!
        final cleanSym = varlik.sembol.toString().toUpperCase().trim().replaceAll('/', '');
        final gecisVerisi = {
          'symbol': cleanSym,
          'kod': cleanSym,
          'kategori': seciliKategori, // 👈 İŞTE ÇÖZÜM: 'Kripto' veya 'Yabancı' bilgisini taşıyoruz
          'full_name': varlik.baslik.isNotEmpty ? varlik.baslik : cleanSym,
          'price': varlik.fiyat,
          'change': varlik.degisim,
        };

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HisseDetayScreen(hisse: gecisVerisi)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            VarlikLogoWidget(
              symbol: varlik.sembol,
              kategori: seciliKategori, // 'Hisseler', 'Kripto', 'Yabancı', 'Fonlar'
              size: 28,
            ),
            const SizedBox(width: 8),

            // Sembol ve Şirket/Coin Adı
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    varlik.sembol,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (varlik.baslik.isNotEmpty && varlik.baslik != varlik.sembol)
                    Text(
                      varlik.baslik,
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),

            // Fiyat ve Yüzde Değişim
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                CanliFiyatText(
                  fiyatMetni: varlik.fiyat,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  varlik.degisim,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: varlik.isPositive ? const Color(0xFF00C853) : const Color(0xFFFF3D00),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAltinPiyasasiBolumu(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 20),
            const SizedBox(width: 6),
            Text(
              'Altın & Kıymetli Madenler',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: altinPiyasasi.map((item) {
              final bool isPos = item['is_positive'] ?? true;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['name']?.toString() ?? '',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        CanliFiyatText(
                          fiyatMetni: item['price']?.toString() ?? '',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 54,
                          child: Text(
                            item['change']?.toString() ?? '',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isPos ? const Color(0xFF00C853) : const Color(0xFFFF3D00),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEkonomikTakvimBolumu(ColorScheme colorScheme) {
    final olaylar = [
      {"ulke": "🇹🇷", "saat": "14:00", "olay": "TCMB Politika Faiz Kararı", "beklenti": "%47.50", "onceki": "%50.00"},
      {"ulke": "🇺🇸", "saat": "15:30", "olay": "ABD Çekirdek TÜFE (Yıllık)", "beklenti": "%3.2", "onceki": "%3.3"},
      {"ulke": "🇪🇺", "saat": "16:15", "olay": "ECB Faiz Kararı", "beklenti": "%3.40", "onceki": "%3.65"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_month_rounded, color: Colors.blueAccent, size: 20),
            const SizedBox(width: 6),
            Text('Ekonomik Takvim', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          ],
        ),
        const SizedBox(height: 12),
        ...olaylar.map((o) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Text(o['ulke']!, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o['olay']!, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                        Text('Beklenti: ${o['beklenti']}  |  Önceki: ${o['onceki']}', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Text(o['saat']!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.primary)),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildHalkaArzBolumu(ColorScheme colorScheme) {
    final arzlar = [
      {"sirket": "Borusan Araç İhale", "kod": "BORUS", "tarih": "Talep Toplanıyor", "fiyat": "₺45.50", "durum": "Talep"},
      {"sirket": "Girişim Varlık Yönetim", "kod": "GRSVM", "tarih": "Onay Bekliyor", "fiyat": "₺18.20", "durum": "Bekliyor"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.rocket_launch_rounded, color: Colors.deepPurpleAccent, size: 20),
            const SizedBox(width: 6),
            Text('Halka Arz Takvimi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          ],
        ),
        const SizedBox(height: 12),
        ...arzlar.map((a) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${a['sirket']} (${a['kod']})',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(a['tarih']!, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: a['durum'] == 'Talep' ? Colors.green.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      a['fiyat']!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: a['durum'] == 'Talep' ? const Color(0xFF00C853) : Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildTemettuBolumu(ColorScheme colorScheme) {
    final temettuler = [
      {"kod": "TUPRS", "ad": "Tüpraş", "tarih": "27 Eyl", "hisseBasi": "₺10.74", "verim": "%6.8"},
      {"kod": "FROTO", "ad": "Ford Otosan", "tarih": "18 Eki", "hisseBasi": "₺29.70", "verim": "%2.9"},
      {"kod": "KCHOL", "ad": "Koç Holding", "tarih": "24 Eki", "hisseBasi": "₺8.00", "verim": "%3.5"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.savings_rounded, color: Colors.teal, size: 20),
            const SizedBox(width: 6),
            Text('Temettü Takvimi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          ],
        ),
        const SizedBox(height: 12),
        ...temettuler.map((t) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(t['kod']!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: colorScheme.primary)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t['ad']!,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text('Tarih: ${t['tarih']}', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(t['hisseBasi']!, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                      Text('Verim: ${t['verim']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00C853))),
                    ],
                  ),
                ],
              ),
            )),
      ],
    );
  }
}