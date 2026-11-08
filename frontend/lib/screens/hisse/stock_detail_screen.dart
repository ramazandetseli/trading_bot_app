import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:trading_bot_app/constants/app_constants.dart';
import 'package:trading_bot_app/screens/dashboard/widgets/varlik_avatar.dart';
import 'package:trading_bot_app/screens/hisse/widgets/ai_analiz.dart';
import 'package:trading_bot_app/screens/hisse/widgets/balina_Radar.dart';
import 'package:trading_bot_app/screens/hisse/widgets/graphic_price.dart';
import 'package:trading_bot_app/screens/hisse/widgets/hedef_istatikstik.dart';
import 'package:trading_bot_app/services/api_service.dart';
import 'package:trading_bot_app/services/premium_service.dart';
import 'package:trading_bot_app/screens/alarms/alarm_kur.dart';

class HisseDetayScreen extends StatefulWidget {
  final Map hisse;
  const HisseDetayScreen({super.key, required this.hisse});

  @override
  State<HisseDetayScreen> createState() => _HisseDetayScreenState();
}

class _HisseDetayScreenState extends State<HisseDetayScreen> with SingleTickerProviderStateMixin {
  // --- AI & Analiz State ---
  String aiYorum = '';
  bool analizBitti = false;
  bool analizYukleniyor = false;
  bool _isTyping = false; 
  bool isGelismisMod = false;
  double aiDestek = 0.0, aiDirenc = 0.0, riskSkoru = 0.0;
  String stratejiEtiketi = '', fonAkisi = '', aktifPeriyot = "1mo";

  // --- Dinamik Veri State ---
  double? aktifFiyat, aktifDegisim, _dinamikRsi, _dinamikRelVol, _dinamikEma20, _dinamikBbUp, _dinamikBbLow;
  double _tvRating = 0.0;

  Timer? _typeTimer;
  late final AnimationController _fadeCtrl;
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>(); 

  // --- Güvenli Veri Okuyucular ---
  String get _symbol => (widget.hisse['symbol'] ?? widget.hisse['kod'] ?? '—').toString().toUpperCase().trim();
  String get _fullName => (widget.hisse['full_name'] ?? widget.hisse['name'] ?? widget.hisse['baslik'] ?? _symbol).toString();
  double get _price => aktifFiyat ?? _d(widget.hisse['raw_price'] ?? widget.hisse['price'] ?? widget.hisse['fiyat']) ?? 0.0;
  double get _change => aktifDegisim ?? _d(widget.hisse['raw_change'] ?? widget.hisse['change'] ?? widget.hisse['degisim']) ?? 0.0;
  double get _rsi => _dinamikRsi ?? _d(widget.hisse['rsi']) ?? 50.0;
  double get _relVol => _dinamikRelVol ?? _d(widget.hisse['rel_vol']) ?? 1.0;
  double get _ema20 => _dinamikEma20 ?? _d(widget.hisse['ema20']) ?? (_price * 0.98);
  double get _bbUp => _dinamikBbUp ?? _d(widget.hisse['bb_up']) ?? (_price * 1.06);
  double get _bbLow => _dinamikBbLow ?? _d(widget.hisse['bb_low']) ?? (_price * 0.95);
  String get _signal => widget.hisse['signal']?.toString() ?? '';

  // --- Akıllı Piyasa ve Para Birimi Tespiti ---
  String get _piyasaTuru {
    final kat = (widget.hisse['kategori'] ?? widget.hisse['tip'] ?? widget.hisse['market'] ?? '').toString().toLowerCase();
    if (kat.contains('kripto') || kat.contains('crypto') || kat.contains('coin')) return 'KRİPTO';
    if (kat.contains('yabanci') || kat.contains('yabancı') || kat.contains('nasdaq') || kat.contains('abd')) return 'NASDAQ';
    if (kat.contains('hisse') || kat.contains('bist')) return 'BIST';

    const kriptolar = {'BTC', 'ETH', 'SOL', 'AVAX', 'XRP', 'DOGE', 'BNB', 'ADA', 'DOT', 'LINK', 'TRX', 'PEPE', 'SHIB', 'HOT', 'CHZ', 'NEAR', 'SUI', 'APT', 'ARB', 'RENDER', 'FET', 'TON'};
    const usStocks = {'AAPL', 'NVDA', 'TSLA', 'MSFT', 'AMZN', 'GOOGL', 'GOOG', 'META', 'AMD', 'NFLX', 'PLTR', 'COIN', 'SPY', 'QQQ', 'INTC', 'BABA', 'MU', 'TSM', 'AVGO', 'ORCL', 'CRM'};
    
    if (_symbol.endsWith('USDT') || kriptolar.contains(_symbol)) return 'KRİPTO';
    if (usStocks.contains(_symbol)) return 'NASDAQ';

    final rawPriceStr = (widget.hisse['price'] ?? '').toString();
    if (rawPriceStr.contains('\$')) {
      return _fullName.contains('Inc') || _fullName.contains('Corp') ? 'NASDAQ' : 'KRİPTO';
    }
    return 'BIST';
  }

  String get _paraBirimi => _piyasaTuru == 'BIST' ? '₺' : '\$';
  bool get _isVip => _signal.contains('VIP');
  bool get _isAgresif => _signal.contains('AGRASİF');
  bool get _isBullish => _price > _ema20;

  double get _tahtaciSkoru => ((_relVol * 22) + (_isBullish ? 20 : 0) + (_isVip ? 25 : 0)).clamp(15, 98);
  double get _hedefDirenc => aiDirenc > 0 ? aiDirenc : _bbUp;
  double get _stopDestek => aiDestek > 0 ? aiDestek : _bbLow;
  double get _potansiyel => _price > 0 ? ((_hedefDirenc - _price) / _price * 100) : 0.0;

  static double? _d(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(RegExp(r'[^0-9.,-]'), '').replaceAll(',', '.'));
  }

  // --- Tema ---
  static const _bg = Color(0xFF070B14);
  static const _card = Color(0xFF0F172A);
  static const _gold = Color(0xFFFFB800);
  
  // Not: UserState().isPremium yapınızın projenizde çalıştığını varsayıyorum.
  Color get _border => UserState().isPremium ? _gold.withValues(alpha: 0.28) : const Color(0xFF1E293B);
  Color get _cyan => UserState().isPremium ? _gold : const Color(0xFF00E5FF);

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 180))..forward();
    if (widget.hisse['rsi'] == null) _eksikTeknikVerileriTamamla();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _typeTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshData() async {
    await _eksikTeknikVerileriTamamla();
  }

  Future<void> _eksikTeknikVerileriTamamla() async {
    try {
      final uri = Uri.parse("${AppConstants.baseUrl}/api/hisse/teknik-detay/$_symbol");
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          setState(() {
            if ((_d(data['price']) ?? 0) > 0) aktifFiyat = _d(data['price']);
            if (_d(data['change']) != null) aktifDegisim = _d(data['change']);
            _dinamikRsi = _d(data['rsi']);
            _dinamikEma20 = _d(data['ema20']);
            _dinamikBbUp = _d(data['bb_up']);
            _dinamikBbLow = _d(data['bb_low']);
            _dinamikRelVol = _d(data['rel_vol']);
            _tvRating = _d(data['tv_rating']) ?? 0.0;
          });
        }
      }
    } catch (_) {}
  }

  void _tikitlaAnalizEt(bool gelismisMi) {
    if (UserState().isPremium) {
      _getAiComment(gelismisMi);
    } else if (UserState().dailyAiRights > 0) {
      setState(() => UserState().dailyAiRights--);
      _getAiComment(gelismisMi);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Günlük AI analiz hakkınız kalmadı."), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _getAiComment(bool gelismisMi) async {
    setState(() {
      analizYukleniyor = true;
      isGelismisMod = gelismisMi;
      aiYorum = '';
      _isTyping = false;
    });

    try {
      final aiData = await ApiService().aiAnaliziniCek(_symbol, _rsi, _relVol, _price, _change, gelismisMi, aktifPeriyot);
      if (!mounted) return;

      if (aiData == null || aiData['status'] == 'error') {
        setState(() {
          aiYorum = aiData?['message'] ?? "Analiz verisi alınamadı.";
          analizBitti = true;
          analizYukleniyor = false;
        });
        return;
      }

      String metin = "Analiz verisi alınamadı.";
      if (gelismisMi) {
        final d = aiData['data'] ?? {};
        metin = "${d['ozet'] ?? ''}\n\n📉 Teknik Rapor:\n${d['teknik_durum'] ?? ''}\n\n🕵️ Piyasa Yapıcı Psikolojisi:\n${d['tahtaci_analizi'] ?? ''}";
        aiDestek = _d(d['destek']) ?? 0.0;
        aiDirenc = _d(d['direnc']) ?? 0.0;
        stratejiEtiketi = d['strateji_etiketi']?.toString() ?? 'Dengeli';
        fonAkisi = d['fon_akisi']?.toString() ?? 'Normal Akış';
        riskSkoru = _d(d['risk_skoru']) ?? 50.0;
      } else {
        metin = aiData['yorum'] ?? "Yorum alınamadı.";
        aiDestek = 0.0;
        aiDirenc = 0.0;
      }

      _startTypewriter(metin);
    } catch (e) {
      if (mounted) {
        setState(() {
          aiYorum = "Bağlantı hatası: $e";
          analizBitti = true;
          analizYukleniyor = false;
        });
      }
    }
  }

  void _startTypewriter(String tamMetin) {
    final chars = tamMetin.characters.toList();
    int idx = 0;
    _typeTimer?.cancel();
    
    setState(() {
      aiYorum = '';
      analizBitti = false; 
      analizYukleniyor = false;
      _isTyping = true;
    });

    _typeTimer = Timer.periodic(const Duration(milliseconds: 12), (t) {
      if (idx < chars.length && mounted) {
        setState(() => aiYorum += chars[idx++]);
      } else {
        t.cancel();
        if (mounted) setState(() {
          _isTyping = false;
          analizBitti = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pTuru = _piyasaTuru;
    final badgeColor = pTuru == 'KRİPTO'
        ? const Color(0xFF00E5FF)
        : (pTuru == 'NASDAQ' ? Colors.orangeAccent : Colors.blueAccent);

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(pTuru, badgeColor),
      body: Stack(
        children: [
          RefreshIndicator(
            key: _refreshKey,
            onRefresh: _refreshData,
            color: _cyan,
            child: FadeTransition(
              opacity: _fadeCtrl,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.only(bottom: 90), // Sticky bottom bar için boşluk
                child: Column(
                  children: [
                    HisseHeroVeGrafikWidget(
                      fullName: _fullName,
                      price: _price,
                      change: _change,
                      symbol: _symbol,
                      isPositive: _change >= 0,
                      bg: _bg,
                      onPeriodChanged: (p) => setState(() => aktifPeriyot = p),
                      onDataFetched: (fiyat, degisim) {
                        if (mounted) setState(() { aktifFiyat = fiyat; aktifDegisim = degisim; });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildMetrikSeridi(),
                    const SizedBox(height: 14),
                    
                    // DÜZELTME: isTyping ve onSkipTyping kaldırıldı, kırmızı hata gidecek.
                    AiAnalizKartWidget(
                      cardColor: _card,
                      borderColor: (analizBitti && !_isTyping) ? _cyan.withValues(alpha: 0.4) : _border,
                      cyan: _cyan,
                      gold: _gold,
                      analizBitti: analizBitti && !_isTyping,
                      analizYukleniyor: analizYukleniyor,
                      isGelismisMod: isGelismisMod,
                      aiYorum: aiYorum,
                      onAnalizTetikle: _tikitlaAnalizEt,
                    ),
                    
                    const SizedBox(height: 14),
                    HisseHedefGridWidget(
                      card: _card,
                      border: _border,
                      cyan: _cyan,
                      analizBitti: analizBitti,
                      analizYukleniyor: analizYukleniyor,
                      hedefDirenc: _hedefDirenc,
                      potansiyel: _potansiyel,
                      stopDestek: _stopDestek,
                    ),
                    const SizedBox(height: 14),
                    if (analizBitti && !analizYukleniyor) ...[
                      WhaleLiveMetricsWidget(
                        card: _card,
                        cyan: _cyan,
                        riskSkoru: riskSkoru,
                        stratejiEtiketi: stratejiEtiketi,
                        fonAkisi: fonAkisi,
                      ),
                      const SizedBox(height: 14),
                    ],
                    _buildTeknikRadarPanel(pTuru),
                    if (_isVip || _isAgresif) _buildUyariBanner(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          // YENİ: Sticky (Yapışkan) Alt Aksiyon Barı
          _buildStickyBottomBar(),
        ],
      ),
    );
  }

  // --- BÖLÜM 1: ÜST BAR ---
  PreferredSizeWidget _buildAppBar(String pTuru, Color badgeColor) {
    return AppBar(
      backgroundColor: _bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              VarlikLogoWidget(symbol: _symbol, size: 24),
              const SizedBox(width: 8),
              Text(_symbol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 0.8),
                ),
                child: Text(pTuru, style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          // YENİ: AppBar'da anlık fiyat ve değişim
          if (_price > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Text("$_paraBirimi${_price.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: (_change >= 0 ? const Color(0xFF00E676) : const Color(0xFFFF5252)).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "${_change >= 0 ? '+' : ''}${_change.toStringAsFixed(2)}%",
                      style: TextStyle(color: _change >= 0 ? const Color(0xFF00E676) : const Color(0xFFFF5252), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 22),
          onPressed: () => _refreshKey.currentState?.show(),
        ),
        IconButton(
          icon: Icon(Icons.notifications_active_outlined, color: _cyan, size: 22),
          onPressed: () => AlarmKur.goster(context: context, symbol: _symbol, anlikFiyat: _price),
        ),
      ],
    );
  }

  // --- BÖLÜM 2: HIZLI METRİK ŞERİDİ ---
  Widget _buildMetrikSeridi() {
    final rsiColor = _rsi > 70 ? Colors.redAccent : (_rsi < 30 ? Colors.greenAccent : Colors.amberAccent);
    final rsiDurum = _rsi > 70 ? "Aşırı Alım" : (_rsi < 30 ? "Aşırı Satım" : "Nötr");

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: _card, 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: _border),
        boxShadow: UserState().isPremium ? [BoxShadow(color: _gold.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))] : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _metrikKutu("RSI (14)", _rsi.toStringAsFixed(1), rsiDurum, rsiColor),
          Container(width: 1, height: 32, color: Colors.white10),
          _metrikKutu("Bağıl Hacim", "${_relVol.toStringAsFixed(2)}x", _relVol > 1.5 ? "Yüksek İlgi" : "Normal", _relVol > 1.5 ? Colors.greenAccent : Colors.white70),
          Container(width: 1, height: 32, color: Colors.white10),
          _metrikKutu("EMA 20", "$_paraBirimi${_ema20.toStringAsFixed(2)}", _isBullish ? "Pozitif Trend" : "Baskı Altında", _isBullish ? const Color(0xFF00E676) : Colors.redAccent),
        ],
      ),
    );
  }

  Widget _metrikKutu(String baslik, String deger, String etiket, Color renk) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(baslik, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(deger, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(etiket, style: TextStyle(color: renk, fontSize: 9.5, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // --- BÖLÜM 3: TEKNİK RADAR VE GÜÇ İBRESİ ---
  Widget _buildTeknikRadarPanel(String pTuru) {
    final score = _tahtaciSkoru;
    final meterColor = score >= 70 ? const Color(0xFF00E676) : (score >= 45 ? Colors.amberAccent : Colors.redAccent);
    final aktor = pTuru == 'BIST' ? 'TAHTACI' : 'BALİNA / KURUMSAL';
    final tvMetin = _tvRating >= 0.1 ? "AL" : (_tvRating <= -0.1 ? "SAT" : "NÖTR");
    final tvRenk = _tvRating >= 0.1 ? const Color(0xFF00E676) : (_tvRating <= -0.1 ? Colors.redAccent : Colors.amberAccent);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(22), border: Border.all(color: _border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$aktor ', style: const TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w800)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: tvRenk.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: Text("TV Sinyal: $tvMetin", style: TextStyle(color: tvRenk, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 64, width: 64,
                    child: CircularProgressIndicator(value: score / 100, strokeWidth: 6.5, color: meterColor, backgroundColor: Colors.white10, strokeCap: StrokeCap.round),
                  ),
                  Text('${score.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    _progressSatiri('Hacim Momentum', (_relVol / 3.5).clamp(0.08, 1.0), const Color(0xFF00E676)),
                    const SizedBox(height: 10),
                    _progressSatiri('RSI Dengesi', (_rsi / 100.0).clamp(0.05, 1.0), Colors.orangeAccent),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _progressSatiri(String label, double val, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            Text('%${(val * 100).toInt()}', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: val, color: color, backgroundColor: Colors.white10, minHeight: 6),
        ),
      ],
    );
  }

  // --- BÖLÜM 4: VIP / AGRESİF UYARI BANNER'I ---
  Widget _buildUyariBanner() {
    final color = _isVip ? _gold : Colors.orangeAccent;
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(_isVip ? Icons.workspace_premium_rounded : Icons.local_fire_department_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isVip ? 'VIP SİNYAL: Kurumsal mal toplama ve hacim patlaması tespit edildi.' : 'AGRESİF HAREKET: Kısa vadeli sert volatilite.',
              style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // YENİ: Sticky Bottom Action Bar
  Widget _buildStickyBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), 
        decoration: BoxDecoration(
          color: _card,
          border: Border(top: BorderSide(color: _border)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => AlarmKur.goster(context: context, symbol: _symbol, anlikFiyat: _price),
                  icon: const Icon(Icons.notifications_active_rounded, size: 18),
                  label: const Text("Alarm Kur"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _cyan,
                    side: BorderSide(color: _cyan.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("$_symbol için işlem modülü yakında aktif olacak."), backgroundColor: _card),
                    );
                  },
                  icon: const Icon(Icons.trending_up_rounded, size: 18),
                  label: const Text("İşlem Yap / İncele"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cyan,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}