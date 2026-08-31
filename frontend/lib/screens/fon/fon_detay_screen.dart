import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:trading_bot_app/models/fon_model.dart';
import 'package:trading_bot_app/services/fon_service.dart';

class FonDetayScreen extends StatefulWidget {
  final String fonKodu;

  const FonDetayScreen({super.key, required this.fonKodu});

  @override
  State<FonDetayScreen> createState() => _FonDetayScreenState();
}

class _FonDetayScreenState extends State<FonDetayScreen> {
  String _selectedPeriod = "3ay";
  bool _loading = true;
  String? _errorMessage;

  // Sadece yeni Modellerimizi tanımlıyoruz (Eski Map listelerini sildik)
  FonDetayModel? _fonDetay;
  FonKiyaslamaModel? _fonKiyaslama;
  String _fonTipi = "Yatırım Fonu";

  final FonService _fonService = FonService();
  
  @override
  void initState() {
    super.initState();
    _tumVerileriYukle();
  }

  Future<void> _tumVerileriYukle() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // 3 servisi paralel çalıştırıp hazır modelleri tek satırda alıyoruz
      final sonuclar = await Future.wait([
        _fonService.getFonDetay(widget.fonKodu, aralik: _selectedPeriod),
        _fonService.getFonKiyaslama(widget.fonKodu),
        _fonService.getFonTipi(widget.fonKodu),
      ]);

      setState(() {
        _fonDetay = sonuclar[0] as FonDetayModel;
        _fonKiyaslama = sonuclar[1] as FonKiyaslamaModel;
        _fonTipi = sonuclar[2] as String;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  void _onPeriodChanged(String period) {
    if (_selectedPeriod == period) return;
    setState(() => _selectedPeriod = period);
    _tumVerileriYukle();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.fonKodu.toUpperCase(),
          style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _tumVerileriYukle,
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _tumVerileriYukle,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderCard(colorScheme),
                        const SizedBox(height: 20),
                        _buildPeriodSelector(colorScheme),
                        const SizedBox(height: 20),
                        _buildChartSection(colorScheme),
                        const SizedBox(height: 24),
                        _buildKategoriCard(colorScheme),
                        const SizedBox(height: 24),
                        _buildBenchmarkSection(colorScheme),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeaderCard(ColorScheme colorScheme) {
    // Modelden verilere NOKTA ile erişiyoruz
    final unvan = _fonDetay?.fonUnvani ?? '';
    final sonFiyat = _fonDetay?.sonFiyat ?? 0.0;
    final getiri = _fonDetay?.donemselGetiriYuzde ?? 0.0;
    final isPositive = getiri >= 0;
    final trendColor = isPositive ? const Color(0xFF00C853) : const Color(0xFFD50000);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: .3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _fonTipi,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      color: trendColor,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isPositive ? '+' : ''}%${getiri.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: trendColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            unvan,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₺${sonFiyat.toStringAsFixed(4)}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Text(
                  '($_selectedPeriod getirisi)',
                  style: TextStyle(fontSize: 12, color: colorScheme.outline),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(ColorScheme colorScheme) {
    final periods = [
      {'label': '1 Ay', 'value': '1ay'},
      {'label': '3 Ay', 'value': '3ay'},
      {'label': '6 Ay', 'value': '6ay'},
      {'label': '1 Yıl', 'value': '1yil'},
    ];

    return Row(
      children: periods.map((p) {
        final isSelected = _selectedPeriod == p['value'];
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _onPeriodChanged(p['value']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    p['label']!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChartSection(ColorScheme colorScheme) {
    final grafikListesi = _fonDetay?.grafikVerileri ?? [];
    
    if (grafikListesi.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        child: const Text('Grafik verisi bulunamadı.'),
      );
    }

    final double sonGetiri = _fonDetay?.donemselGetiriYuzde ?? 0.0;
    final bool isPositive = sonGetiri >= 0;
    final Color lineColor = isPositive ? const Color(0xFF00C853) : const Color(0xFFD50000);

    final spots = grafikListesi.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.price); // Map yerine model classı kullandığımız için e.value.price
    }).toList();

    double minPrice = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    double maxPrice = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    double padding = (maxPrice - minPrice) * 0.1;
    if (padding == 0) padding = minPrice * 0.05;

    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: colorScheme.outlineVariant.withValues(alpha: .2),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: (grafikListesi.length / 4).clamp(1, double.infinity),
                getTitlesWidget: (value, meta) {
                  int idx = value.toInt();
                  if (idx < 0 || idx >= grafikListesi.length) return const SizedBox.shrink();
                  
                  final date = grafikListesi[idx].date; // String parse etmeye gerek kalmadı, modelde DateTime zaten
                  
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      DateFormat('dd MMM').format(date),
                      style: TextStyle(fontSize: 10, color: colorScheme.outline),
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
                  final item = grafikListesi[spot.spotIndex];
                  final dateFormatted = DateFormat('dd.MM.yyyy').format(item.date);
                  
                  return LineTooltipItem(
                    '₺${spot.y.toStringAsFixed(4)}\n$dateFormatted',
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
              color: lineColor,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    lineColor.withValues(alpha: .3),
                    lineColor.withValues(alpha: .0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKategoriCard(ColorScheme colorScheme) {
    // Yine modellere noktalı erişim
    final derece = _fonDetay?.kategoriDerecesi;
    final toplam = _fonDetay?.kategoriToplamFon;

    if (derece == null || toplam == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(colorScheme, 'Kategori Sıralaması', '$derece. / $toplam Fon'),
          Container(width: 1, height: 30, color: colorScheme.outlineVariant.withValues(alpha: .5)),
          _buildInfoItem(colorScheme, 'Başarı Dilimi', '%${((derece / toplam) * 100).toStringAsFixed(1)} içinde'),
        ],
      ),
    );
  }

  Widget _buildBenchmarkSection(ColorScheme colorScheme) {
    final kiyaslamaListesi = _fonKiyaslama?.kiyaslamaAraclari ?? [];
    
    if (kiyaslamaListesi.isEmpty) return const SizedBox.shrink();

    final fonGetiri = _fonKiyaslama?.fon?.getiriYuzde ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '1 Yıllık Getiri Kıyaslaması',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              'Benchmark',
              style: TextStyle(fontSize: 12, color: colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // Fonun Kendisi
              _buildBenchmarkBar(
                colorScheme: colorScheme,
                title: widget.fonKodu.toUpperCase(),
                yuzde: fonGetiri,
                isMainFund: true,
              ),
              const Divider(height: 20),
              // Diğer Enstrümanlar
              ...kiyaslamaListesi.map((item) {
                final double yuzde = item.getiriYuzde;
                final title = item.enstruman.isNotEmpty ? item.enstruman : item.kod;
                
                return _buildBenchmarkBar(
                  colorScheme: colorScheme,
                  title: title,
                  yuzde: yuzde,
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBenchmarkBar({
    required ColorScheme colorScheme,
    required String title,
    required double yuzde,
    bool isMainFund = false,
  }) {
    final bool isPos = yuzde >= 0;
    final color = isMainFund
        ? colorScheme.primary
        : isPos
            ? const Color(0xFF00C853)
            : const Color(0xFFD50000);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isMainFund ? FontWeight.bold : FontWeight.w500,
                color: isMainFund ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (yuzde.abs() / 100).clamp(0.05, 1.0),
                backgroundColor: colorScheme.outlineVariant.withValues(alpha: .2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            child: Text(
              '${isPos ? '+' : ''}%${yuzde.toStringAsFixed(2)}',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(ColorScheme colorScheme, String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: colorScheme.outline)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
      ],
    );
  }
}