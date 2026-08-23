import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trading_bot_app/models/rehber_models.dart';

class ApiService {
  final String url = "https://trading-bot-app-za72.onrender.com";
  // final String url = "http://localhost:8000";
  Future<List<dynamic>> hisseleriGetir() async {
    try {
      final response = await http.get(Uri.parse("$url/endeksler")); 
      
      debugPrint("Server Durum Kodu: ${response.statusCode}");

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        return data['veriler']; 
      } else {
        throw Exception('Sunucu hatası, Kod: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Hisse getirme hatası aga: $e"); 
      throw Exception("Veri çekilemedi");
    }
  }

  Future<Map<String, dynamic>?> aiAnaliziniCek(
    String symbol,
    double rsi,
    double vol,
    double price,
    double change,
  ) async {
    try {
      final response = await http.get(Uri.parse(
        "$url/analiz?symbol=$symbol&rsi=$rsi&vol=$vol&price=$price&change=$change"
      ));

      debugPrint("AI Analiz Durum Kodu: ${response.statusCode}");
      debugPrint("Gelen Yanıt: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> resData = json.decode(response.body);
        
        if (resData['status'] == 'success' && resData['data'] != null) {
          return resData['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      debugPrint("ApiService AI Analiz Hatası: $e");
      return null;
    }
  }

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

  Future<Map<String, dynamic>> getHisseTarihsel(String symbol, String period) async {
      // 🎯 DÜZELTME: Sabit localhost yerine yukarıdaki canlı Render URL'sini kullanıyoruz!
      final endpoint = '$url/hisse-tarihsel/${symbol.toUpperCase()}?period=$period';
      
      try {
        final response = await http.get(Uri.parse(endpoint));
        
        if (response.statusCode == 200) {
          return json.decode(response.body);
        } else {
          print("API Hatası: Kod ${response.statusCode}");
          return {'status': 'error', 'data': []};
        }
      } catch (e) {
        print("Bağlantı patladı: $e");
        return {'status': 'error', 'data': []};
      }
    }
    // 🌟 Favori Ekleme / Silme İşlemleri
  Future<bool> favoriIslemYap(String userId, String symbol, bool isFav) async {
    final endpoint = isFav ? '/favori-sil' : '/favori-ekle';
    final requestUrl = Uri.parse('$url$endpoint');

    try {
      final response = await http.post(
        requestUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": userId, "symbol": symbol}),
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint("Favori işlem hatası: $e");
      return false;
    }
  }
}


