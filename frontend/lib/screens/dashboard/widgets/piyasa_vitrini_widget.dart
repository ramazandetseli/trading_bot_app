import 'package:flutter/material.dart';
import 'package:trading_bot_app/screens/hisse/stock_detail_screen.dart';
import 'package:trading_bot_app/services/api_service.dart';
import 'package:intl/intl.dart';

class PiyasaVitriniWidget extends StatefulWidget {
  const PiyasaVitriniWidget({super.key});

  @override
  State<PiyasaVitriniWidget> createState() => _PiyasaVitriniWidgetState();
}

class _PiyasaVitriniWidgetState extends State<PiyasaVitriniWidget> {
  Map<String, dynamic>? _istatistikler;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _verileriCek();
  }

  Future<void> _verileriCek() async {
    final data = await ApiService().gunlukIstatistikleriGetir();
    if (mounted) {
      setState(() {
        _istatistikler = data;
        _loading = false;
      });
    }
  }

  String _formatHacim(double vol) {
    if (vol >= 1000000000) return "${(vol / 1000000000).toStringAsFixed(2)} Mr";
    if (vol >= 1000000) return "${(vol / 1000000).toStringAsFixed(2)} Mn";
    if (vol >= 1000) return "${(vol / 1000).toStringAsFixed(1)} B";
    return vol.toStringAsFixed(0);
  }

  String _formatFiyat(double price) {
    final formatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    return formatter.format(price);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
        ),
        child: const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
      );
    }

    if (_istatistikler == null || _istatistikler!['gainers'] == null) {
      return const SizedBox.shrink(); // Veri yoksa ekranda hiç yer kaplama
    }

    final gainers = _istatistikler!['gainers'] as List;
    final losers = _istatistikler!['losers'] as List;
    final volume = _istatistikler!['volume_leaders'] as List;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent), // Altındaki çizgiyi gizler
        child: ExpansionTile(
          iconColor: Colors.blueAccent,
          title: Row(
            children: [
              const Icon(Icons.analytics_outlined, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 10),
              const Text(
                "Piyasa Özeti (Top 5)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          children: [
            // Kutu açıldığında gösterilecek sekme ve listeler
            SizedBox(
              height: 250,
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    const TabBar(
                      indicatorColor: Colors.blueAccent,
                      labelColor: Colors.blueAccent,
                      dividerColor: Colors.transparent,
                      labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      tabs: [
                        Tab(icon: Icon(Icons.trending_up), text: "Yükselen"),
                        Tab(icon: Icon(Icons.trending_down), text: "Düşen"),
                        Tab(icon: Icon(Icons.bar_chart), text: "Hacim"),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildListe(gainers),
                          _buildListe(losers),
                          _buildListe(volume, isVolume: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListe(List items, {bool isVolume = false}) {
    final int itemCount = items.length > 5 ? 5 : items.length;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      physics: const BouncingScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (context, index) => Divider( height: 1.5),
      itemBuilder: (context, index) {
        final item = items[index];
        final symbol = item['symbol'];
        final price = item['price'];
        final change = item['change'];
        final vol = item['volume'];
        final isPositive = change >= 0;

        Color rankColor;
        if (index == 0) {
          rankColor = Colors.amber;
        } else if (index == 1) {
          rankColor = Colors.grey.shade400;
        } else if (index == 2) {
          rankColor = Colors.orangeAccent.shade200;
        } else {
          rankColor = Colors.blueAccent.withValues(alpha: 0.4);
        }

        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),

          leading: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: rankColor, width: 1.5),
            ),
            child: Text(
              "${index + 1}",
              style: TextStyle(
                color: rankColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          
          title: Text(symbol, style: const TextStyle( fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(
            isVolume ? "Hacim: ${_formatHacim(vol)}" : "Fiyat: ${_formatFiyat(price)}", 
            style: const TextStyle( fontSize: 11),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isPositive ? Colors.greenAccent.withValues(alpha: 0.1) : Colors.redAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              "${isPositive ? '+' : ''}${change.toStringAsFixed(2)}%",
              style: TextStyle(
                color: isPositive ? Colors.greenAccent : Colors.redAccent, 
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => HisseDetayScreen(hisse: {'symbol': symbol, 'price': price, 'change': change, 'volume': vol}),
            ));
          },
        );
      },
    );
  }
}