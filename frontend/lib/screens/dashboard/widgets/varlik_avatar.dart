import 'package:flutter/material.dart';

class VarlikLogoWidget extends StatefulWidget {
  final String symbol;
  final String? kategori; // 'Hisseler', 'Kripto', 'Yabancı', 'Fonlar' veya null (Portföy için)
  final double size;

  const VarlikLogoWidget({
    super.key,
    required this.symbol,
    this.kategori,
    this.size = 28,
  });

  @override
  State<VarlikLogoWidget> createState() => _VarlikLogoWidgetState();
}

class _VarlikLogoWidgetState extends State<VarlikLogoWidget> {
  static final Map<String, String> _urlCache = {};

  late String temizSymbol;
  int denemeAsamasi = 0;
  String? cachedUrl;

  @override
  void initState() {
    super.initState();
    _hazirla();
  }

  @override
  void didUpdateWidget(covariant VarlikLogoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.symbol != widget.symbol || oldWidget.kategori != widget.kategori) {
      _hazirla();
    }
  }

  // Portföy gibi yerlerde kategori null gelse bile sembolden tipi anında anlar
  String get efektifKategori {
    final kat = widget.kategori;
    if (kat != null && kat.isNotEmpty && kat != 'Hisseler') {
      return kat;
    }

    final sym = widget.symbol.trim().toUpperCase();

    // 1. Kripto Tespiti
    const bilinenKriptolar = {
      'BTC', 'ETH', 'SOL', 'AVAX', 'XRP', 'DOGE', 'BNB', 'ADA', 'DOT', 'TRX', 'LINK', 'MATIC', 'NEAR', 'SUI', 'PEPE', 'SHIB'
    };
    if (sym.endsWith('USDT') || bilinenKriptolar.contains(sym)) {
      return 'Kripto';
    }

    // 2. ABD / Nasdaq Tespiti
    const usHisseleri = {
      'AAPL', 'NVDA', 'TSLA', 'MSFT', 'AMZN', 'GOOGL', 'GOOG', 'META',
      'SPY', 'QQQ', 'AMD', 'INTC', 'NFLX', 'COIN', 'PLTR', 'BABA', 'BRK.B'
    };
    if (usHisseleri.contains(sym)) {
      return 'Yabancı';
    }

    // 3. Fon Tespiti (Genelde 3 harflidir: TZL, AFT vb. ama BIST hisseleri en az 4-5 harf)
    if (sym.length == 3 && !bilinenKriptolar.contains(sym)) {
      // 3 harfli standart fon kodu varsayımı
      return 'Fonlar';
    }

    // Varsayılan Borsa İstanbul
    return 'Hisseler';
  }

  void _hazirla() {
    temizSymbol = widget.symbol.trim().toUpperCase();
    denemeAsamasi = 0;
    cachedUrl = _urlCache['${efektifKategori}_$temizSymbol'];
  }

  String get aktifUrl {
    if (cachedUrl != null) return cachedUrl!;
    final kat = efektifKategori;

    // 1. KRİPTO LOGOLARI (CoinCap CDN - Cayır cayır çalışan kısım)
    if (kat == 'Kripto') {
      final coin = temizSymbol.replaceAll('USDT', '').toLowerCase();
      return "https://assets.coincap.io/assets/icons/$coin@2x.png";
    }

    // 2. YABANCI HİSSELER (NASDAQ / NYSE)
    // Clearbit yerine doğrudan çalışan resmi FinancialModelingPrep + Google Favicon zinciri
    if (kat.contains('Yabancı')) {
      const usDomainMap = {
        'AAPL': 'apple.com',
        'NVDA': 'nvidia.com',
        'TSLA': 'tesla.com',
        'MSFT': 'microsoft.com',
        'AMZN': 'amazon.com',
        'GOOGL': 'google.com',
        'GOOG': 'google.com',
        'META': 'meta.com',
        'AMD': 'amd.com',
        'INTC': 'intel.com',
        'NFLX': 'netflix.com',
        'COIN': 'coinbase.com',
        'PLTR': 'palantir.com',
        'SPY': 'ssga.com',
        'QQQ': 'invesco.com',
      };

      if (denemeAsamasi == 0) {
        // 1. Deneme: FinancialModelingPrep Resmi Borsa Logosu (Ticker bazlı, token istemez)
        return "https://financialmodelingprep.com/image-stock/$temizSymbol.png";
      } else if (denemeAsamasi == 1) {
        // 2. Deneme: DuckDuckGo Yüksek Çözünürlüklü Favicon API
        final domain = usDomainMap[temizSymbol];
        if (domain != null) {
          return "https://icons.duckduckgo.com/ip3/$domain.ico";
        }
      } else if (denemeAsamasi == 2) {
        // 3. Deneme: Google Favicon Servisi (Hiçbir zaman 403 vermez)
        final domain = usDomainMap[temizSymbol];
        if (domain != null) {
          return "https://www.google.com/s2/favicons?domain=$domain&sz=128";
        }
      }
      return "";
    }

    // 3. FONLAR İÇİN URL YOK (İkon döner)
    if (kat == 'Fonlar') {
      return "";
    }

    // 4. BIST HİSSELERİ (Fintables Kademeli Fallback)
    final lower = temizSymbol.toLowerCase();
    if (denemeAsamasi == 0) {
      return "https://storage.fintables.com/media/uploads/company-logos/${lower}_icon.png";
    } else if (denemeAsamasi == 1) {
      return "https://storage.fintables.com/media/uploads/company-logos/${temizSymbol}_icon.png";
    } else if (denemeAsamasi == 2) {
      return "https://storage.fintables.com/media/uploads/company-logos/$temizSymbol.png";
    } else if (denemeAsamasi == 3) {
      return "https://storage.fintables.com/media/uploads/company-logos/${lower}_logo.png";
    }

    return "";
  }

  @override
  Widget build(BuildContext context) {
    final kat = efektifKategori;

    // Fonlar için doğrudan ikon bas
    if (kat == 'Fonlar') {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.amberAccent.withValues(alpha: 0.12),
          border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
        ),
        child: Icon(Icons.pie_chart_rounded, size: widget.size * 0.55, color: Colors.amberAccent),
      );
    }

    final url = aktifUrl;
    if (url.isEmpty) {
      return _buildFallbackText();
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.size / 2),
        child: Image.network(
          url,
          fit: BoxFit.contain,
          cacheWidth: 120,
          cacheHeight: 120,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white24),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            // BIST (4 aşama) veya Yabancı (3 aşama) için fallback basamaklarını işlet
            final int maxDeneme = (kat.contains('Yabancı')) ? 2 : 3;

            if (denemeAsamasi < maxDeneme) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() => denemeAsamasi++);
                }
              });
              return const SizedBox();
            }

            return _buildFallbackText();
          },
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (frame != null && cachedUrl == null && url.isNotEmpty) {
              _urlCache['${kat}_$temizSymbol'] = url;
            }
            return child;
          },
        ),
      ),
    );
  }

  Widget _buildFallbackText() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1E2837),
        border: Border.all(color: Colors.white12),
      ),
      child: Center(
        child: Text(
          widget.symbol.isNotEmpty ? widget.symbol[0].toUpperCase() : "?",
          style: TextStyle(
            color: const Color(0xFF00E676),
            fontWeight: FontWeight.bold,
            fontSize: widget.size * 0.42,
          ),
        ),
      ),
    );
  }
}