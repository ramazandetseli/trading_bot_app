import 'dart:math';
import 'package:flutter/material.dart';

class BorsaSeansi {
  final String id;
  final String ad;
  final String ulke;
  final String bayrak;
  final double baslangicSaat; // TSİ 24 saat formatında (Örn: 9.91 = 09:55)
  final double bitisSaat;      // TSİ 24 saat formatında (Örn: 18.16 = 18:10)
  final Color renk;
  final bool is724;

  const BorsaSeansi({
    required this.id,
    required this.ad,
    required this.ulke,
    required this.bayrak,
    required this.baslangicSaat,
    required this.bitisSaat,
    required this.renk,
    this.is724 = false,
  });

  bool isOpenAt(double saat24) {
    if (is724) return true;
    if (bitisSaat > baslangicSaat) {
      return saat24 >= baslangicSaat && saat24 < bitisSaat;
    } else {
      return saat24 >= baslangicSaat || saat24 < bitisSaat;
    }
  }

  String formatSaat(double saat) {
    if (is724) return "7/24 Kesintisiz";
    final int h = saat.floor();
    final int m = ((saat - h) * 60).round();
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}";
  }
}

class PiyasaSaatleriScreen extends StatefulWidget {
  const PiyasaSaatleriScreen({super.key});

  @override
  State<PiyasaSaatleriScreen> createState() => _PiyasaSaatleriScreenState();
}

class _PiyasaSaatleriScreenState extends State<PiyasaSaatleriScreen> {
  final List<BorsaSeansi> seanslar = const [
    BorsaSeansi(
      id: 'bist',
      ad: 'Borsa İstanbul (BIST)',
      ulke: 'Türkiye',
      bayrak: '🇹🇷',
      baslangicSaat: 9.916, // 09:55
      bitisSaat: 18.166,    // 18:10
      renk: Color(0xFF00E676),
    ),
    BorsaSeansi(
      id: 'nyse',
      ad: 'New York (NYSE / NASDAQ)',
      ulke: 'ABD',
      bayrak: '🇺🇸',
      baslangicSaat: 16.5,  // 16:30
      bitisSaat: 23.0,     // 23:00
      renk: Color(0xFFFF9100),
    ),
    BorsaSeansi(
      id: 'lse',
      ad: 'Londra (LSE)',
      ulke: 'Birleşik Krallık',
      bayrak: '🇬🇧',
      baslangicSaat: 10.0,  // 10:00
      bitisSaat: 18.5,     // 18:30
      renk: Color(0xFF2979FF),
    ),
    BorsaSeansi(
      id: 'tse',
      ad: 'Tokyo (TSE)',
      ulke: 'Japonya',
      bayrak: '🇯🇵',
      baslangicSaat: 3.0,   // 03:00
      bitisSaat: 9.0,      // 09:00
      renk: Color(0xFFD500F9),
    ),
    BorsaSeansi(
      id: 'kripto',
      ad: 'Kripto Para (Global)',
      ulke: 'Global 7/24',
      bayrak: '🌐',
      baslangicSaat: 0.0,
      bitisSaat: 24.0,
      renk: Color(0xFF00E5FF),
      is724: true,
    ),
  ];

  late double _kadranSaati; // 0.0 - 12.0 arası kadran pozisyonu
  late bool _isPm;          // false = AM (00:00 - 11:59), true = PM (12:00 - 23:59)
  bool _canliMod = true;

  @override
  void initState() {
    super.initState();
    _suankiSaateEsitle();
  }

  void _suankiSaateEsitle() {
    final now = DateTime.now();
    final double tamSaat = now.hour + (now.minute / 60.0);
    setState(() {
      _isPm = now.hour >= 12;
      _kadranSaati = tamSaat >= 12 ? tamSaat - 12 : tamSaat;
      _canliMod = true;
    });
  }

  // 12 saatlik kadran açısını hesaplama
  void _dokunmaIsle(Offset localPos, Size widgetSize) {
    final center = Offset(widgetSize.width / 2, widgetSize.height / 2);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;

    // Tepede 12 (0 radyan), sağda 3 (pi/2), altta 6 (pi), solda 9 (3pi/2)
    double angle = atan2(dy, dx) + (pi / 2);
    if (angle < 0) angle += 2 * pi;

    double saat12 = (angle / (2 * pi)) * 12.0;
    // 5 dakikalık kademelere yapışması için yuvarlama
    saat12 = (saat12 * 12).round() / 12.0;
    if (saat12 >= 12.0) saat12 = 0.0;

    setState(() {
      _kadranSaati = saat12;
      _canliMod = false;
    });
  }

  // 24 saatlik gerçek TSİ saati
  double get _aktifSaat24 => _isPm ? _kadranSaati + 12.0 : _kadranSaati;

  String _format24Saat(double saat24) {
    int h = saat24.floor();
    if (h >= 24) h = 0;
    final int m = ((saat24 - saat24.floor()) * 60).round();
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final double suankiSaat24 = _aktifSaat24;
    final acikBorsalar = seanslar.where((s) => s.isOpenAt(suankiSaat24)).toList();
    final kapaliBorsalar = seanslar.where((s) => !s.isOpenAt(suankiSaat24)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F141C),
      appBar: AppBar(
        title: const Text(
          "Piyasa Seans Radar",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF151C28),
        elevation: 0,
        actions: [
          if (!_canliMod)
            TextButton.icon(
              onPressed: _suankiSaateEsitle,
              icon: const Icon(Icons.my_location, size: 16, color: Color(0xFF00E676)),
              label: const Text("Şimdi", style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Üst Bilgi Kartı & AM/PM Butonları
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2837),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _canliMod ? "CANLI TÜRKİYE SAATİ" : "KONTROL EDİLEN SAAT",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _canliMod ? const Color(0xFF00E676) : Colors.amberAccent,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${_format24Saat(suankiSaat24)} TSİ",
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ],
                  ),
                  // AM / PM Toggle Buton Grubu
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF151C28),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      children: [
                        _amPmButon("AM", !_isPm, () {
                          setState(() {
                            _isPm = false;
                            _canliMod = false;
                          });
                        }),
                        _amPmButon("PM", _isPm, () {
                          setState(() {
                            _isPm = true;
                            _canliMod = false;
                          });
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 12 Saatlik Klasik Kadran (Üstte 12, Altta 6)
            Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = min(constraints.maxWidth - 40, 320.0);
                  return GestureDetector(
                    onPanDown: (d) => _dokunmaIsle(d.localPosition, Size(size, size)),
                    onPanUpdate: (d) => _dokunmaIsle(d.localPosition, Size(size, size)),
                    child: Container(
                      width: size,
                      height: size,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF151C28),
                        boxShadow: [
                          BoxShadow(color: Colors.black54, blurRadius: 18, offset: Offset(0, 4)),
                        ],
                      ),
                      child: CustomPaint(
                        size: Size(size, size),
                        painter: KlasikSaatPainter(
                          seanslar: seanslar,
                          kadranSaati: _kadranSaati,
                          isPm: _isPm,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Üstte 12 • Altta 6 | Şu an ${_isPm ? 'Öğleden Sonra / Gece (PM)' : 'Gece / Sabah (AM)'} Modundasınız",
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(height: 20),

            // Dinamik Liste Başlığı
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${_format24Saat(suankiSaat24)} Piyasa Seansları",
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "${acikBorsalar.length} Açık",
                    style: TextStyle(
                      color: acikBorsalar.isNotEmpty ? const Color(0xFF00E676) : Colors.white38,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Açık Seanslar
            if (acikBorsalar.isNotEmpty)
              ...acikBorsalar.map((s) => _seansKarti(s, true)),

            // Kapalı Seanslar
            if (kapaliBorsalar.isNotEmpty)
              ...kapaliBorsalar.map((s) => _seansKarti(s, false)),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _amPmButon(String label, bool aktif, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: aktif ? const Color(0xFF2979FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: aktif ? Colors.white : Colors.white54,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _seansKarti(BorsaSeansi s, bool acik) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF182230),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: acik ? s.renk.withOpacity(0.5) : Colors.white10,
          width: acik ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Text(s.bayrak, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.ad,
                  style: TextStyle(
                    color: acik ? Colors.white : Colors.white54,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  s.is724 ? "7/24 Kesintisiz" : "${s.formatSaat(s.baslangicSaat)} - ${s.formatSaat(s.bitisSaat)} TSİ",
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: acik ? s.renk.withOpacity(0.18) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: acik ? s.renk : Colors.grey,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  acik ? "AÇIK" : "KAPALI",
                  style: TextStyle(
                    color: acik ? s.renk : Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- 12 Saatlik Klasik Kadran Çizici (Tepede 12, Altta 6) ---
class KlasikSaatPainter extends CustomPainter {
  final List<BorsaSeansi> seanslar;
  final double kadranSaati; // 0.0 - 12.0
  final bool isPm;

  KlasikSaatPainter({
    required this.seanslar,
    required this.kadranSaati,
    required this.isPm,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 24;

    // 1. Dış Çember
    final bgLinePaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, outerRadius, bgLinePaint);

    // 2. Klasik Saat Rakamları (12 tepede, 3 sağda, 6 altta, 9 solda)
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final List<Map<String, dynamic>> marks = [
      {"label": "12", "hour": 0},
      {"label": "1",  "hour": 1},
      {"label": "2",  "hour": 2},
      {"label": "3",  "hour": 3},
      {"label": "4",  "hour": 4},
      {"label": "5",  "hour": 5},
      {"label": "6",  "hour": 6},
      {"label": "7",  "hour": 7},
      {"label": "8",  "hour": 8},
      {"label": "9",  "hour": 9},
      {"label": "10", "hour": 10},
      {"label": "11", "hour": 11},
    ];

    for (var m in marks) {
      final int h = m["hour"] as int;
      // 0 saat = -pi/2 (tepe), 3 saat = 0 (sağ), 6 saat = pi/2 (alt), 9 saat = pi (sol)
      final double a = (h / 12.0) * 2 * pi - (pi / 2);
      final bool isMain = (h % 3 == 0);

      final pos = Offset(
        center.dx + (outerRadius + 14) * cos(a),
        center.dy + (outerRadius + 14) * sin(a),
      );

      textPainter.text = TextSpan(
        text: m["label"] as String,
        style: TextStyle(
          color: isMain ? Colors.white : Colors.white38,
          fontSize: isMain ? 12 : 9,
          fontWeight: isMain ? FontWeight.w900 : FontWeight.normal,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
      );
    }

    // 3. Seans Şeritlerini (Arc) Çiz
    // 12 saatlik kadranda aktif AM/PM dilimine denk gelen kısımlar çizilir
    final double aktifOffset = isPm ? 12.0 : 0.0;
    final double aktifPencereBas = aktifOffset;
    final double aktifPencereBit = aktifOffset + 12.0;

    double trackRadius = outerRadius - 10;
    const double trackStep = 10.0;

    for (int i = 0; i < seanslar.length; i++) {
      final s = seanslar[i];
      final currentR = trackRadius - (i * trackStep);

      // Boş arkaplan rayı
      canvas.drawCircle(
        center,
        currentR,
        Paint()
          ..color = Colors.white.withValues(alpha: .04)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6,
      );

      final double suankiSaat24 = isPm ? kadranSaati + 12.0 : kadranSaati;
      final bool isOpen = s.isOpenAt(suankiSaat24);
      final arcPaint = Paint()
        ..color = isOpen ? s.renk : s.renk.withValues(alpha: .25)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = isOpen ? 7.5 : 5.5;

      if (s.is724) {
        // Kripto her zaman tam çember
        canvas.drawCircle(center, currentR, arcPaint);
      } else {
        // Seansın bu 12 saatlik pencereyle kesişimini al
        final double bas = max(s.baslangicSaat, aktifPencereBas);
        final double bit = min(s.bitisSaat, aktifPencereBit);

        if (bit > bas) {
          final double kadranBas = bas - aktifOffset;
          final double kadranBit = bit - aktifOffset;

          final double startAngle = (kadranBas / 12.0) * 2 * pi - (pi / 2);
          final double sweepAngle = ((kadranBit - kadranBas) / 12.0) * 2 * pi;

          canvas.drawArc(
            Rect.fromCircle(center: center, radius: currentR),
            startAngle,
            sweepAngle,
            false,
            arcPaint,
          );
        }
      }
    }

    // 4. Saat İbresi (Klasik 12 Saat Kolu)
    final double handAngle = (kadranSaati / 12.0) * 2 * pi - (pi / 2);
    final handPaint = Paint()
      ..color = Colors.amberAccent
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final handEnd = Offset(
      center.dx + (outerRadius - 4) * cos(handAngle),
      center.dy + (outerRadius - 4) * sin(handAngle),
    );
    canvas.drawLine(center, handEnd, handPaint);

    // Göbek noktası
    canvas.drawCircle(center, 6, Paint()..color = Colors.amberAccent);
    canvas.drawCircle(center, 2.5, Paint()..color = const Color(0xFF0F141C));
  }

  @override
  bool shouldRepaint(covariant KlasikSaatPainter oldDelegate) =>
      oldDelegate.kadranSaati != kadranSaati || oldDelegate.isPm != isPm;
}