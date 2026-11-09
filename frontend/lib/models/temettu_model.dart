import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class TemettuModel {
  final String sembol;
  final String unvan;
  final String tarih;
  final String payBasinaBrut;
  final double payBasinaBrutSayisal;
  final String brutOran;
  final String verim;
  final double verimSayisal;
  final String sonFiyat;

  TemettuModel({
    required this.sembol,
    required this.unvan,
    required this.tarih,
    required this.payBasinaBrut,
    required this.payBasinaBrutSayisal,
    required this.brutOran,
    required this.verim,
    required this.verimSayisal,
    required this.sonFiyat,
  });

  factory TemettuModel.fromJson(Map<String, dynamic> json) {
    return TemettuModel(
      sembol: json['sembol']?.toString() ?? '',
      unvan: json['unvan']?.toString() ?? '',
      tarih: json['tarih']?.toString() ?? '',
      payBasinaBrut: json['pay_basina_brut']?.toString() ?? '',
      payBasinaBrutSayisal: (json['pay_basina_brut_sayisal'] as num?)?.toDouble() ?? 0.0,
      brutOran: json['brut_oran']?.toString() ?? '',
      verim: json['verim']?.toString() ?? '',
      verimSayisal: (json['verim_sayisal'] as num?)?.toDouble() ?? 0.0,
      sonFiyat: json['son_fiyat']?.toString() ?? '',
    );
  }
}

class TemettuService {
  static const String endpoint = 'http://192.168.1.102:8000/api/temettu/takvim';

  static Future<List<TemettuModel>> fetchTemettuTakvimi() async {
    try {
      debugPrint("Temettü isteği başlatılıyor: $endpoint");
      final response = await http
          .get(Uri.parse(endpoint))
          .timeout(const Duration(seconds: 8));

      debugPrint("Temettü Yanıt Kodu: ${response.statusCode}");

      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        final List list = decoded['data'] ?? [];
        debugPrint("Parse edilen kayıt sayısı: ${list.length}");
        return list.map((item) => TemettuModel.fromJson(item)).toList();
      } else {
        throw Exception('Sunucu yanıt vermedi: ${response.statusCode}');
      }
    } catch (e, stack) {
      debugPrint("TEMETTU BAĞLANTI/PARSE HATASI: $e");
      debugPrint("HATA DETAYI: $stack");
      rethrow;
    }
  }
}