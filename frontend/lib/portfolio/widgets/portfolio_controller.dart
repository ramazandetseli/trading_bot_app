import 'package:flutter/material.dart';
import 'package:trading_bot_app/models/portfolio_item.dart';
import 'package:trading_bot_app/services/portfolio_service.dart';

class PortfolioController extends ChangeNotifier {
  final String userId;
  final Map<String, double> anlikFiyatlar;

  bool _isLoading = true;
  List<PortfolioItem> _items = [];

  bool get isLoading => _isLoading;
  List<PortfolioItem> get items => _items;

  PortfolioController({required this.userId, required this.anlikFiyatlar}) {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    final veriler = await PortfolioService.fetchPortfolio(userId);
    for (var item in veriler) {
      if (anlikFiyatlar.containsKey(item.symbol)) {
        item.currentPrice = anlikFiyatlar[item.symbol]!;
      }
    }

    _items = veriler;
    _isLoading = false;
    notifyListeners();
  }

  // --- Finansal Hesaplamalar ---
  double get toplamMaliyet => _items.fold(0.0, (acc, item) => acc + item.totalCost);
  double get toplamGuncelDeger => _items.fold(0.0, (acc, item) => acc + item.currentValue);
  double get toplamNetKarZarar => toplamGuncelDeger - toplamMaliyet;
  double get toplamKarZararYuzde => toplamMaliyet > 0 ? (toplamNetKarZarar / toplamMaliyet) * 100 : 0.0;

  // --- İşlemler ---
  Future<void> addItem(String symbol, double lotQuantity, double buyPrice) async {
    final basarili = await PortfolioService.addItem(
      userId: userId, symbol: symbol, lotQuantity: lotQuantity, buyPrice: buyPrice,
    );
    if (basarili) await loadData();
  }

  Future<void> deleteItem(String itemId) async {
    final silindiMi = await PortfolioService.deleteItem(portfolioId: itemId, userId: userId);
    if (silindiMi) {
      _items.removeWhere((item) => item.id == itemId);
      notifyListeners();
    }
  }
}