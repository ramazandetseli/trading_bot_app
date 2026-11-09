import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../models/ekonomik_takvim_model.dart';

class EkonomikTakvimScreen extends StatefulWidget {
  const EkonomikTakvimScreen({super.key});

  @override
  State<EkonomikTakvimScreen> createState() => _EkonomikTakvimScreenState();
}

class _EkonomikTakvimScreenState extends State<EkonomikTakvimScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _hataMesaji;
  List<EkonomikOlay> _yerelOlaylar = [];
  List<EkonomikOlay> _globalOlaylar = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _verileriGetir();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _verileriGetir() async {
    setState(() {
      _isLoading = true;
      _hataMesaji = null;
    });

    try {
      final res = await http.get(Uri.parse(AppConstants.ekonomikTakvimUrl)).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final decoded = json.decode(utf8.decode(res.bodyBytes));
        final data = TakvimResponse.fromJson(decoded);

        if (mounted) {
          setState(() {
            _yerelOlaylar = data.yerel;
            _globalOlaylar = data.global;
            _isLoading = false;
          });
        }
      } else {
        throw Exception("Sunucu hatası: ${res.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hataMesaji = "Veriler alınamadı: $e";
          _isLoading = false;
        });
      }
    }
  }

  Color _onemRengi(int score) {
    if (score >= 3) return Colors.redAccent;
    if (score == 2) return Colors.amber;
    return Colors.grey.shade400;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          "Ekonomik Takvim",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _verileriGetir,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blueAccent,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey.shade400,
          tabs: [
            Tab(text: "🇹🇷 Türkiye (${_yerelOlaylar.length})"),
            Tab(text: "🌐 Küresel (${_globalOlaylar.length})"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            )
          : _hataMesaji != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        _hataMesaji!,
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _verileriGetir,
                        child: const Text("Tekrar Dene"),
                      )
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOlayListesi(_yerelOlaylar),
                    _buildOlayListesi(_globalOlaylar),
                  ],
                ),
    );
  }

  Widget _buildOlayListesi(List<EkonomikOlay> liste) {
    if (liste.isEmpty) {
      return const Center(
        child: Text(
          "Yakın zamanda planlanan veri bulunmuyor.",
          style: TextStyle(color: Colors.white60),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _verileriGetir,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        itemCount: liste.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final olay = liste[index];
          final saatFormati = DateFormat('dd.MM.yyyy HH:mm').format(olay.date);

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _onemRengi(olay.importanceScore).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(olay.flag, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      olay.countryName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _onemRengi(olay.importanceScore).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        olay.importanceLevel,
                        style: TextStyle(
                          color: _onemRengi(olay.importanceScore),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      saatFormati,
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  olay.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDegerKutusu("Açıklanan", olay.formatDeger(olay.actual),
                          degerRengi: olay.actual != null ? Colors.greenAccent : Colors.white70),
                      _buildDegerKutusu("Beklenti", olay.formatDeger(olay.forecast)),
                      _buildDegerKutusu("Önceki", olay.formatDeger(olay.previous)),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDegerKutusu(String baslik, String deger, {Color degerRengi = Colors.white70}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          baslik,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          deger,
          style: TextStyle(
            color: degerRengi,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}