import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:trading_bot_app/constants/app_constants.dart';
import 'package:trading_bot_app/models/portfolio_item.dart';
import 'package:trading_bot_app/services/portfolio_service.dart';

class PortfolioController extends ChangeNotifier {
  final String userId;
  final Map<String, double> anlikFiyatlar;

  bool _isLoading = true;
  List<PortfolioItem> _items = [];
  Map<String, double> _guncelFiyatHavuzu = {};
  double _usdTryKuru = 49; // Başlangıç yedeği, açılışta canlı güncellenir

  bool get isLoading => _isLoading;
  List<PortfolioItem> get items => _items;
  Map<String, double> get guncelFiyatHavuzu => _guncelFiyatHavuzu;
  double get usdTryKuru => _usdTryKuru;

  PortfolioController({required this.userId, required this.anlikFiyatlar}) {
    _guncelFiyatHavuzu = Map<String, double>.from(anlikFiyatlar);
    loadData();
  }

  static double _parseFiyat(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    String s = val.toString().replaceAll(RegExp(r'[^0-9.,-]'), '');
    if (s.contains(',') && s.contains('.')) {
      if (s.lastIndexOf(',') > s.lastIndexOf('.')) {
        s = s.replaceAll('.', '').replaceAll(',', '.');
      } else {
        s = s.replaceAll(',', '');
      }
    } else if (s.contains(',')) {
      s = s.replaceAll(',', '.');
    }
    return double.tryParse(s) ?? 0.0;
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Portföyü, Piyasa Fiyatlarını ve Dolar Kurunu aynı anda paralel çek!
      final sonuclar = await Future.wait([
        PortfolioService.fetchPortfolio(userId),
        _canliFiyatlariBackenddenCek(),
        _canliDolarKurunuCek(),
      ]);

      final veriler = sonuclar[0] as List<PortfolioItem>;
      final apiFiyatlar = sonuclar[1] as Map<String, double>;

      _guncelFiyatHavuzu.addAll(apiFiyatlar);

      // 2. Her varlığa kendi canlı fiyatını ve güncel Dolar kurunu bağla
      for (var item in veriler) {
        final sym = item.symbol.toUpperCase().trim();
        item.usdTryRate = _usdTryKuru; // 👈 Dolar kurunu modele enjekte ettik!

        if (_guncelFiyatHavuzu.containsKey(sym) && _guncelFiyatHavuzu[sym]! > 0) {
          item.currentPrice = _guncelFiyatHavuzu[sym]!;
        } else if (_guncelFiyatHavuzu.containsKey('${sym}USDT')) {
          item.currentPrice = _guncelFiyatHavuzu['${sym}USDT']!;
        } else if (sym.endsWith('USDT')) {
          final kisa = sym.replaceAll('USDT', '');
          if (_guncelFiyatHavuzu.containsKey(kisa)) {
            item.currentPrice = _guncelFiyatHavuzu[kisa]!;
          }
        }
      }

      _items = veriler;
    } catch (e) {
      debugPrint("🚨 Portföy loadData hatası: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Dolar kurunu önce senin tabela-verileri endpoint'inden, olmazsa Binance USDTTRY'den çeker
  Future<void> _canliDolarKurunuCek() async {
    // 1. Öncelik: Senin Backend Tabela Verileri
    try {
      final res = await http.get(AppConstants.piyasaGet).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['veriler'] as List? ?? data['tabela'] as List? ?? data['data'] as List? ?? []);
        for (var item in list) {
          final isim = (item['name'] ?? item['ad'] ?? item['symbol'] ?? '').toString().toUpperCase();
          if (isim.contains('USD') || isim.contains('DOLAR')) {
            final kur = _parseFiyat(item['raw_price'] ?? item['price'] ?? item['fiyat']);
            if (kur > 20) {
              _usdTryKuru = kur;
              debugPrint("💵 Backend USD/TRY Kuru Çekildi: $_usdTryKuru");
              return;
            }
          }
        }
      }
    } catch (_) {}

    // 2. Yedek: Binance USDT/TRY Canlı Kur (Hiçbir zaman şaşmaz)
    try {
      final bRes = await http
          .get(Uri.parse('https://api.binance.com/api/v3/ticker/price?symbol=USDTTRY'))
          .timeout(const Duration(seconds: 5));
      if (bRes.statusCode == 200) {
        final bData = jsonDecode(bRes.body);
        final kur = _parseFiyat(bData['price']);
        if (kur > 20) {
          _usdTryKuru = kur;
          debugPrint("💵 Binance USD/TRY Kuru Çekildi: $_usdTryKuru");
        }
      }
    } catch (_) {}
  }

  Future<Map<String, double>> _canliFiyatlariBackenddenCek() async {
    final Map<String, double> fiyatlar = {};

    // Popüler ABD ve Kripto sembolleri her zaman aramada çıksın diye başlangıçta ekliyoruz
    const garantiGlobal = [
      'AAPL', 'NVDA', 'TSLA', 'MSFT', 'AMZN', 'GOOGL', 'META', 'AMD', 'NFLX', 'PLTR', 'COIN', 'SPY', 'QQQ', 'INTC',
      'BTCUSDT', 'ETHUSDT', 'SOLUSDT', 'AVAXUSDT', 'XRPUSDT', 'BNBUSDT', 'DOGEUSDT'
    ];
    for (var s in garantiGlobal) {
      fiyatlar[s] = 0.0;
    }

    // 1. BIST Hisseleri
    try {
      final res = await http.get(AppConstants.taraUri).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['hisseler'] as List? ?? data['data'] as List? ?? []);
        for (var h in list) {
          final sym = (h['symbol'] ?? h['kod'] ?? '').toString().toUpperCase().trim();
          final val = _parseFiyat(h['raw_price'] ?? h['lastPrice'] ?? h['price'] ?? h['fiyat']);
          if (sym.isNotEmpty && val > 0) fiyatlar[sym] = val;
        }
      }
    } catch (_) {}

    // 2. Kripto Paralar (Binance üzerinden tüm USDT çiftleri)
    try {
      final bRes = await http.get(Uri.parse('https://api.binance.com/api/v3/ticker/price')).timeout(const Duration(seconds: 6));
      if (bRes.statusCode == 200) {
        final List bList = jsonDecode(bRes.body);
        for (var item in bList) {
          final sym = item['symbol'].toString().toUpperCase();
          if (sym.endsWith('USDT')) {
            final val = _parseFiyat(item['price']);
            if (val > 0) {
              fiyatlar[sym] = val;
              fiyatlar[sym.replaceAll('USDT', '')] = val;
            }
          }
        }
      }
    } catch (_) {}

    // 3. ABD / NASDAQ Hisseleri
    try {
      final yRes = await http.get(AppConstants.yabanciPiyasaGet).timeout(const Duration(seconds: 8));
      if (yRes.statusCode == 200) {
        final data = jsonDecode(yRes.body);
        final tumListe = [
          ...(data['tum_yabancilar'] as List? ?? []),
          ...(data['kazananlar'] as List? ?? []),
          ...(data['kaybedenler'] as List? ?? []),
        ];
        for (var item in tumListe) {
          final sym = (item['symbol'] ?? '').toString().toUpperCase().trim();
          final val = _parseFiyat(item['raw_price'] ?? item['price']);
          if (sym.isNotEmpty && val > 0) fiyatlar[sym] = val;
        }
      }
    } catch (_) {}

    return fiyatlar;
  }

  // --- Finansal Hesaplamalar (Hepsi Otomatik TL Bazında Toplanır) ---
  double get toplamMaliyet => _items.fold(0.0, (acc, item) => acc + item.totalCost);
  double get toplamGuncelDeger => _items.fold(0.0, (acc, item) => acc + item.currentValue);
  double get toplamNetKarZarar => toplamGuncelDeger - toplamMaliyet;
  double get toplamKarZararYuzde =>
      toplamMaliyet > 0 ? (toplamNetKarZarar / toplamMaliyet) * 100 : 0.0;

  // --- İşlemler ---
  Future<void> addItem(String symbol, double lotQuantity, double buyPrice) async {
    final basarili = await PortfolioService.addItem(
      userId: userId,
      symbol: symbol,
      lotQuantity: lotQuantity,
      buyPrice: buyPrice,
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