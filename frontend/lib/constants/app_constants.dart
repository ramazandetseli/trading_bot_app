class AppConstants {
  // Canlıya alırken bunu 'false' yapman yeterli
  static const bool isDevelopment = true;

  // Local IP (FastAPI)
  static const String _localUrl = "http://10.145.217.107:8000";

  // Production URL (Render)
  static const String _prodUrl = "https://trading-bot-app-za72.onrender.com";

  // Ana Sunucu Adresi
  static String get baseUrl => isDevelopment ? _localUrl : _prodUrl;

  // --- TARAMA & PİYASA ---
  static Uri get taraUri => Uri.parse("$baseUrl/tara");
  static Uri taraModUri(String mode) => Uri.parse("$baseUrl/tara/$mode");
  static Uri get endekslerUri => Uri.parse("$baseUrl/endeksler");

  // --- HİSSE DETAY & ANALİZ ---
  static Uri hisseTarihselUri(String symbol, String period) =>
      Uri.parse("$baseUrl/hisse-tarihsel/${symbol.toUpperCase()}?period=$period");

  static Uri hisseAnalizUri({
    required String symbol,
    required dynamic rsi,
    required dynamic vol,
    required dynamic price,
    required dynamic change,
  }) =>
      Uri.parse(
        "$baseUrl/analiz?symbol=$symbol&rsi=$rsi&vol=$vol&price=$price&change=$change",
      );

  // --- FAVORİLER ---
  static Uri get favoriEkleUri => Uri.parse("$baseUrl/favori-ekle");
  static Uri get favoriSilUri => Uri.parse("$baseUrl/favori-sil");
  static Uri favorilerUri(String userId) =>
      Uri.parse("$baseUrl/favoriler/$userId");

  // --- ALARMLAR ---
  static Uri get alarmKurUri => Uri.parse("$baseUrl/alarm-kur");
  static Uri get alarmSilUri => Uri.parse("$baseUrl/alarm-sil");
  static Uri get alarmDuzenleUri => Uri.parse("$baseUrl/alarm-duzenle");
  static Uri alarmlarUri(String userId) =>
      Uri.parse("$baseUrl/alarmlar/$userId");

  // --- TEFAS FONLARI ---
  static Uri tumFonlarUri([String? fonTip]) =>
      Uri.parse("$baseUrl/tum-fonlar${fonTip != null ? '?fon_tip=$fonTip' : ''}");

  static Uri fonDetayUri(String fonKodu, String aralik) =>
      Uri.parse("$baseUrl/detay/${fonKodu.toUpperCase()}?aralik=$aralik");

  static Uri fonKiyaslamaUri(String fonKodu, String periyod) =>
      Uri.parse("$baseUrl/kiyaslama/${fonKodu.toUpperCase()}?periyod=$periyod");

  static Uri fonTipUri(String fonKodu) =>
      Uri.parse("$baseUrl/tip/${fonKodu.toUpperCase()}");

  static Uri get oneCikanFonlarUri => 
  Uri.parse("$baseUrl/one-cikanlar");
}