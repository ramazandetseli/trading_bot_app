import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:trading_bot_app/constants/app_constants.dart';
import 'package:trading_bot_app/models/portfolio_item.dart';

class PortfolioService {
  // 1. Portföyü Çek
  static Future<List<PortfolioItem>> fetchPortfolio(String userId) async {
    try {
      final res = await http.get(AppConstants.portfolioGetirUri(userId));
      if (res.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(res.body);
        if (jsonResponse['status'] == 'success') {
          final List list = jsonResponse['data'] ?? [];
          return list.map((e) => PortfolioItem.fromMap(e)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 2. Varlık Ekle
  static Future<bool> addItem({
    required String userId,
    required String symbol,
    required double lotQuantity,
    required double buyPrice,
  }) async {
    try {
      final res = await http.post(
        AppConstants.portfolioEkleUri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'symbol': symbol,
          'lot_quantity': lotQuantity,
          'buy_price': buyPrice,
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 3. Varlık Sil
  static Future<bool> deleteItem({
    required String portfolioId,
    required String userId,
  }) async {
    try {
      final res = await http.post(
        AppConstants.portfolioSilUri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'portfolio_id': portfolioId,
          'user_id': userId,
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}