class PiyasaVarlikModel {
  final String sembol;
  final String baslik;
  final String fiyat;
  final String degisim;
  final double rawDegisim;
  final bool isPositive;

  PiyasaVarlikModel({
    required this.sembol,
    required this.baslik,
    required this.fiyat,
    required this.degisim,
    required this.rawDegisim,
    required this.isPositive,
  });

  factory PiyasaVarlikModel.fromJson(Map<String, dynamic> json) {
    return PiyasaVarlikModel(
      sembol: json['symbol'] ?? json['kod'] ?? '',
      baslik: json['name'] ?? json['symbol'] ?? '',
      fiyat: json['price']?.toString() ?? '',
      degisim: json['change']?.toString() ?? '',
      rawDegisim: (json['raw_change'] as num?)?.toDouble() ?? 0.0,
      isPositive: json['is_positive'] ?? ((json['raw_change'] as num?)?.toDouble() ?? 0.0) >= 0,
    );
  }
}