class AppConstants {
  // Canlıya alırken bunu 'false' yapman yeterli
  static const bool isDevelopment = false;

  // Local IP (FastAPI)
  static const String _localUrl = "http://192.168.1.114:8000";

  // Production URL (Render)
  static const String _prodUrl = "https://trading-bot-app-za72.onrender.com";

  // Ana Sunucu Adresi
  static String get baseUrl => isDevelopment ? _localUrl : _prodUrl;

  // --- TARAMA & PİYASA (/api/hisse) ---
  static Uri get taraUri => Uri.parse("$baseUrl/api/hisse/tara");
  static Uri taraModUri(String mode) => Uri.parse("$baseUrl/api/hisse/tara/$mode");
  static Uri get endekslerUri => Uri.parse("$baseUrl/api/hisse/endeksler");

  // --- HİSSE DETAY & GEÇMİŞ VERİ (/api/hisse) ---
  static Uri hisseTarihselUri(String symbol, String period) =>
      Uri.parse("$baseUrl/api/hisse/tarihsel/${symbol.toUpperCase()}?period=$period");
  static Uri get hisseIstatistikUri => Uri.parse("$baseUrl/api/hisse/gunluk-istatistikler");

  // --- YAPAY ZEKA ANALİZ (/api/ai) ---
  static Uri hisseAnalizUri({
    required String symbol,
    required dynamic rsi,
    required dynamic vol,
    required dynamic price,
    required dynamic change,
  }) =>
      Uri.parse(
        "$baseUrl/api/ai/deep-analiz?symbol=$symbol&rsi=$rsi&vol=$vol&price=$price&change=$change",
      );

  // --- FAVORİLER (/api/kullanici) ---
  static Uri get favoriEkleUri => Uri.parse("$baseUrl/api/kullanici/favori-ekle");
  static Uri get favoriSilUri => Uri.parse("$baseUrl/api/kullanici/favori-sil");
  static Uri favorilerUri(String userId) =>
      Uri.parse("$baseUrl/api/kullanici/favoriler/$userId");

  // --- ALARMLAR (/api/kullanici) ---
  static Uri get alarmKurUri => Uri.parse("$baseUrl/api/kullanici/alarm-kur");
  static Uri get alarmSilUri => Uri.parse("$baseUrl/api/kullanici/alarm-sil");
  static Uri get alarmDuzenleUri => Uri.parse("$baseUrl/api/kullanici/alarm-duzenle");
  static Uri alarmlarUri(String userId) =>
      Uri.parse("$baseUrl/api/kullanici/alarmlar/$userId");

  // --- TEFAS & FVT FONLARI (/api/fon) ---
  static Uri tumFonlarUri([String? fonTip]) =>
      Uri.parse("$baseUrl/api/fon/tum-fonlar${fonTip != null ? '?fon_tip=$fonTip' : ''}");

  static Uri fonDetayUri(String fonKodu, String aralik) =>
      Uri.parse("$baseUrl/api/fon/detay/${fonKodu.toUpperCase()}?aralik=$aralik");

  static Uri fonKiyaslamaUri(String fonKodu, String periyod) =>
      Uri.parse("$baseUrl/api/fon/kiyaslama/${fonKodu.toUpperCase()}?periyod=$periyod");

  static Uri fonTipUri(String fonKodu) =>
      Uri.parse("$baseUrl/api/fon/tip/${fonKodu.toUpperCase()}");

  static Uri get oneCikanFonlarUri => 
      Uri.parse("$baseUrl/api/fon/one-cikanlar");

  // FVT üzerinden fonun hisse dağılımını çeken rota
  static Uri fonPortfoyUri(String fonKodu) =>
      Uri.parse("$baseUrl/api/fon/portfoy/${fonKodu.toUpperCase()}");
      
  static Uri fonTahminUri(String fonKodu) =>
      Uri.parse("$baseUrl/api/fon/tahmin/${fonKodu.toUpperCase()}");

  static Uri get fonVitrinUri => Uri.parse("$baseUrl/api/fon/vitrin");

  // --- PORTFÖY (/api/kullanici) ---
  static Uri get portfolioEkleUri => Uri.parse("$baseUrl/api/kullanici/portfolio-ekle");
  static Uri get portfolioSilUri => Uri.parse("$baseUrl/api/kullanici/portfolio-sil");
  static Uri portfolioGetirUri(String userId) =>
      Uri.parse("$baseUrl/api/kullanici/portfolio/$userId");

  // --- PİYASA TABELA & 
  static Uri get piyasaGet => Uri.parse('$baseUrl/api/piyasa/endeksler');
  static Uri get kriptoGet => Uri.parse('$baseUrl/api/piyasa/kriptolar');
  static Uri get fonEnleriGet => Uri.parse('$baseUrl/api/piyasa/fon-enleri');
  static Uri get yabanciPiyasaGet => Uri.parse('$baseUrl/api/piyasa/yabanci-piyasa');
  static Uri get altinGet => Uri.parse('$baseUrl/api/piyasa/altinlar');
}