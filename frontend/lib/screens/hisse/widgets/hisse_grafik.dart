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
      final uri = Uri.parse("${AppConstants.baseUrl}/hisse-tarihsel/${widget.symbol}?period=$_selectedPeriod");
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
    return Column(
      children: [
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00D4FF)))
              : _error != null || _veriListesi.isEmpty
                  ? Center(child: Text(_error ?? "Veri bulunamadı.", style: const TextStyle(color: Colors.white38, fontSize: 12)))
                  : _buildLineChart(),
        ),

        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _periods.map((p) {
              final isSelected = _selectedPeriod == p['value'];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    if (_selectedPeriod != p['value']) {
                      setState(() => _selectedPeriod = p['value']!);
                      widget.onPeriodChanged(_selectedPeriod);
                      _verileriCek();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF00D4FF) : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      p['label']!,
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white60,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

      ],
    );
  }

  Widget _buildLineChart() {
    final spots = _veriListesi.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.close);
    }).toList();

    double minPrice = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    double maxPrice = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    // Yatay sıkışmayı önleyen %10 dinamik nefes payı
    double padding = (maxPrice - minPrice) * 0.10;
    if (padding == 0) padding = minPrice * 0.05;

    final isPositive = _veriListesi.last.close >= _veriListesi.first.open;
    final color = isPositive ? const Color(0xFF00E676) : const Color(0xFFFF5252);

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 16, 0),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.white.withValues(alpha: 0.04),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: (_veriListesi.length / 4).clamp(1, double.infinity),
                getTitlesWidget: (val, _) {
                  int idx = val.toInt();
                  if (idx < 0 || idx >= _veriListesi.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      DateFormat('dd MMM').format(_veriListesi[idx].date),
                      style: const TextStyle(color: Colors.white30, fontSize: 10),
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
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final item = _veriListesi[spot.spotIndex];
                  return LineTooltipItem(
                    "₺${spot.y.toStringAsFixed(2)}\n${DateFormat('dd.MM.yyyy HH:mm').format(item.date)}",
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.2,
              color: color,
              barWidth: 2.2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}