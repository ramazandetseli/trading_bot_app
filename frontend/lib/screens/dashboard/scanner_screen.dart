import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trading_bot_app/constants/app_constants.dart';
import 'package:trading_bot_app/screens/hisse/widgets/hisse_card.dart';
import 'package:trading_bot_app/models/hisse_model.dart';
import 'dart:convert';
import '../hisse/stock_detail_screen.dart';
import 'dart:async';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  List<dynamic> hisseler = [];
  List<dynamic> endeksler = [];
  Set<String> favoriHisseler = {};
  bool yukleniyor = false;
  bool hataVarMi = false;
  String? seciliMod;
  Timer? _timer;


  Future<void> stratejiBaslat(String mode) async {
    setState(() {
      yukleniyor = true;
      seciliMod = mode;
      hisseler = [];
      hataVarMi = false;
    });

    try {
      final response = await http.get(AppConstants.taraModUri(mode)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          hisseler = data['hisseler'];
          yukleniyor = false;
        });
      } else {
        setState(() { yukleniyor = false; hataVarMi = true; });
      }
    } catch (e) {
      setState(() { yukleniyor = false; hataVarMi = true; });
    }
  }

  Future<void> endeksleriGetir() async {
    try {
      final response = await http.get(AppConstants.endekslerUri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['islem_durumu'] == 'basarili') {
          setState(() => endeksler = data['veriler']);
        } else {
          setState(() => endeksler = [{"name": "Hata", "price": "Backend Hatası", "change": "+0.0"}]);
        }
      } else {
        setState(() => endeksler = [{"name": "HTTP", "price": "${response.statusCode}", "change": "+0.0"}]);
      }
    } catch (e) {
      setState(() => endeksler = [{"name": "Bağlantı Hatası", "price": "Hata", "change": "+0.0"}]);
      print("🚨 Hata Detayı: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    endeksleriGetir();
    _favorileriYukle();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) => endeksleriGetir());
  }

  
  Future<void> _favorileriYukle() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await http.get(AppConstants.favorilerUri(userId)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> liste = data['data'] ?? [];
        if (!mounted) return;
        setState(() {
          favoriHisseler = Set<String>.from(liste.map((e) => e.toString().toUpperCase()));
        });
      }
    } catch (e) {
      debugPrint("Scanner favori yükleme hatası: $e");
    }
  }

  void _favoriTetiklendi(String symbol) {
    setState(() {
      final sym = symbol.toUpperCase();
      if (favoriHisseler.contains(sym)) {
        favoriHisseler.remove(sym);
      } else {
        favoriHisseler.add(sym);
      }
    });
  }
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getModAciklamasi(String? mod) {
    switch (mod) {
      case "momentum":
        return "🚀 RSI > 60 ve hacmi artan, yükseliş trendi güçlü hisseler.";
      case "opportunity":
        return "📉 Aşırı düşmüş (RSI < 35) ama alıcıların gelmeye başladığı kağıtlar.";
      case "breakout":
        return "⚡ Dirençleri hacimli kırarak yeni bir kanal açanlar.";
      case "relativeVolume":
        return "💎 Anlık hacmi, 10 günlük ortalamanın 3 katını aşan 'Balina' girişi.";
      case "tradeFocus":
        return "🎯 Fiyat EMA 20'nin hemen üstünde, RSI 50'yi yukarı kırıp hacimli olanlar.";
      case "sikisma":
        return "🧨 Bollinger bantları daralmış, her an sert patlama yapabilecekler.";
      case "corbaci":
        return "🥣 RSI 25 altı olup, bugünkü alıcılarla ilk yeşil mumunu yakanlar.";
      default:
        return "🔍 Taramaya başlamak için yukarıdan bir strateji seç aga.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        titleSpacing: 16,
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: endeksler.isEmpty
                ? [Text("Piyasa verileri yükleniyor...", style: TextStyle(fontSize: 12))]
                : endeksler.map<Widget>((e) => _bistIndexCard(
                    e['name']?.toString() ?? "-",
                    e['price']?.toString() ?? "-",
                    e['change']?.toString() ?? "0",
                  )).toList(),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _strategyButton("🚀 Momentum", "momentum", Colors.orangeAccent),
                  _strategyButton("📉 Dip Avcısı", "opportunity", Colors.blueAccent),
                  _strategyButton("⚡ Direnç Kırılımı", "breakout", Colors.purpleAccent),
                  _strategyButton("💎 Hacim Kusması", "relativeVolume", Colors.lightBlueAccent),
                  _strategyButton("🎯 Trade Focus", "tradeFocus", Colors.yellow),
                  _strategyButton("🧨 Bollinger Sıkışması", "sikisma", Colors.redAccent),
                  _strategyButton("🥣 Dip Tepkisi", "corbaci", Colors.yellowAccent),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _getModAciklamasi(seciliMod),
                key: ValueKey(seciliMod),
                style: TextStyle(color: Colors.grey[500], fontSize: 12.5, height: 1.4),
              ),
            ),
          ),
          if (hisseler.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text("${hisseler.length} hisse bulundu", style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          Expanded(
            child: seciliMod == null
                ? _buildEmptyState()
                : yukleniyor
                ? _buildLoadingState()
                : hataVarMi
                ? _buildHataState()
                : hisseler.isEmpty
                ? _buildNoResult()
                : RefreshIndicator(
                    color: Colors.greenAccent,
                    onRefresh: () => stratejiBaslat(seciliMod!),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                      itemCount: hisseler.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => _buildHisseCard(hisseler[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _bistIndexCard(String label, String price, String change) {
    bool isUp = change.contains("+");
    final color = isUp ? Colors.greenAccent : Colors.redAccent;
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w600, letterSpacing: 0.3)),
              const SizedBox(height: 2),
              Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 10, color: color),
                const SizedBox(width: 2),
                Text("%$change", style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _strategyButton(String label, String mode, Color color) {
    bool aktif = seciliMod == mode;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: () => stratejiBaslat(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: aktif ? color.withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: aktif ? color.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.06), width: aktif ? 1.4 : 1),
              boxShadow: aktif ? [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 4))] : null,
            ),
            child: Text(label, style: TextStyle(color: aktif ? color : Colors.grey[400], fontSize: 13, fontWeight: aktif ? FontWeight.bold : FontWeight.w500)),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.greenAccent, strokeWidth: 2.4),
          const SizedBox(height: 16),
          Text("Taranıyor...", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildHataState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text("Bağlantı hatası, tekrar dene.", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          const SizedBox(height: 16),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => stratejiBaslat(seciliMod!),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
                ),
                child: const Text("Tekrar Dene", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.radar_rounded, size: 72, color: Colors.grey[800]),
          const SizedBox(height: 20),
          Text("Aramaya başlamak için yukarıdan\nbir strateji seç.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildNoResult() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: Colors.grey[700]),
          const SizedBox(height: 12),
          Text("Şu an bu kriterlere uyan hisse yok.", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildHisseCard(dynamic hisseVerisi) {
    final model = Hissemodel.fromMap(hisseVerisi);
    
    // 👈 O anki sembolün favori olup olmadığını kontrol et
    final bool isFavori = favoriHisseler.contains(model.symbol.toUpperCase());

    return HisseCard(
      hisse: model,
      isFav: isFavori, // 👈 false yerine dinamik değişkeni ver
      onFavoriDegisti: () => _favoriTetiklendi(model.symbol), // 👈 Callback'i bağla
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HisseDetayScreen(hisse: hisseVerisi)),
        );
      },
    );
  }
  
}