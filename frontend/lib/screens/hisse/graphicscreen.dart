import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:trading_bot_app/api/api_service.dart';
import 'package:trading_bot_app/screens/hisse/alarm_kur.dart';

class HisseMumu {
  final DateTime tarih;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;

  HisseMumu(this.tarih, this.open, this.high, this.low, this.close, this.volume);
}

class GraphViewScreen extends StatefulWidget {
  final String symbol;
  const GraphViewScreen({super.key, required this.symbol});

  @override
  State<GraphViewScreen> createState() => _GraphViewScreenState();
}

class _GraphViewScreenState extends State<GraphViewScreen> {
  List<HisseMumu> fiyatNoktalari = [];
  bool yukleniyor = true;
  String seciliZaman = '1A';
  
  // 🎯 GRAFİK TÜRÜ (Mum mu Çizgi mi?)
  bool mumGrafigiMi = true;

  // 🎯 ÇİZİM VE ARAÇ DEĞİŞKENLERİ
  bool cizimModuAktif = false;
  List<double> yatayCizgiler = []; 
  double? suruklenenCizgi;

  late TrackballBehavior _trackballBehavior;
  late ZoomPanBehavior _zoomPanBehavior;
  ChartSeriesController? _chartSeriesController;

  // 🎯 GÜNLÜK İSTATİSTİKLER İÇİN DEĞİŞKENLER
  String gunlukAcilis = "-";
  String gunlukKapanis = "-";
  String gunlukEnYuksek = "-";
  String gunlukEnDusuk = "-";
  String gunlukHacim = "-";

  @override
  void initState() {
    super.initState();
    
  _trackballBehavior = TrackballBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        builder: (BuildContext context, TrackballDetails details) {
          // 🎯 Seçilen noktanın index'ini alıp listemizdeki o mumu yakalıyoruz amk!
          if (details.pointIndex == null || details.pointIndex! < 0) return const SizedBox.shrink();
          
          final mum = fiyatNoktalari[details.pointIndex!];
          
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(
              '${mum.close.toStringAsFixed(2)} ₺', // Mum da olsa çizgi de olsa Kapanış fiyatını gösterir
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          );
        },
      );
      
    // Parmakla sıkıştırma, genişletme ve kaydırma hareketleri
    _zoomPanBehavior = ZoomPanBehavior(
      enablePinching: true, 
      enablePanning: true,  
      zoomMode: ZoomMode.xy, 
    );
    
    _veriyiCekVeGrafikYap();
  }
  String _formatXAxisLabel(DateTime dt) {
      if (seciliZaman == '1G') {
        return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      } else {
        return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      }
    }
  Future<void> _veriyiCekVeGrafikYap() async {
    setState(() => yukleniyor = true);
    try {
      String apiPeriod = '1mo';
      if (seciliZaman == '1G') apiPeriod = '1d';
      if (seciliZaman == '1H') apiPeriod = '5d';
      if (seciliZaman == '1A') apiPeriod = '1mo';
      if (seciliZaman == '1Y') apiPeriod = '1y';

      // Backend'den (Unix timestamp ile) dönen yeni JSON formatını çekiyoruz
      final Map<String, dynamic> response = await ApiService().getHisseTarihsel(widget.symbol, apiPeriod);
      final List data = response['data'] ?? [];
      
      setState(() {
        fiyatNoktalari = data.map((json) {
          return HisseMumu(
            DateTime.fromMillisecondsSinceEpoch(json['time'] * 1000), // Unix saniyeyi DateTime yap
            double.parse(json['open'].toString()),
            double.parse(json['high'].toString()),
            double.parse(json['low'].toString()),
            double.parse(json['close'].toString()),
            int.parse(json['volume'].toString()),
          );
        }).toList();

      if (fiyatNoktalari.isNotEmpty) {
                // Listedeki en yüksek ve en düşük değerleri matematiksel olarak süzüyoruz amk
                double enYuksek = fiyatNoktalari.map((e) => e.high).reduce((a, b) => a > b ? a : b);
                double enDusuk = fiyatNoktalari.map((e) => e.low).reduce((a, b) => a < b ? a : b);
                // Tüm hacmi topluyoruz
                double toplamHacim = fiyatNoktalari.fold(0, (sum, item) => sum + item.volume);

                gunlukAcilis = fiyatNoktalari.first.open.toStringAsFixed(2); // İlk açılış
                gunlukKapanis = fiyatNoktalari.last.close.toStringAsFixed(2); // Son kapanış
                gunlukEnYuksek = enYuksek.toStringAsFixed(2);
                gunlukEnDusuk = enDusuk.toStringAsFixed(2);
                gunlukHacim = _hacimFormatla(toplamHacim.toInt());
              } else {
                gunlukAcilis = "-"; gunlukEnYuksek = "-"; gunlukEnDusuk = "-"; gunlukHacim = "-"; gunlukKapanis = "-";
              }
              
              yukleniyor = false;
      });
    } catch (e) {
      print("Grafik yüklenemedi: $e");
      setState(() => yukleniyor = false);
    }
  }

  String _hacimFormatla(int hacim) {
    if (hacim > 1000000) return "${(hacim / 1000000).toStringAsFixed(2)} M";
    if (hacim > 1000) return "${(hacim / 1000).toStringAsFixed(2)} B";
    return hacim.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        title: Text("${widget.symbol} Analiz", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // 🎯 MUM / ÇİZGİ GRAFİĞİ DEĞİŞTİRME BUTONU
          IconButton(
            onPressed: () {
              setState(() {
                mumGrafigiMi = !mumGrafigiMi;
              });
            },
            icon: Icon(
              mumGrafigiMi ? Icons.show_chart_rounded : Icons.candlestick_chart_rounded,
              color: Colors.greenAccent,
            ),
            tooltip: mumGrafigiMi ? "Çizgi Grafiğine Geç" : "Mum Grafiğine Geç",
          ),
        ],
      ),
      // 🎯 SAYFA KAYDIRILABİLİR OLACAK AMK
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDrawingToolbar(),
            
            // 🎯 GRAFİK ALANI (Kaydırma çakışmasın diye sabit yükseklik verdik)
            SizedBox(
              height: 400,
              child: yukleniyor
                  ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
                  : Padding(
                      padding: const EdgeInsets.only(right: 8.0, left: 8.0),
                      child: _buildGrafik(),
                    ),
            ),
            
            const SizedBox(height: 10),
            _buildTimeFilters(),
            
            const SizedBox(height: 20),
            
            // 🎯 ALT BÖLÜM: FİYAT İSTATİSTİKLERİ VE ALARM
            _buildIstatistikBolumu(),
            
            const SizedBox(height: 30),
            
            // 🎯 ALARM KUR BUTONU
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
               onPressed: () {
                  double guncelFiyat = fiyatNoktalari.isNotEmpty 
                      ? fiyatNoktalari.last.close 
                      : 0.0;

                  // 2. AlarmKur sınıfını çağırıyoruz
                  AlarmKur.goster(
                    context: context, 
                    symbol: widget.symbol, // Sınıfın en üstünden gelen sembol (örn: THYAO)
                    anlikFiyat: guncelFiyat, // Yukarıda bulduğumuz güncel fiyat
                  );
                },
                icon: const Icon(Icons.alarm_add_rounded, color: Colors.greenAccent),
                label: const Text("Alarm Kur", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            
            const SizedBox(height: 40), // En alt boşluk
          ],
        ),
      ),
    );
  }

  Widget _buildGrafik() {
    return SfCartesianChart(
      backgroundColor: Colors.transparent,
      trackballBehavior: cizimModuAktif ? TrackballBehavior(enable: false) : _trackballBehavior,
      zoomPanBehavior: _zoomPanBehavior,
      plotAreaBorderWidth: 0,
      
      primaryXAxis: CategoryAxis(
        majorGridLines: const MajorGridLines(width: 0),
        axisLine: const AxisLine(width: 0),
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 10),
        labelRotation: -45, 
        labelIntersectAction: AxisLabelIntersectAction.hide, 
      ),   
      primaryYAxis: NumericAxis(
        opposedPosition: true, 
        decimalPlaces: 2, // 00.00 Kuruş formatı
        labelFormat: '{value} ₺',
        axisLine: const AxisLine(width: 0),
        majorGridLines: MajorGridLines(width: 1, color: Colors.white.withValues(alpha: 0.05)),
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
        
        plotBands: yatayCizgiler.map((cizgiY) => PlotBand(
          isVisible: true,
          start: cizgiY,
          end: cizgiY,
          borderColor: suruklenenCizgi == cizgiY ? Colors.orangeAccent : Colors.blueAccent,
          borderWidth: suruklenenCizgi == cizgiY ? 3 : 2,
          dashArray: const <double>[5, 5],
          text: '${cizgiY.toStringAsFixed(2)} ₺',
          textStyle: TextStyle(color: suruklenenCizgi == cizgiY ? Colors.orangeAccent : Colors.blueAccent, fontWeight: FontWeight.bold),
          horizontalTextAlignment: TextAnchor.end,
        )).toList(),
      ),
      
      // ÇİZGİYE DOKUNMA VE SÜRÜKLEME MANTIĞI
      onChartTouchInteractionDown: (ChartTouchInteractionArgs args) {
        if (_chartSeriesController == null || yatayCizgiler.isEmpty) return;
        CartesianChartPoint<dynamic> point = _chartSeriesController!.pixelToPoint(args.position);
        double dokunulanFiyat = (point.y ?? 0.0).toDouble();

        double enYakin = yatayCizgiler.reduce((a, b) => (a - dokunulanFiyat).abs() < (b - dokunulanFiyat).abs() ? a : b);
        if ((enYakin - dokunulanFiyat).abs() / dokunulanFiyat < 0.03) {
          setState(() { suruklenenCizgi = enYakin; });
        }
      },

      onChartTouchInteractionMove: (ChartTouchInteractionArgs args) {
        if (suruklenenCizgi != null) {
          CartesianChartPoint<dynamic> point = _chartSeriesController!.pixelToPoint(args.position);
          double yeniFiyat = (point.y ?? 0.0).toDouble();
          setState(() {
            int index = yatayCizgiler.indexOf(suruklenenCizgi!);
            if (index != -1) {
              yatayCizgiler[index] = yeniFiyat;
              suruklenenCizgi = yeniFiyat; 
            }
          });
        }
      },

      onChartTouchInteractionUp: (ChartTouchInteractionArgs args) {
        if (cizimModuAktif && suruklenenCizgi == null && _chartSeriesController != null) {
          CartesianChartPoint<dynamic> point = _chartSeriesController!.pixelToPoint(args.position);
          setState(() {
            yatayCizgiler.add((point.y ?? 0.0).toDouble());
            cizimModuAktif = false;
          });
        }
        setState(() { suruklenenCizgi = null; });
      },
      
      series: <CartesianSeries<HisseMumu, String>>[
        if (mumGrafigiMi)
          CandleSeries<HisseMumu, String>( // 🎯 Burası da String
            dataSource: fiyatNoktalari,
            // 🎯 X EKSENİNE FONKSİYONDAN ÇIKAN KISA TARİHİ VERİYORUZ
            xValueMapper: (HisseMumu data, _) => _formatXAxisLabel(data.tarih),
            lowValueMapper: (HisseMumu data, _) => data.low,
            highValueMapper: (HisseMumu data, _) => data.high,
            openValueMapper: (HisseMumu data, _) => data.open,
            closeValueMapper: (HisseMumu data, _) => data.close,
            bullColor: Colors.greenAccent, 
            bearColor: Colors.redAccent, 
            enableSolidCandles: true, 
            animationDuration: 500,
            onRendererCreated: (ChartSeriesController controller) => _chartSeriesController = controller,
          )
        else
          LineSeries<HisseMumu, String>( // 🎯 Burası da String
            dataSource: fiyatNoktalari,
            // 🎯 X EKSENİNE FONKSİYONDAN ÇIKAN KISA TARİHİ VERİYORUZ
            xValueMapper: (HisseMumu data, _) => _formatXAxisLabel(data.tarih),
            yValueMapper: (HisseMumu data, _) => data.close,
            color: Colors.greenAccent,
            width: 2,
            animationDuration: 500,
            onRendererCreated: (ChartSeriesController controller) => _chartSeriesController = controller,
          )
      ],
    );
  }

  // --- ARAÇ ÇUBUĞU VE GERİ AL ---
  Widget _buildDrawingToolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // Sol taraftaki araçlar
          _toolbarIcon(Icons.horizontal_rule_rounded, "Yatay Işın", () {
            setState(() { cizimModuAktif = true; });
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Grafikte dokunduğun yere yatay ışın atılacak.")));
          }, cizimModuAktif),
          
          const Spacer(), // Arayı açıyoruz amk
          
          // 🎯 EN SAĞA GERİ AL BUTONU
          if (yatayCizgiler.isNotEmpty)
            _toolbarIcon(Icons.undo_rounded, "Geri Al", () {
              setState(() { yatayCizgiler.removeLast(); });
            }, false),
        ],
      ),
    );
  }

  Widget _toolbarIcon(IconData icon, String tooltip, VoidCallback onTap, bool aktifMi) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: aktifMi ? Colors.greenAccent.withValues(alpha: 0.3) : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: aktifMi ? Colors.greenAccent : Colors.transparent),
          ),
          child: Icon(icon, color: aktifMi ? Colors.greenAccent : Colors.white70, size: 20),
        ),
      ),
    );
  }

  Widget _buildTimeFilters() {
    List<String> zamanlar = ['1G', '1H', '1A', '1Y'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: zamanlar.map((zaman) {
          bool seciliMi = seciliZaman == zaman;
          return GestureDetector(
            onTap: () {
              setState(() { seciliZaman = zaman; });
              _veriyiCekVeGrafikYap(); 
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
              decoration: BoxDecoration(
                color: seciliMi ? Colors.greenAccent.withValues(alpha: 0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: seciliMi ? Colors.greenAccent : const Color(0xFF1E293B)),
              ),
              child: Text(
                zaman,
                style: TextStyle(color: seciliMi ? Colors.greenAccent : Colors.white54, fontWeight: seciliMi ? FontWeight.bold : FontWeight.normal),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- 🎯 GÜNLÜK VERİLER BÖLÜMÜ ---
  Widget _buildIstatistikBolumu() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1420),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Piyasa Özeti", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _istatistikKutusu("Açılış", gunlukAcilis),
                _istatistikKutusu("Kapanış", gunlukKapanis),
                _istatistikKutusu("Hacim", gunlukHacim),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _istatistikKutusu("En Düşük", gunlukEnDusuk, renk: Colors.redAccent),
                _istatistikKutusu("En Yüksek", gunlukEnYuksek, renk: Colors.greenAccent),
                const SizedBox(width: 80), // Hiza bozulmasın diye boşluk
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _istatistikKutusu(String baslik, String deger, {Color renk = Colors.white}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(baslik, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 4),
        Text(deger == "-" ? "-" : "$deger ₺", style: TextStyle(color: renk, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}