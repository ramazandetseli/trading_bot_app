class TakvimResponse {
  final String islemDurumu;
  final int toplamOlay;
  final List<EkonomikOlay> yerel;
  final List<EkonomikOlay> global;

  TakvimResponse({
    required this.islemDurumu,
    required this.toplamOlay,
    required this.yerel,
    required this.global,
  });

  factory TakvimResponse.fromJson(Map<String, dynamic> json) {
    return TakvimResponse(
      islemDurumu: json['islem_durumu'] ?? 'hata',
      toplamOlay: json['toplam_olay'] ?? 0,
      yerel: (json['yerel'] as List? ?? [])
          .map((e) => EkonomikOlay.fromJson(e))
          .toList(),
      global: (json['global'] as List? ?? [])
          .map((e) => EkonomikOlay.fromJson(e))
          .toList(),
    );
  }
}

class EkonomikOlay {
  final String id;
  final String title;
  final String countryCode;
  final String countryName;
  final String flag;
  final DateTime date;
  final String period;
  final dynamic actual;
  final dynamic forecast;
  final dynamic previous;
  final String scale;
  final String unit;
  final String importanceLevel;
  final int importanceScore;
  final bool isLocal;

  EkonomikOlay({
    required this.id,
    required this.title,
    required this.countryCode,
    required this.countryName,
    required this.flag,
    required this.date,
    required this.period,
    this.actual,
    this.forecast,
    this.previous,
    required this.scale,
    required this.unit,
    required this.importanceLevel,
    required this.importanceScore,
    required this.isLocal,
  });

  factory EkonomikOlay.fromJson(Map<String, dynamic> json) {
    return EkonomikOlay(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      countryCode: json['country_code'] ?? '',
      countryName: json['country_name'] ?? '',
      flag: json['flag'] ?? '🌐',
      date: DateTime.tryParse(json['date_utc'] ?? '')?.toLocal() ?? DateTime.now(),
      period: json['period'] ?? '',
      actual: json['actual'],
      forecast: json['forecast'],
      previous: json['previous'],
      scale: json['scale'] ?? '',
      unit: json['unit'] ?? '',
      importanceLevel: json['importance_level'] ?? 'ORTA',
      importanceScore: json['importance_score'] ?? 2,
      isLocal: json['is_local'] ?? false,
    );
  }

  String formatDeger(dynamic deger) {
    if (deger == null) return "-";
    return "$deger$scale$unit".trim();
  }
}