import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:trading_bot_app/constants/app_constants.dart';
import '../models/fon_model.dart';

class FonService {
  final http.Client _client = http.Client();

  // 1. Tüm Fonları Getir
  Future<List<FonOzetModel>> getTumFonlar({String? fonTip}) async {
    final uri = AppConstants.tumFonlarUri(fonTip);
    
    final response = await _client.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data['islem_durumu'] == 'basarili') {
        final List list = data['fonlar'] ?? [];
        return list.map((item) => FonOzetModel.fromJson(item)).toList();
      }
      throw Exception(data['mesaj'] ?? 'Fon listesi alınamadı');
    }
    throw Exception('Sunucu hatası: ${response.statusCode}');
  }

  // 2. Fon Detay ve Grafik Verilerini Getir
  Future<FonDetayModel> getFonDetay(String fonKodu, {String aralik = '3ay'}) async {
    final uri = AppConstants.fonDetayUri(fonKodu, aralik);
    
    final response = await _client.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data['islem_durumu'] == 'basarili') {
        return FonDetayModel.fromJson(data);
      }
      throw Exception(data['mesaj'] ?? 'Fon detay bilgisi bulunamadı');
    }
    throw Exception('Sunucu hatası: ${response.statusCode}');
  }

  // 3. Benchmark Kıyaslama Verilerini Getir
  Future<FonKiyaslamaModel> getFonKiyaslama(String fonKodu, {String periyod = '12'}) async {
    final uri = AppConstants.fonKiyaslamaUri(fonKodu, periyod);
    
    final response = await _client.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data['islem_durumu'] == 'basarili') {
        return FonKiyaslamaModel.fromJson(data);
      }
      throw Exception(data['mesaj'] ?? 'Kıyaslama verisi alınamadı');
    }
    throw Exception('Sunucu hatası: ${response.statusCode}');
  }

  // 4. Fon Tipini Getir
  Future<String> getFonTipi(String fonKodu) async {
    final uri = AppConstants.fonTipUri(fonKodu);
    
    final response = await _client.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data['islem_durumu'] == 'basarili') {
        return data['fon_tipi_aciklama'] ?? 'Yatırım Fonu';
      }
    }
    return 'Yatırım Fonu';
  }

  


  Future<Map<String, List<FonOzetModel>>> getOneCikanFonlar() async {
    try {
      final response = await _client
          .get(AppConstants.oneCikanFonlarUri)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['islem_durumu'] == 'basarili') {
          final yukselenler = (data['haftanin_yukselenleri'] as List? ?? [])
              .map((e) => FonOzetModel.fromJson(e))
              .toList();
          final populer = (data['populer_fonlar'] as List? ?? [])
              .map((e) => FonOzetModel.fromJson(e))
              .toList();

          return {
            'yukselenler': yukselenler,
            'populer': populer,
          };
        }
      }
    } catch (e) {
      debugPrint("Öne çıkan fonlar çekilemedi: $e");
    }
    return {'yukselenler': [], 'populer': []};
  }
}