import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trading_bot_app/constants/app_constants.dart';
import 'package:trading_bot_app/models/rehber_models.dart';

class ApiService {
  // 📈 Endeksleri Getir
  Future<List<dynamic>> hisseleriGetir() async {
    try {
      final response = await http.get(AppConstants.endekslerUri); 
      
      debugPrint("Server Durum Kodu: ${response.statusCode}");

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        return data['veriler'] ?? []; 
      } else {
        throw Exception('Sunucu hatası, Kod: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Hisse getirme hatası: $e"); 
      throw Exception("Veri çekilemedi");
    }
  }

  // 🤖 AI Analizi
  Future<Map<String, dynamic>?> aiAnaliziniCek(
    String symbol, double rsi, double relVol, double price, double change, bool isGelismisMod, String period) async {
  try {
    Uri uri;
    if (isGelismisMod) {
      // 👑 Seçilen periyodu URL'ye ekliyoruz
      uri = Uri.parse("${AppConstants.baseUrl}/ai/deep-analiz?symbol=$symbol&rsi=$rsi&vol=$relVol&price=$price&change=$change&period=$period");
    } else {
      uri = Uri.parse("${AppConstants.baseUrl}/ai/basic-analiz?symbol=$symbol&price=$price&rsi=$rsi");
    }

    final response = await http.get(uri).timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
  } catch (e) {
    debugPrint("AI Analiz Hatası: $e");
  }
  return null;
}

  // 📚 Rehber Bilgileri (Supabase)
  Future<List<RehberModels>> rehberleriGetir(String kategoriAdi) async {
    try {
      final response = await Supabase.instance.client
          .from('rehber')
          .select()
          .ilike('kategori', kategoriAdi); 

      final List<dynamic> data = response;
      return data.map((item) => RehberModels.fromMap(item)).toList();
    } catch (e) {
      debugPrint("Supabase Rehber Hatası: $e");
      return [];
    }
  }

  // 📊 Hisse Tarihsel Veri
  Future<Map<String, dynamic>> getHisseTarihsel(String symbol, String period) async {
    try {
      final response = await http.get(AppConstants.hisseTarihselUri(symbol, period));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint("API Hatası: Kod ${response.statusCode}");
        return {'status': 'error', 'data': []};
      }
    } catch (e) {
      debugPrint("Bağlantı hatası: $e");
      return {'status': 'error', 'data': []};
    }
  }

  // 🌟 Favori Ekleme / Silme
  Future<bool> favoriIslemYap(String userId, String symbol, bool isFav) async {
    final requestUri = isFav ? AppConstants.favoriSilUri : AppConstants.favoriEkleUri;

    try {
      final response = await http.post(
        requestUri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": userId, "symbol": symbol}),
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint("Favori işlem hatası: $e");
      return false;
    }
  }

  // ⏰ Alarm Ekleme
  Future<bool> alarmEkleApi(String userId, String symbol, double targetPrice, double currentPrice) async {
    try {
      final response = await http.post(
        AppConstants.alarmKurUri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "symbol": symbol,
          "target_price": targetPrice,
          "current_price": currentPrice,
        }),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint("Alarm ekleme hatası: $e");
      return false;
    }
  }

  // ⏰ Alarmları Listeleme
  Future<List<dynamic>> alarmlariGetirApi(String userId) async {
    try {
      final response = await http.get(AppConstants.alarmlarUri(userId));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['alarmlar'] ?? [];
      }
      return [];
    } catch (e) {
      debugPrint("Alarm getirme hatası: $e");
      return [];
    }
  }

  // ⏰ Alarm Silme
  Future<bool> alarmSilApi(String userId, String symbol) async {
    try {
      final response = await http.post(
        AppConstants.alarmSilUri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": userId, "symbol": symbol}),
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint("Alarm silme hatası: $e");
      return false;
    }
  }



  
}