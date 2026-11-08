class PortfolioItem {
  final String id;
  final String userId;
  final String symbol;
  final double lotQuantity;
  final double buyPrice;
  final DateTime? createdAt;

  // UI tarafında canlı borsa/fon fiyatıyla beslenecek dinamik alan:
  double currentPrice;

  // Varlık Dolar bazlıysa (Kripto veya NASDAQ) TL toplamına katmak için anlık kur çarpanı:
  double usdTryRate;

  PortfolioItem({
    required this.id,
    required this.userId,
    required this.symbol,
    required this.lotQuantity,
    required this.buyPrice,
    this.createdAt,
    this.currentPrice = 0.0,
    this.usdTryRate = 34.50,
  });

  // Supabase'den okuma
  factory PortfolioItem.fromMap(Map<String, dynamic> map) {
    return PortfolioItem(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      symbol: (map['symbol']?.toString() ?? '').toUpperCase().trim(),
      lotQuantity: (map['lot_quantity'] as num?)?.toDouble() ?? 0.0,
      buyPrice: (map['buy_price'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  // Supabase'e ekleme / güncelleme
  Map<String, dynamic> toMap({required String currentUserId}) {
    return {
      'user_id': currentUserId,
      'symbol': symbol.toUpperCase().trim(),
      'lot_quantity': lotQuantity,
      'buy_price': buyPrice,
    };
  }

  // --- Para Birimi Tespiti (USD mi TRY mi?) ---
  bool get isUsdAsset {
    final sym = symbol.toUpperCase().trim();

    // 1. Kripto Paralar
    const bilinenKriptolar = {
      'BTC', 'ETH', 'SOL', 'AVAX', 'XRP', 'DOGE', 'BNB', 'ADA', 'DOT', 'TRX', 'LINK', 'MATIC', 'NEAR', 'SUI', 'PEPE', 'SHIB'
    };
    if (sym.endsWith('USDT') || bilinenKriptolar.contains(sym)) {
      return true;
    }

    // 2. ABD / NASDAQ Hisseleri
    const usHisseleri = {
      'AAPL', 'NVDA', 'TSLA', 'MSFT', 'AMZN', 'GOOGL', 'GOOG', 'META',
      'SPY', 'QQQ', 'AMD', 'INTC', 'NFLX', 'COIN', 'PLTR', 'BABA', 'BRK.B'
    };
    if (usHisseleri.contains(sym)) {
      return true;
    }

    return false;
  }

  // Kartlarda göstermek için para birimi sembolü ($ veya ₺)
  String get currencySymbol => isUsdAsset ? '\$' : '₺';

  // --- Kendi Para Birimindeki (Orijinal USD veya TRY) Hesaplamalar ---
  double get nativeTotalCost => lotQuantity * buyPrice;

  double get nativeCurrentValue =>
      lotQuantity * (currentPrice > 0 ? currentPrice : buyPrice);

  double get nativeProfitLossAmount => nativeCurrentValue - nativeTotalCost;

  // --- Portföy Genel Toplamı İçin TL'ye Normalize Edilmiş Getters ---
  // (Controller ve mevcut UI widget'ların bu isimleri kullandığı için kur dönüşümü burada otomatik yapılır)

  double get _kurCarpani => isUsdAsset ? usdTryRate : 1.0;

  // Toplam Maliyet Tutarı (TL Karşılığı)
  double get totalCost => nativeTotalCost * _kurCarpani;

  // Anlık Güncel Değer (TL Karşılığı)
  double get currentValue => nativeCurrentValue * _kurCarpani;

  // Kâr / Zarar Tutarı (TL Karşılığı)
  double get profitLossAmount => currentValue - totalCost;

  // Kâr / Zarar Yüzdesi (%) -> Yüzde hesabı kurdan bağımsızdır
  double get profitLossPercentage {
    if (buyPrice <= 0) return 0.0;
    final priceToCompare = currentPrice > 0 ? currentPrice : buyPrice;
    return ((priceToCompare - buyPrice) / buyPrice) * 100;
  }

  bool get isProfitable => profitLossAmount >= 0;
}