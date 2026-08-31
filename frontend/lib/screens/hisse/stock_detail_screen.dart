import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trading_bot_app/screens/hisse/widgets/ai_analiz.dart';
import 'package:trading_bot_app/screens/hisse/widgets/balina_Radar.dart';
import 'package:trading_bot_app/screens/hisse/widgets/graphic_price.dart';
import 'package:trading_bot_app/screens/hisse/widgets/hedef_istatikstik.dart';
import 'package:trading_bot_app/screens/hisse/widgets/hisse_istatistik.dart';
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
  // --- AI State ---
  String aiYorum = ''; 
  bool analizBitti = false;
  bool analizYukleniyor = false; 
  bool isGelismisMod = false; 


  double? aktifFiyat;
  double? aktifDegisim;

  double aiDestek = 0.0;
  double aiDirenc = 0.0;  
  String stratejiEtiketi = '';
  String fonAkisi = '';
  double riskSkoru = 0.0;
  String aktifPeriyot = "1mo";
  
  Timer? _typeTimer; 
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  // --- Veri Okuyucular ---
  String get _symbol   => widget.hisse['symbol']?.toString()   ?? '—';
  String get _fullName => widget.hisse['full_name']?.toString() ?? _symbol;
  double get _price    => _d(widget.hisse['price'])    ?? 0.0;
  double get _change   => _d(widget.hisse['change'])   ?? 0.0;
  double get _rsi      => _d(widget.hisse['rsi'])      ?? 50.0;
  double get _relVol   => _d(widget.hisse['rel_vol'])  ?? 0.0;
  double get _ema20    => _d(widget.hisse['ema20'])    ?? 0.0;
  double get _bbUp     => _d(widget.hisse['bb_up'])    ?? (_price * 1.05);
  double get _bbLow    => _d(widget.hisse['bb_low'])   ?? (_price * 0.96);
  String get _signal   => widget.hisse['signal']?.toString() ?? '';

  bool get _isVip      => _signal.contains('VIP');
  bool get _isAgresif  => _signal.contains('AGRASİF');
  bool get _isPositive => _change >= 0;
  bool get _isBullish  => _price > _ema20;

  double get _tahtaciSkoru => ((_relVol * 20) + (_isVip ? 30 : 0)).clamp(0, 100);
  double get _hedefDirenc => aiDirenc > 0 ? aiDirenc : _bbUp;
  double get _stopDestek  => aiDestek > 0 ? aiDestek : _bbLow;
  double get _potansiyel  => _price > 0 ? ((_hedefDirenc - _price) / _price * 100) : 0.0;

  static double? _d(dynamic v) => v == null ? null : double.tryParse(v.toString());

  // --- Renkler ---
  Color get _bg      => const Color(0xFF070B14);
  Color get _card    => const Color(0xFF0D1420);
  Color get _border  => UserState().isPremium ? const Color(0xFFFFB800).withValues(alpha: 0.3) : const Color(0xFF1E293B);
  Color get _cyan    => UserState().isPremium ? const Color(0xFFFFB800) : const Color(0xFF00D4FF); 
  static const _gold = Color(0xFFFFB800);

  @override
  void initState() {
    super.initState();
    int fadeSure = UserState().isPremium ? 5 : 200;
    _fadeCtrl = AnimationController(vsync: this, duration: Duration(milliseconds: fadeSure));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _typeTimer?.cancel(); 
    super.dispose();
  }

  // --- AI Fonksiyonları ---
  void _tikitlaAnalizEt(bool gelismisMi) {
    if (UserState().isPremium) {
      _getAiComment(gelismisMi);
    } else {
      if (UserState().dailyAiRights > 0) {
        setState(() => UserState().dailyAiRights--);
        _getAiComment(gelismisMi);
      } else {
        _showPremiumBottomSheet();
      }
    }
  }

  Future<void> _getAiComment(bool gelismisMi) async {
    setState(() {
      analizYukleniyor = true;
      isGelismisMod = gelismisMi; 
      aiYorum = ''; // Önceki yorumu temizle
    });

    try {
      final aiData = await ApiService().aiAnaliziniCek(_symbol, _rsi, _relVol, _price, _change, gelismisMi, aktifPeriyot);
      
      // 🔥 KONSOLA NE GELDİĞİNİ YAZDIRIYORUZ
      debugPrint("🤖 AI'DAN GELEN HAM VERİ: $aiData");
      
      if (!mounted) return;

      if (aiData != null) {
        if (aiData['status'] == 'error') {
          _hataDurumu(aiData['message'] ?? "Bilinmeyen bir API hatası oluştu.");
          return;
        }

        String gonderilecekMetin = "Analiz verisi alınamadı.";

        setState(() {
          if (gelismisMi) {
            // 👑 PREMIUM (DEEP) VERİLERİNİ OKU
            final data = aiData['data'] ?? {};
            
            final ozet = data['ozet'] ?? "Özet bulunamadı.";
            final teknik = data['teknik_durum'] ?? "Teknik veri bulunamadı.";
            final tahtaci = data['tahtaci_analizi'] ?? "Tahtacı verisi bulunamadı.";
            
            gonderilecekMetin = "$ozet\n\n📉 Teknik Rapor:\n$teknik\n\n🕵️ Tahtacı Psikolojisi:\n$tahtaci";
            
            aiDestek = double.tryParse(data['destek']?.toString() ?? '0') ?? 0.0;
            aiDirenc = double.tryParse(data['direnc']?.toString() ?? '0') ?? 0.0;
            stratejiEtiketi = data['strateji_etiketi']?.toString() ?? 'Hesaplanamadı';
            fonAkisi = data['fon_akisi']?.toString() ?? 'Dengeli Akış';
            riskSkoru = double.tryParse(data['risk_skoru']?.toString() ?? '50') ?? 50.0;
          } 
          else {
            // 🟢 BASIC (ÜCRETSİZ) VERİLERİNİ OKU
            gonderilecekMetin = aiData['yorum'] ?? "Groq'tan yorum dönmedi.";
            aiDestek = 0.0;
            aiDirenc = 0.0;
          }
        });
        
        _startTypewriterAnimation(gonderilecekMetin);
      } else {
        _hataDurumu("Bağlantı kurulamadı. Veri boş geldi.");
      }
    } catch (e) {
      if (!mounted) return;
      _hataDurumu("Uygulama içi hata: $e");
    }
  }

  void _hataDurumu(String mesaj) {
    setState(() {
      aiYorum = mesaj;
      analizBitti = true;
      analizYukleniyor = false;
    });
  }

  void _startTypewriterAnimation(String tamMetin) {
    final karakterler = tamMetin.characters.toList();
    int idx = 0;
    _typeTimer?.cancel(); 
    setState(() { aiYorum = ''; analizBitti = true; analizYukleniyor = false; });

    _typeTimer = Timer.periodic(const Duration(milliseconds: 15), (timer) { 
      if (idx < karakterler.length && mounted) {
        setState(() => aiYorum += karakterler[idx]);
        idx++;
      } else {
        timer.cancel(); 
      }
    });
  }

  void _showPremiumBottomSheet() {
    // ... Premium Bottom Sheet kodun (Değiştirilmedi)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(_symbol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 1)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.alarm_add_rounded, color: Colors.white),
            onPressed: () => AlarmKur.goster(context: context, symbol: _symbol, anlikFiyat: _price),
          )
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              HisseHeroVeGrafikWidget(
                fullName: _fullName,
                price: aktifFiyat ?? _price,           // 🔥 Dinamik Fiyat
                change: aktifDegisim ?? _change,       // 🔥 Dinamik Değişim
                symbol: _symbol,
                isPositive: (aktifDegisim ?? _change) >= 0,
                bg: _bg,

                onPeriodChanged: (yeniPeriyot) {
                  setState(() {
                    aktifPeriyot = yeniPeriyot; // 🔥 Kullanıcı tıkladıkça burası güncellenir!
                  });
                },
                onDataFetched: (yeniFiyat, yeniDegisim) {
                  // Grafik veriyi çektiğinde burayı tetikleyip tepeyi günceller!
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if(mounted) {
                      setState(() {
                        aktifFiyat = yeniFiyat;
                        aktifDegisim = yeniDegisim;
                      });
                    }
                  });
                },
              ),

              const SizedBox(height: 14),

              AiAnalizKartWidget(
                cardColor: _card,
                borderColor: analizBitti ? _cyan.withValues(alpha: 0.3) : _border,
                cyan: _cyan,
                gold: _gold,
                analizBitti: analizBitti,
                analizYukleniyor: analizYukleniyor,
                isGelismisMod: isGelismisMod,
                aiYorum: aiYorum,
                onAnalizTetikle: _tikitlaAnalizEt,
              ),
              
              const SizedBox(height: 14),

              // 3. İstatistikler
              HisseStatsRowWidget(card: _card, border: _border, rsi: _rsi, relVol: _relVol, isBullish: _isBullish, isVip: _isVip, isAgresif: _isAgresif, gold: _gold),
              
              const SizedBox(height: 14),

              // 4. Hedefler
              HisseHedefGridWidget(card: _card, border: _border, cyan: _cyan, analizBitti: analizBitti, analizYukleniyor: analizYukleniyor, hedefDirenc: _hedefDirenc, potansiyel: _potansiyel, stopDestek: _stopDestek),

              const SizedBox(height: 14),

              // 5. Balina Radarı (Sadece Analiz bitince görünür)
              if (analizBitti) 
                WhaleLiveMetricsWidget(card: _card, cyan: _cyan, riskSkoru: riskSkoru, stratejiEtiketi: stratejiEtiketi, fonAkisi: fonAkisi),
              if (analizBitti) const SizedBox(height: 14),

              // 6. Tahtacı Gücü ve Teknik Karne
              _PowerMeterWidget(card: _card, border: _border, score: _tahtaciSkoru, gold: _gold),
              const SizedBox(height: 14),
              _TeknikKarneWidget(card: _card, border: _border, relVol: _relVol, rsi: _rsi),
              
              if (_isVip || _isAgresif) ...[
                const SizedBox(height: 14),
                _AlertBannerWidget(isVip: _isVip, gold: _gold),
              ],
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}



// 6. DİĞER KÜÇÜK PARÇALAR
class _PowerMeterWidget extends StatelessWidget {
  final Color card, border, gold;
  final double score;
  const _PowerMeterWidget({required this.card, required this.border, required this.score, required this.gold});
  @override
  Widget build(BuildContext context) {
    final meterColor = score > 70 ? Colors.greenAccent : gold;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(24), border: Border.all(color: border)),
      child: Column(
        children: [
          const Text('TAHTACI GÜVEN ENDEKSİ', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Stack(alignment: Alignment.center, children: [SizedBox(height: 60, width: 60, child: CircularProgressIndicator(value: score / 100, strokeWidth: 6, color: meterColor, backgroundColor: Colors.white10)), Text('${score.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900))]),
              const SizedBox(width: 16),
              Expanded(child: Text(score > 70 ? '🐋 Balina girişi tespit edildi.' : '🤫 Hacim henüz sakin.', style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4))),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeknikKarneWidget extends StatelessWidget {
  final Color card, border;
  final double relVol, rsi;
  const _TeknikKarneWidget({required this.card, required this.border, required this.relVol, required this.rsi});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(24), border: Border.all(color: border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TEKNİK KARNE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 16),
          _barItem('Hacim Yoğunluğu', (relVol / 5.0).clamp(0.0, 1.0), Colors.greenAccent),
          _barItem('RSI Baskısı', (rsi / 100.0).clamp(0.0, 1.0), Colors.orangeAccent),
        ],
      ),
    );
  }
  Widget _barItem(String label, double val, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)), Text('%${(val * 100).toInt()}', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 6),
          ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: val, color: color, backgroundColor: Colors.white10, minHeight: 5)),
        ],
      ),
    );
  }
}

class _AlertBannerWidget extends StatelessWidget {
  final bool isVip;
  final Color gold;
  const _AlertBannerWidget({required this.isVip, required this.gold});
  @override
  Widget build(BuildContext context) {
    final color = isVip ? gold : Colors.orangeAccent;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: color.withValues(alpha: .05), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: .2))),
      child: Row(children: [Icon(isVip ? Icons.warning_amber_rounded : Icons.local_fire_department_rounded, color: color, size: 18), const SizedBox(width: 10), Expanded(child: Text(isVip ? 'DİKKAT: Yüksek hacimli mal toplama emareleri var.' : 'Agresif hareket tespit edildi.', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)))]),
    );
  }
}


