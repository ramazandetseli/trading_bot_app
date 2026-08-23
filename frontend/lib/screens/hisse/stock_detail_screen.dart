import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trading_bot_app/api/api_service.dart';
import 'package:trading_bot_app/api/premium_service.dart';
import 'package:trading_bot_app/screens/hisse/graphicscreen.dart';

class HisseDetayScreen extends StatefulWidget {
  final Map hisse;
  
  const HisseDetayScreen({super.key, required this.hisse});

  @override
  State<HisseDetayScreen> createState() => _HisseDetayScreenState();
}

class _HisseDetayScreenState extends State<HisseDetayScreen> with SingleTickerProviderStateMixin {
  String aiYorum = ''; 
  bool analizBitti = false;
  bool analizYukleniyor = false; 
  bool degerlerYuklendi = false; 
  double aiDestek = 0.0;
  double aiDirenc = 0.0;  

  String stratejiEtiketi = '';
  String fonAkisi = '';
  double riskSkoru = 0.0;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  
  Timer? _typeTimer; 
  
  // ─── Güvenli Veri Okuma Okuyucuları ────────────────────────────────────
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

  // ─── 🎨 Dinamik Premium Tema Renkleri ─────────────────────────────────
  Color get _bg      => const Color(0xFF070B14);
  Color get _card    => const Color(0xFF0D1420);
  Color get _border  => UserState().isPremium ? const Color(0xFFFFB800).withValues(alpha: 0.3) : const Color(0xFF1E293B);
  Color get _cyan    => UserState().isPremium ? const Color(0xFFFFB800) : const Color(0xFF00D4FF); 
  static const _gold    = Color(0xFFFFB800);

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

  void _tikitlaAnalizEt() {
    if (UserState().isPremium) {
      getAiComment();
    } else {
      if (UserState().dailyAiRights > 0) {
        setState(() {
          UserState().dailyAiRights--; 
        });
        getAiComment();
      } else {
        _showPremiumBottomSheet();
      }
    }
  }

  void _startTypewriterAnimation(String tamMetin) {
    final karakterListesi = tamMetin.characters.toList();
    int currentCharIndex = 0;
    _typeTimer?.cancel(); 

    setState(() {
      aiYorum = ''; 
      analizBitti = true;
      analizYukleniyor = false;
    });

    _typeTimer = Timer.periodic(const Duration(milliseconds: 15), (timer) { // Hızı 15ms yaptık kurumsal aksın amk
      if (currentCharIndex < karakterListesi.length) {
        if (!mounted) return;
        setState(() {
          aiYorum += karakterListesi[currentCharIndex]; 
        });
        currentCharIndex++;
      } else {
        timer.cancel(); 
      }
    });
  }

  // ─── 🎯 Geliştirilmiş API Çağrısı (Yeni Verileri Yakalayan Bölge) ─────
  Future<void> getAiComment() async {
    setState(() {
      analizYukleniyor = true;
      degerlerYuklendi = true; 
    });

    try {
      final aiData = await ApiService().aiAnaliziniCek(
        _symbol, _rsi, _relVol, _price, _change
      );
      
      if (!mounted) return;

      if (aiData != null) {
        final gonderilecekMetin = "${aiData['ozet']}\n\n"
            "📈 Teknik Rapor: ${aiData['teknik_durum']}\n\n"
            "🕵️ Tahta Dinamikleri: ${aiData['tahtaci_analizi']}";

        setState(() {
          // 1. Gelen finansal hedefleri atıyoruz amk
          aiDestek = double.tryParse(aiData['destek'].toString()) ?? 0.0;
          aiDirenc = double.tryParse(aiData['direnc'].toString()) ?? 0.0;
          
          // 2. 🐋 Python'da yazdığımız o ölümcül yeni balina parametrelerini yakalıyoruz amk
          stratejiEtiketi = aiData['strateji_etiketi']?.toString() ?? 'Hesaplanamadı';
          fonAkisi = aiData['fon_akisi']?.toString() ?? 'Dengeli Akış';
          riskSkoru = double.tryParse(aiData['risk_skoru'].toString()) ?? 50.0;
        });

        // 3. Yazma şovunu başlatıyoruz
        _startTypewriterAnimation(gonderilecekMetin);

      } else {
        setState(() {
          aiYorum = "AI şu an yoğun, lütfen tekrar deneyin.";
          analizBitti = true;
          analizYukleniyor = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        aiYorum = "Bağlantı hatası: Sunucu aktif mi?";
        analizBitti = true;
        analizYukleniyor = false;
      });
    }
  }

  void _showPremiumBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Icon(Icons.auto_awesome_rounded, color: _gold, size: 44),
            const SizedBox(height: 16),
            const Text("Premium Özelliktir", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
              "Günlük 3 yapay zeka analiz hakkınız dolmuştur. Sınırsız balina radarı ve özel Groq AI raporları için Profil sayfasından PRO'ya yükseltebilirsiniz.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.pop(context); 
                  Navigator.pop(context); 
                },
                child: const Text("Profil / Ayarlar Sayfasına Git", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildHeroHeader(),
              const SizedBox(height: 14),
              _buildStatsRow(),
              const SizedBox(height: 14),
              _buildCleanTargetGrid(), 
              const SizedBox(height: 14),
              if (analizBitti) _buildWhaleLiveMetrics(), // 🎯 YENİ: Balina Etiketleri ve Risk İbre Paneli amk!
              const SizedBox(height: 14),
              _buildAiCard(),          
              const SizedBox(height: 14),
              _buildPowerMeter(),
              const SizedBox(height: 14),
              _buildTechnicalReport(),
              if (_isVip || _isAgresif) ...[
                const SizedBox(height: 14),
                _buildAlertBanner(),
              ],
              const SizedBox(height: 16),
              _buildDisclaimer(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      title: Text(
        _symbol,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 1),
      ),
      centerTitle: true,
      actions: [
        if (!UserState().isPremium)
          IconButton(
            onPressed: () {
              // 🎯 BURAYA DİKKAT: _symbol değişkenini GraphViewScreen'e gönderiyoruz amk
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GraphViewScreen(symbol: _symbol),
                ),
              );
            },
            icon: const Icon(Icons.show_chart, color: _gold), // Premium icon'u grafik ikonuna çevirdim daha mantıklı aga
          )
      ],
    );
  }

  Widget _buildHeroHeader() {
    final accentColor = _isPositive ? Colors.greenAccent : Colors.redAccent;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 90, left: 16, right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border, width: 1),
      ),
      child: Column(
        children: [
          Text(
            _fullName,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: .4), fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _price.toStringAsFixed(2),
                style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900, letterSpacing: -1),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 6, left: 2),
                child: Text(' ₺', style: TextStyle(color: Colors.white30, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_isPositive ? '+' : ''}${_change.toStringAsFixed(2)}%',
              style: TextStyle(color: accentColor, fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _statChip('RSI', _rsi.toStringAsFixed(0), _rsi < 35 ? Colors.orangeAccent : _rsi > 70 ? Colors.redAccent : Colors.white70),
          const SizedBox(width: 8),
          _statChip('HACİM', 'x${_relVol.toStringAsFixed(1)}', _relVol > 2 ? Colors.greenAccent : Colors.white70),
          const SizedBox(width: 8),
          _statChip('TREND', _isBullish ? '▲ EMA20' : '▼ EMA20', _isBullish ? Colors.blueAccent : Colors.redAccent),
          const SizedBox(width: 8),
          _statChip('SİNYAL', _isVip ? '🐋 VIP' : _isAgresif ? '🔥 AGR' : 'SAKİN', _isVip ? _gold : _isAgresif ? Colors.orangeAccent : Colors.tealAccent),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildCleanTargetGrid() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: () {
        if (analizYukleniyor) {
          return const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
              ),
              SizedBox(width: 12),
              Text(
                "Hedef Seviyeler Hesaplanıyor...",
                style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          );
        }
        
        if (analizBitti) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _targetItem('DİRENÇ / HEDEF', '${_hedefDirenc.toStringAsFixed(2)} ₺', Colors.greenAccent),
              Container(width: 1, height: 35, color: _border),
              _targetItem('POTANSİYEL', '%${_potansiyel.toStringAsFixed(2)}', _cyan),
              Container(width: 1, height: 35, color: _border),
              _targetItem('DESTEK / STOP', '${_stopDestek.toStringAsFixed(2)} ₺', Colors.redAccent),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_clock_rounded, color: Colors.white.withValues(alpha: .3), size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                "Hedef & Stop Seviyeleri İçin Analiz Başlatın",
                style: TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      }(),
    );
  }

  Widget _targetItem(String title, String val, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Text(val, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
      ],
    );
  }

  // ─── 🐋 YENİ: Para Basacak Canavar Kurumsal Gösterge Paneli ──────────
  Widget _buildWhaleLiveMetrics() {
    bool isHighRisk = riskSkoru > 65;
    Color riskColor = isHighRisk ? Colors.redAccent : Colors.greenAccent;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cyan.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🤖 YAPAY ZEKA BALİNA TAKİP RADARI',
            style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 14),
          
          // 💥 Neon Strateji Etiketi
          _whaleMetricRow(Icons.radar_rounded, "Tahtacı Stratejisi:", stratejiEtiketi, _cyan),
          const SizedBox(height: 10),
          
          // 📊 Fon Akış İbresi
          _whaleMetricRow(Icons.swap_horizontal_circle_outlined, "Fon Akış Durumu:", fonAkisi, Colors.tealAccent),
          const SizedBox(height: 14),
          
          // 🔥 Yapay Zeka Risk Skoru Çubuğu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Yapay Zeka Risk İndeksi:", style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text("%${riskSkoru.toInt()}", style: TextStyle(color: riskColor, fontSize: 13, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: riskSkoru / 100,
              color: riskColor,
              backgroundColor: Colors.white.withValues(alpha: .04),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _whaleMetricRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAiCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: analizBitti ? _cyan.withValues(alpha: 0.3) : _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_rounded, color: _cyan, size: 22),
              const SizedBox(width: 8),
              Text('YAPAY ZEKA ANALİZİ', style: TextStyle(color: _cyan, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
              const Spacer(),
              if (!analizBitti && !analizYukleniyor)
                Text(
                  UserState().isPremium ? "PRO: Sınırsız" : "Hak: ${UserState().dailyAiRights}/3",
                  style: TextStyle(color: UserState().dailyAiRights == 0 && !UserState().isPremium ? Colors.redAccent : Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
                )
            ],
          ),
          const SizedBox(height: 16),
          if (analizYukleniyor)
            Column(
              children: [
                LinearProgressIndicator(color: _cyan, backgroundColor: Colors.white10),
                const SizedBox(height: 10),
                Text("Llama-3.3 borsa verilerini inceliyor...", style: TextStyle(color: Colors.white.withValues(alpha: .4), fontSize: 12)),
              ],
            )
          else if (analizBitti)
            Text(
              aiYorum,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cyan.withValues(alpha: .15),
                  foregroundColor: _cyan,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: _cyan, width: 0.5)),
                ),
                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: const Text("Analiz Et ve Rapor Oluştur", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: _tikitlaAnalizEt,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPowerMeter() {
    final score = _tahtaciSkoru;
    final isHigh = score > 70;
    final meterColor = isHigh ? Colors.greenAccent : _gold;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(24), border: Border.all(color: _border)),
      child: Column(
        children: [
          const Text('TAHTACI GÜVEN ENDEKSİ', style: TextStyle(color: Colors.white38, letterSpacing: 1.5, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 80,
                    width: 80,
                    child: CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      color: meterColor,
                      backgroundColor: Colors.white10,
                    ),
                  ),
                  Text('${score.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Text(
                  isHigh ? '🐋 Balina girişi tespit edildi. Tahtacı malı yukarı sürmeye kararlı görünüyor.' : '🤫 Hacim henüz sakin. Tahtacı çaktırmadan alttan toplama bölgesinde bekliyor.',
                  style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalReport() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(24), border: Border.all(color: _border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TEKNİK KARNE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 16),
          _barItem('Hacim Yoğunluğu', (_relVol / 5.0).clamp(0.0, 1.0), Colors.greenAccent),
          _barItem('RSI Baskısı',      (_rsi / 100.0).clamp(0.0, 1.0), Colors.orangeAccent),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              Text('%${(val * 100).toInt()}', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(value: val, color: color, backgroundColor: Colors.white10, minHeight: 5),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner() {
    final color = _isVip ? _gold : Colors.orangeAccent;
    final text  = _isVip
        ? 'DİKKAT: Bu hissede yüksek hacimli mal toplama emareleri var. Silkeleme operasyonu bitmiş olabilir.'
        : 'Agresif hareket tespit edildi. Volatiliteli bölge, stop seviyene sadık kal.';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withValues(alpha: .05), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: .2))),
      child: Row(
        children: [
          Icon(_isVip ? Icons.warning_amber_rounded : Icons.local_fire_department_rounded, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        'Bu sayfada görünen bilgiler yatırım tavsiyesi değildir.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white12, fontSize: 10, letterSpacing: 0.3),
      ),
    );
  }
}