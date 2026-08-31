class HisseTarihselNokta {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;

  HisseTarihselNokta({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory HisseTarihselNokta.fromJson(Map<String, dynamic> json) {
    return HisseTarihselNokta(
      date: DateTime.fromMillisecondsSinceEpoch((json['time'] as int) * 1000),
      open: (json['open'] as num?)?.toDouble() ?? 0.0,
      high: (json['high'] as num?)?.toDouble() ?? 0.0,
      low: (json['low'] as num?)?.toDouble() ?? 0.0,
      close: (json['close'] as num?)?.toDouble() ?? 0.0,
      volume: (json['volume'] as num?)?.toInt() ?? 0,
    );
  }
}