class Hissemodel {
  final String symbol;
  final double price;
  final double change;
  final String signal;
  final String relVol;

  Hissemodel({
    required this.symbol,
    required this.price,
    required this.change,
    required this.signal,
    required this.relVol,
  });

  factory Hissemodel.fromMap(Map<String, dynamic> map) {
    return Hissemodel(
      // Gelen veriyi her ihtimale karşı .toString() ile metne çeviriyoruz
      symbol: map['symbol']?.toString() ?? "",
      
      // Sayısal değerleri zaten tryParse ile güvene almıştık
      price: double.tryParse(map['price'].toString()) ?? 0.0,
      change: double.tryParse(map['change'].toString()) ?? 0.0,
      
      // Sinyal boş gelebilir veya yanlışlıkla sayı gelebilir
      signal: map['signal']?.toString() ?? "",
      
      // İŞTE HATAYI ÇÖZEN SATIR: 0.71 gelse bile artık "0.71" metni olacak
      relVol: map['rel_vol']?.toString() ?? "0.0", 
    );
  }
}