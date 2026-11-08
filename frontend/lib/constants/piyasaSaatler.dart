class PiyasaSaatleri {
  // Türkiye resmi tatilleri (Ay-Gün formatında)
  static const List<String> _trResmiTatiller = [
    "01-01", // Yılbaşı
    "04-23", // 23 Nisan
    "05-01", // 1 Mayıs
    "05-19", // 19 Mayıs
    "07-15", // 15 Temmuz
    "08-30", // 30 Ağustos
    "10-29", // 29 Ekim Cumhuriyet Bayramı
  ];

  static String _bugunFormatli(DateTime dt) =>
      "${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";

  /// Borsa İstanbul (Hisseler ve BIST Endeksleri) açık mı?
  static bool isBistAcik() {
    final now = DateTime.now();
    // Cumartesi (6) ve Pazar (7) kapalı
    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      return false;
    }
    // Resmi tatillerde kapalı
    if (_trResmiTatiller.contains(_bugunFormatli(now))) {
      return false;
    }
    // Saat 09:55 ile 18:10 arası açık
    final dakikaBazliSaat = now.hour * 60 + now.minute;
    return dakikaBazliSaat >= (9 * 60 + 55) && dakikaBazliSaat <= (18 * 60 + 10);
  }

  /// ABD Borsaları (NASDAQ / NYSE - Yabancı Piyasa) açık mı?
  static bool isAbdBorsaAcik() {
    final now = DateTime.now();
    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      return false;
    }
    // TSİ 16:30 ile 23:59 arası açık (Yaz/Kış saati genel kapsama)
    final dakikaBazliSaat = now.hour * 60 + now.minute;
    return dakikaBazliSaat >= (16 * 60 + 30) && dakikaBazliSaat <= (23 * 60 + 59);
  }

  /// Küresel Döviz ve Altın (Forex) piyasası açık mı?
  static bool isForexAltinAcik() {
    final now = DateTime.now();
    // Cumartesi ve Pazar kapalı, hafta içi 24 saat açık
    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      return false;
    }
    return true;
  }

  /// Kripto piyasası her zaman açıktır (7/24)
  static bool isKriptoAcik() => true;

  /// TEFAS Fonları anlık tick almaz, günde 1 kez fiyatlanır
  static bool isFonCanli() => false;
}