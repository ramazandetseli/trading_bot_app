import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:trading_bot_app/constants/app_constants.dart';
import 'package:trading_bot_app/models/hisse_tarihsel_model.dart';

class HisseGrafikWidget extends StatefulWidget {
  final String symbol;
  final Function(double, double) onDataFetched;
  final Function(String) onPeriodChanged;

  const HisseGrafikWidget({
    super.key,
    required this.symbol,
    required this.onDataFetched,
    required this.onPeriodChanged,
  });

  @override
  State<HisseGrafikWidget> createState() => _HisseGrafikWidgetState();
}

class _HisseGrafikWidgetState extends State<HisseGrafikWidget> {
  String _selectedPeriod = "1mo";
  bool _loading = true;
  String? _error;
  List<HisseTarihselNokta> _veriListesi = [];

  final List<Map<String, String>> _periods = [
    {"label": "1G", "value": "1d"},
    {"label": "5G", "value": "5d"},
    {"label": "1A", "value": "1mo"},
    {"label": "1Y", "value": "1y"},
    {"label": "5Y", "value": "5y"},
  ];

  @override
  void initState() {
    super.initState();
    _verileriCek();
  }

  Future<void> _verileriCek() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uri = AppConstants.hisseTarihselUri(widget.symbol, _selectedPeriod);
      final res = await http.get(uri).timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        if (data['status'] == 'success') {
          final list = (data['data'] as List? ?? [])
              .map((e) => HisseTarihselNokta.fromJson(e))
              .toList();

          if (list.isNotEmpty) {
            final sonFiyat = list.last.close;
            final ilkFiyat = list.first.open;
            final degisim = ilkFiyat > 0 ? ((sonFiyat - ilkFiyat) / ilkFiyat) * 100 : 0.0;
            widget.onDataFetched(sonFiyat, degisim);
          }

          setState(() {
            _veriListesi = list;
            _loading = false;
          });
          return;
        }
      }
      setState(() {
        _error = "Grafik verisi alınamadı.";
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Bağlantı hatası: $e";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Veri varsa istatistikleri hesapla
    double? currentPrice, changePercent, highPrice, lowPrice;
    if (_veriListesi.isNotEmpty) {
      currentPrice = _veriListesi.last.close;
      final ilkFiyat = _veriListesi.first.open;
      changePercent = ilkFiyat > 0 ? ((currentPrice - ilkFiyat) / ilkFiyat) * 100 : 0.0;
      highPrice = _veriListesi.map((e) => e.close).reduce((a, b) => a > b ? a : b);
      lowPrice = _veriListesi.map((e) => e.close).reduce((a, b) => a < b ? a : b);
    }

    final isPositive = changePercent != null && changePercent >= 0;
    final trendColor = isPositive ? const Color(0xFF00E676) : const Color(0xFFFF5252);

    return Column(
      children: [
        // 1. EKLEME: Fiyat ve Değişim Özeti (Header)
        if (_veriListesi.isNotEmpty && !_loading)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Güncel Fiyat", style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      "₺${currentPrice!.toStringAsFixed(2)}",
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("Değişim", style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: trendColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${isPositive ? '+' : ''}${changePercent!.toStringAsFixed(2)}%",
                        style: TextStyle(color: trendColor, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // 2. EKLEME: En Yüksek / En Düşük Bilgi Çubuğu
        if (_veriListesi.isNotEmpty && !_loading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatChip("En Yüksek", "₺${highPrice!.toStringAsFixed(2)}", const Color(0xFF00E676)),
                Container(width: 1, height: 20, color: Colors.white.withValues(alpha: 0.1)),
                _buildStatChip("En Düşük", "₺${lowPrice!.toStringAsFixed(2)}", const Color(0xFFFF5252)),
              ],
            ),
          ),

        Expanded(
          child: _loading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF00D4FF)),
                      SizedBox(height: 16),
                      Text("Veriler yükleniyor...", style: TextStyle(color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                )
              : _error != null || _veriListesi.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.area_chart_outlined, color: Colors.white24, size: 48),
                          const SizedBox(height: 12),
                          Text(_error ?? "Veri bulunamadı.", style: const TextStyle(color: Colors.white54, fontSize: 14)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _verileriCek,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text("Tekrar Dene"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00D4FF),
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _buildLineChart(),
        ),

        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _periods.map((p) {
                final isSelected = _selectedPeriod == p['value'];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        if (_selectedPeriod != p['value']) {
                          setState(() => _selectedPeriod = p['value']!);
                          widget.onPeriodChanged(_selectedPeriod);
                          _verileriCek();
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF00D4FF) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isSelected
                              ? [BoxShadow(color: const Color(0xFF00D4FF).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          p['label']!,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white54,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // Yardımcı Widget: İstatistik Çipi
  Widget _buildStatChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }

  Widget _buildLineChart() {
    final spots = _veriListesi.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.close);
    }).toList();

    double minPrice = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    double maxPrice = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    double padding = (maxPrice - minPrice) * 0.10;
    if (padding == 0) padding = minPrice * 0.05;

    final isPositive = _veriListesi.last.close >= _veriListesi.first.open;
    final color = isPositive ? const Color(0xFF00E676) : const Color(0xFFFF5252);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.white.withValues(alpha: 0.06),
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            // 3. EKLEME: Sağ Tarafta Fiyat Etiketleri (Kullanıcı için çok daha anlaşılır)
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                interval: (maxPrice - minPrice) / 4, // Yaklaşık 4 etiket göster
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      '₺${value.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: (_veriListesi.length / 5).ceilToDouble().clamp(1, double.infinity),
                getTitlesWidget: (val, _) {
                  int idx = val.toInt();
                  if (idx < 0 || idx >= _veriListesi.length) return const SizedBox.shrink();
                  
                  final date = _veriListesi[idx].date;
                  final format = _selectedPeriod == '1d' || _selectedPeriod == '5d' 
                      ? DateFormat('HH:mm') 
                      : DateFormat('dd MMM');
                      
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      format.format(date),
                      style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minY: (minPrice - padding).clamp(0, double.infinity),
          maxY: maxPrice + padding,
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            // 4. EKLEME: Profesyonel Crosshair (Dikey Çizgi) ve Vurgulu Nokta
            getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
              return spotIndexes.map((index) {
                return TouchedSpotIndicatorData(
                  FlLine(
                    color: Colors.white.withValues(alpha: 0.4),
                    strokeWidth: 1.5,
                    dashArray: [4, 4],
                  ),
                  FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, idx) => FlDotCirclePainter(
                      radius: 5,
                      color: Colors.white,
                      strokeWidth: 2.5,
                      strokeColor: color,
                    ),
                  ),
                );
              }).toList();
            },
            touchTooltipData: LineTouchTooltipData(
               tooltipPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final item = _veriListesi[spot.spotIndex];
                  final spotIsPositive = item.close >= _veriListesi.first.open;
                  final textColor = spotIsPositive ? const Color(0xFF00E676) : const Color(0xFFFF5252);
                  
                  return LineTooltipItem(
                    "₺${spot.y.toStringAsFixed(2)}\n",
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    children: [
                      TextSpan(
                        text: DateFormat('dd MMM yyyy, HH:mm').format(item.date),
                        style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w400, fontSize: 11),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: color,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false), // Normalde nokta yok, sadece touch'ta var
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.2),
                    color.withValues(alpha: 0.05),
                    color.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}