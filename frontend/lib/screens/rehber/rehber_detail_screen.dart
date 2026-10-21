import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:trading_bot_app/models/rehber_models.dart';

class RehberDetailScreen extends StatelessWidget {
  final RehberModels ders;

  const RehberDetailScreen({super.key, required this.ders});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      // CustomScrollView ile sayfayı aşağı kaydırdıkça üstteki resmin küçülüp AppBar'a dönüştüğü o premium efekti veriyoruz.
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // HAVALI ÜST KAPAK (SliverAppBar)
          SliverAppBar(
            expandedHeight: 260.0,
            pinned: true,
            stretch: true,
            backgroundColor: colorScheme.surface,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white), // Geri butonu beyaz
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: ders.resimUrl,
                    fit: BoxFit.cover,
                    // 🔥 İŞTE GECİKMEYİ ÇÖZEN SİHİR: Linkin sonundaki token'ları yoksay!
                    cacheKey: ders.resimUrl.split('?').first,
                    placeholder: (context, url) => Container(
                      color: colorScheme.surfaceContainerHigh,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: colorScheme.surfaceContainerHigh,
                      child: const Icon(Icons.broken_image_rounded, size: 50),
                    ),
                  ),
                  // Resmin üzerine hafif siyah degrade atıyoruz ki geri butonu her resimde okunsun
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                          colorScheme.surface.withValues(alpha: 0.8),
                          colorScheme.surface,
                        ],
                        stops: const [0.0, 0.3, 0.9, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // SAYFA İÇERİĞİ
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategori Etiketi
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ders.kategori.toUpperCase(),
                      style: TextStyle(
                        color: colorScheme.primary, 
                        fontWeight: FontWeight.w800, 
                        fontSize: 11,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Başlık
                  Text(
                    ders.baslik,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  const SizedBox(height: 24),

                  // Detay Metni
                  Text(
                    ders.detayMetni,
                    style: TextStyle(
                      fontSize: 16, 
                      height: 1.6, 
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  const SizedBox(height: 24),

                  // Grafik Başlığı
                  Row(
                    children: [
                      Icon(Icons.insights_rounded, color: colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "Teknik Gösterim",
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold, 
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Büyütülebilir Grafik Kartı
                  GestureDetector(
                    onTap: () => _tamEkranResimGoster(context, ders.graphicUrl),
                    child: Hero(
                      tag: 'grafik_${ders.id}', // Hero animasyonu için
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 200),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: CachedNetworkImage(
                            imageUrl: ders.graphicUrl,
                            fit: BoxFit.contain,
                            // 🔥 Grafikteki gecikmeyi de aynı taktikle çözüyoruz
                            cacheKey: ders.graphicUrl.split('?').first,
                            placeholder: (context, url) => const SizedBox(
                              height: 200,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) => const SizedBox(
                              height: 200,
                              child: Center(child: Icon(Icons.broken_image_rounded, size: 40)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      "Büyütmek için grafiğe dokunun",
                      style: TextStyle(fontSize: 12, color: colorScheme.outline, fontStyle: FontStyle.italic),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAM EKRAN GRAFİK DİYALOĞU
  // =========================================================================
  void _tamEkranResimGoster(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9), // Sinema modu gibi simsiyah arka plan
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero, // Ekranı tam kaplasın
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              maxScale: 4.0,
              minScale: 0.5,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: Hero(
                    tag: 'grafik_${ders.id}',
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.contain,
                      cacheKey: url.split('?').first,
                    ),
                  ),
                ),
              ),
            ),
            // Çarpı (Kapat) Butonu
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}