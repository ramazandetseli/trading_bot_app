class PortfolioItem {
  final String id;
  final String userId;
  final String symbol;
  final double lotQuantity;
  final double buyPrice;
  final DateTime? createdAt;
  
  // UI tarafında canlı borsa/fon fiyatıyla beslenecek dinamik alan:
  double currentPrice;

  PortfolioItem({
    required this.id,
    required this.userId,
    required this.symbol,
    required this.lotQuantity,
    required this.buyPrice,
    this.createdAt,
    this.currentPrice = 0.0,
  });

  // Supabase'den okuma
  factory PortfolioItem.fromMap(Map<String, dynamic> map) {
    return PortfolioItem(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      symbol: (map['symbol']?.toString() ?? '').toUpperCase(),
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
      'symbol': symbol.toUpperCase(),
      'lot_quantity': lotQuantity,
      'buy_price': buyPrice,
    };
  }

  // --- Finansal Hesaplama Getters ---
  
  // Toplam Maliyet Tutarı
  double get totalCost => lotQuantity * buyPrice;

  // Anlık Güncel Değer (Canlı fiyat girilmişse)
  double get currentValue => lotQuantity * (currentPrice > 0 ? currentPrice : buyPrice);

  // Kâr / Zarar Tutarı (₺)
  double get profitLossAmount => currentValue - totalCost;

  // Kâr / Zarar Yüzdesi (%)
  double get profitLossPercentage {
    if (buyPrice <= 0) return 0.0;
    final priceToCompare = currentPrice > 0 ? currentPrice : buyPrice;
    return ((priceToCompare - buyPrice) / buyPrice) * 100;
  }

  bool get isProfitable => profitLossAmount >= 0;
}