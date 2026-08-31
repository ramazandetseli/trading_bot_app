import 'package:flutter/material.dart';

class HisseLogoWidget extends StatefulWidget {
  final String symbol;
  final double size;

  const HisseLogoWidget({super.key, required this.symbol, this.size = 28});

  @override
  State<HisseLogoWidget> createState() => _HisseLogoWidgetState();
}

class _HisseLogoWidgetState extends State<HisseLogoWidget> {
  static final Map<String, String> _urlCache = {};

  late String temizSymbol;
  int denemeAsamasi = 0;
  String? cachedUrl;

  @override
  void initState() {
    super.initState();
    temizSymbol = widget.symbol.trim();
    cachedUrl = _urlCache[temizSymbol];
  }

  String get aktifUrl {
    if (cachedUrl != null) return cachedUrl!;

    if (denemeAsamasi == 0) {
      return "https://storage.fintables.com/media/uploads/company-logos/${temizSymbol.toLowerCase()}_icon.png";
    } else if (denemeAsamasi == 1) {
      return "https://storage.fintables.com/media/uploads/company-logos/${temizSymbol}_icon.png";
    } else if (denemeAsamasi == 2) {
      return "https://storage.fintables.com/media/uploads/company-logos/${temizSymbol.toUpperCase()}.png";
    } else if (denemeAsamasi == 3) {
      return "https://storage.fintables.com/media/uploads/company-logos/${temizSymbol.toLowerCase()}_logo.png";
    } else  {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    // Eğer URL önbellekte varsa hata döngülerine hiç girme, direkt resmi çiz
    if (cachedUrl != null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Image.network(
          cachedUrl!,
          fit: BoxFit.contain,
          cacheWidth: 100,
          cacheHeight: 100,
        ),
      );
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Image.network(
        aktifUrl,
        fit: BoxFit.contain,
        cacheWidth: 100,
        cacheHeight: 100,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white54),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          if (denemeAsamasi < 2) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  denemeAsamasi++; // Sıradaki deneme aşamasına geç (0 -> 1 -> 2)
                });
              }
            });
            return const SizedBox();
          }

          // Hepsi patladıysa ilk harfi bas
          return Center(
            child: Text(
              widget.symbol.isNotEmpty ? widget.symbol[0].toUpperCase() : "?",
              style: const TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold, 
                fontSize: 12,
              ),
            ),
          );
        },
        // 🔥 Resim başarıyla yüklendiği an çalışan URL'yi hafızaya çiviliyoruz!
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (frame != null && cachedUrl == null) {
            _urlCache[temizSymbol] = aktifUrl;
          }
          return child;
        },
      ),
    );
  }
}