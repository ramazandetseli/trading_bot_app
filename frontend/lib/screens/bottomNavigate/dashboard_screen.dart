import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trading_bot_app/screens/hisse/hisse_card.dart';
import 'package:trading_bot_app/models/hisse_model.dart';
import 'package:trading_bot_app/screens/hisse/stock_detail_screen.dart'; 

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isVipOnly = false;
  bool isFavoriteOnly = false;
  bool yukleniyor = false;
  String query = '';
  Set<String> favoriHisseler = {};

  List<dynamic> _rawResults = [];
  List<Hissemodel> _parsedModels = [];
  List<Hissemodel> _displayList = [];

  final TextEditingController _searchController = TextEditingController();

  //final String _localUrl = "https://trading-bot-backend-2pyt.onrender.com"; 
  static const String _localUrl = 'http://localhost:8000';
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    verileriTazele();
    _favorileriYukle();  // 👈 ekle
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────
  void _rawVerileriGuncelle(List<dynamic> yeniVeriler) {
    _rawResults = yeniVeriler;
    _parsedModels = yeniVeriler.map((v) => Hissemodel.fromMap(v)).toList();
    _displayListiHesapla();
  }

  void _displayListiHesapla() {
    final q = query.toLowerCase();
    _displayList = _parsedModels.where((hisse) {
      final vipOk = isVipOnly ? hisse.signal.contains('VIP') : true;
      final favOk = isFavoriteOnly ? favoriHisseler.contains(hisse.symbol) : true;
      final aramaOk = hisse.symbol.toLowerCase().contains(q);
      return vipOk && favOk && aramaOk;
    }).toList();
  }

  void _onSearchChanged() {
    setState(() {
      query = _searchController.text;
      _displayListiHesapla();
    });
  }

  void verileriTazele() async {
    setState(() => yukleniyor = true);
    try {
      final response = await http.get(Uri.parse("$_localUrl/tara"));
      if (response.statusCode == 200) {
        Map<String, dynamic> decodedData = json.decode(response.body);
        List<dynamic> results = decodedData['hisseler'] ?? [];
        
        setState(() {
          _rawVerileriGuncelle(results);
          yukleniyor = false;
        });
      } else {
        setState(() => yukleniyor = false);
      }
    } catch (e) {
      debugPrint("Dashboard veri tazeleme hatası: $e");
      setState(() => yukleniyor = false);
    }
  }


  Future<void> _alarmKurApiCall(String symbol, String priceText) async {
    final targetPrice = double.tryParse(priceText) ?? 0.0;
    try {
      final response = await http.post(
        Uri.parse(
          '$_localUrl/alarm-kur?symbol=$symbol&price=$targetPrice',
        ),
      );
      if (response.statusCode == 200 && mounted) {
        _kisaMesaj('$symbol için alarm kuruldu! 🚀');
      }
    } catch (e) {
      debugPrint('Alarm kurarken hata: $e');
    }
  }

  void favoriGuncelle(String symbol) {
    setState(() {
      if (favoriHisseler.contains(symbol)) {
        favoriHisseler.remove(symbol);
      } else {
        favoriHisseler.add(symbol);
      }
      if (isFavoriteOnly) _displayListiHesapla();
    });
  }

  void _kisaMesaj(String mesaj) {
    final overlayState = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .8),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              mesaj,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      ),
    );
    overlayState.insert(entry);
    Future.delayed(const Duration(seconds: 2), entry.remove);
  }

  void _alarmDialogGoster(Hissemodel model) {
    final priceController = TextEditingController(text: model.price.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          '${model.symbol} Alarm Kur',
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: priceController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Hedef Fiyat'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              _alarmKurApiCall(model.symbol, priceController.text);
              Navigator.pop(ctx);
            },
            child: const Text('Kur'),
          ),
        ],
      ),
    ).then((_) => priceController.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14), // Arka plan temasını eşitledik
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 110,
        leading: _buildToggleButton(
          isActive: isFavoriteOnly,
          activeColor: Colors.yellowAccent,
          icon: isFavoriteOnly ? Icons.star : Icons.star_border,
          label: isFavoriteOnly ? 'FAV' : 'ALL',
          onTap: () => setState(() {
            isFavoriteOnly = !isFavoriteOnly;
            _displayListiHesapla();
          }),
        ),
        title: const Text('Piyasa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          _buildToggleButton(
            isActive: isVipOnly,
            activeColor: Colors.amber,
            icon: Icons.bolt,
            label: isVipOnly ? 'VIP' : 'ALL',
            onTap: () => setState(() {
              isVipOnly = !isVipOnly;
              _displayListiHesapla();
            }),
            isAction: true,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 350,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search, color: Colors.white54),
                hintText: 'Hisse ara...',
                hintStyle: TextStyle(color: Colors.white38),
              ),
            ),
          ),
          const SizedBox(height: 30),
          if (yukleniyor)
            const Center(child: CircularProgressIndicator(color: Colors.amber))
          else
            Expanded(
              child: RefreshIndicator(
                color: Colors.greenAccent,
                backgroundColor: Colors.grey[900],
                onRefresh: () async {
                  verileriTazele();
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _displayList.length,
                  itemBuilder: _buildItem,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
  final model = _displayList[index];
  final isFav = favoriHisseler.contains(model.symbol);

  return HisseCard(
    hisse: model,
    isFav: isFav,
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HisseDetayScreen(
          hisse: _rawResults.firstWhere((r) => r['symbol'] == model.symbol),
        ),
      ),
    ),
    onFavoriDegisti: () => favoriGuncelle(model.symbol),
  );
}

  Widget _buildToggleButton({
    required bool isActive,
    required Color activeColor,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isAction = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: isAction ? 0 : 8,
        right: isAction ? 8 : 0,
        top: 6,
        bottom: 6,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            color: isActive ? activeColor.withValues(alpha: .1) : Colors.grey[900],
            border: Border.all(
              color: isActive ? activeColor : Colors.grey[800]!,
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                curve: Curves.easeInOut,
                duration: const Duration(milliseconds: 300),
                alignment: isActive ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 30,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? activeColor : Colors.grey[600],
                  ),
                  child: Icon(icon, size: 16, color: Colors.black),
                ),
              ),
              Center(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: isActive ? 0 : 25,
                    right: isActive ? 25 : 0,
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isActive ? activeColor : Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _favorileriYukle() async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return;

  try {
    final response = await http.get(Uri.parse("$_localUrl/favoriler/$userId"));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> liste = data['data'] ?? [];
      setState(() {
        favoriHisseler = Set<String>.from(liste);
      });
    }
  } catch (e) {
    debugPrint("Favoriler yüklenirken hata: $e");
  }
}
}