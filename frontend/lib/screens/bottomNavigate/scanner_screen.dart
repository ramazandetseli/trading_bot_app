import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:trading_bot_app/screens/hisse/hisse_card.dart';
import 'package:trading_bot_app/models/hisse_model.dart';
import 'dart:convert';
import '../hisse/stock_detail_screen.dart'; // Detay sayfası importu
import 'dart:async';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  List<dynamic> hisseler=[];
  List<dynamic> endeksler = [];
  bool yukleniyor=false;
  String? seciliMod;

  // 🎯 Canlı Render URL'miz
  final String url = "https://trading-bot-app-za72.onrender.com";

  Future<void> stratejiBaslat(String mode) async {
    setState(() {
      yukleniyor = true;
      seciliMod = mode;
      hisseler = []; // Eski listeyi temizle
    });

    try {
      // 🎯 Canlı adrese istek atıyoruz
      final response = await http.get(Uri.parse('$url/tara/$mode'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          hisseler = data['hisseler'];
          yukleniyor = false;
        });
      }
    } catch (e) {
      print("Aga hata: $e");
      setState(() { yukleniyor = false; });
    }
  }

  Future<void> endeksleriGetir() async {
    try {
      // 🎯 Canlı adrese istek atıyoruz
      final response = await http.get(Uri.parse('$url/endeksler'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          endeksler = data['veriler'];
        });
      }
    } catch (e) {
      print("Endeksler çekilirken hata oluştu: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    endeksleriGetir(); 
    
    Timer.periodic(const Duration(minutes: 5), (timer) {
      endeksleriGetir();
    });
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
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: endeksler.isEmpty 
            ? [Center(child: const Text("Veriler yükleniyor...", style: TextStyle(fontSize: 12, color: Colors.grey)))]
            : endeksler.map((e) => _bistIndexCard(e['name'], e['price'], e['change'])).toList(),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding:  const EdgeInsets.symmetric(vertical: 15),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _strategyButton("🚀 Momentum", "momentum", Colors.orangeAccent),
                  _strategyButton("📉 Dip Avcısı", "opportunity", Colors.blueAccent),
                  _strategyButton("⚡ Direnç Kırılımı", "breakout", Colors.purpleAccent), // Patlama yerine daha profesyonel bir isim
                  _strategyButton("💎 Hacim Kusması", "relativeVolume", Colors.lightBlueAccent),
                  _strategyButton("🎯 Trade Focus", "tradeFocus", Colors.yellow),
                  _strategyButton("🧨 Bollinger Sıkışması", "sikisma", Colors.redAccent),
                  _strategyButton("🥣 Dip Tepkisi", "corbaci", Colors.yellowAccent),
                ],
              ),
            ),
          ),
          Expanded(
            child: seciliMod==null 
            ? _buildEmptyState() 
            : yukleniyor
            ? Center(child: CircularProgressIndicator(color: Colors.greenAccent))
            : hisseler.isEmpty
            ? _buildNoResult()
            : ListView.builder(
              itemCount: hisseler.length,
              itemBuilder:(context, index) {
                final hisse=hisseler[index];
                return _buildHisseCard(hisse);
              },
              )
            )
        ],
      ),
    );
  }



  Widget _bistIndexCard(String label,String price, String change){
    bool isUp=change.contains("+");
    return Container(
      margin: EdgeInsets.only(right: 15),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[900], borderRadius: BorderRadius.circular(10)
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
      children: [
        Text("$label: ", style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
        const SizedBox(width: 6),
        Text(
          "%$change", 
          style: TextStyle(
            color: isUp ? Colors.greenAccent : Colors.redAccent, 
            fontSize: 12, 
            fontWeight: FontWeight.bold
          )
        ),
      ],
      ),
    );
  }

void _kisaMesaj(BuildContext context, String mod) {
  // Overlay state'ini alıyoruz
  OverlayState? overlayState = Overlay.of(context);
  
  // Ekranda yüzecek olan kutuyu tasarlıyoruz
  OverlayEntry overlayEntry = OverlayEntry(
    builder: (context) => Center( // Ekranın tam ortasına koyar
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: .8), // Şeffaf siyah
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            _getModAciklamasi(mod),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ),
    ),
  );

  // Mesajı ekrana çak
  overlayState.insert(overlayEntry);

  // 5 saniye sonra sessizce kaldır
  Future.delayed(const Duration(seconds: 2), () {
    overlayEntry.remove();
  });
}

  Widget _strategyButton(String label, String mode, Color color){
    bool aktif=seciliMod == mode;
    
    return GestureDetector(
      onTap: () => stratejiBaslat(mode),
      onDoubleTap: () =>_kisaMesaj(context, mode),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 500),
        padding: EdgeInsets.symmetric(horizontal: 20,vertical: 20),
        decoration: BoxDecoration(
          color: aktif ? color.withValues(alpha:0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: aktif ? color : Colors.grey[800]!),
        ),
        child: Text(label, style: TextStyle(color: aktif ? color : Colors.grey)),
        ),
    );
  }


  Widget _buildEmptyState(){
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.radar,size: 80,color: Colors.grey[700]),
            SizedBox(height: 80,),
            Text("aramaya başlamak için bir strateji seç."
            ,style: TextStyle(color: Colors.grey),)
          ],
        ),
      );
  }


  Widget _buildNoResult(){
      return Center(
        child: Text("Şu an bu kriterlere uyan hisse yok.",style: TextStyle(color: Colors.redAccent),),
      );

  }

  Widget _buildHisseCard(dynamic hisseVerisi) {
    // 1. Python'dan gelen karmaşık Map verisini, temiz HisseModel'imize çeviriyoruz
    final model = Hissemodel.fromMap(hisseVerisi);

    // 2. Sadece kartımızı çağırıp arkamıza yaslanıyoruz
    return HisseCard(
      hisse: model,
      // Eğer Scanner sayfasında da favori Set'in varsa 'favoriHisseler.contains(model.symbol)' yap. 
      // Yoksa şimdilik false kalsın.
      isFav:  false, 
      onTap: () {
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => HisseDetayScreen(hisse: hisseVerisi))
        );
      },
    );
  }
}