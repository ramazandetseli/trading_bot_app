import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Paket import edildi
import 'package:trading_bot_app/models/rehber_models.dart';

class RehberDetailScreen extends StatelessWidget {
  final RehberModels ders;

  const RehberDetailScreen({super.key, required this.ders});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ders.baslik, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ÜST KAPAK RESMİ (AI Görseli)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: ders.resimUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.greenAccent),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategori Etiketi (Badge)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ders.kategori,
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Başlık
                  Text(
                    ders.baslik,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 30, thickness: 1),

                  // Detaylar Alt Başlığı
                  const Text(
                    "Analiz ve Eğitim Detayları",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent),
                  ),
                  const SizedBox(height: 10),

                  // Detay Metni
                  Text(
                    ders.detayMetni,
                    style: const TextStyle(fontSize: 15, height: 1.6, fontWeight: FontWeight.w500),
                  ),
                  
                  ...[
                  const Divider(height: 40, thickness: 1),
                  const Text(
                    "Teknik Gösterim / Örnek Senaryo",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 12),
                  
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: GestureDetector(
                        onTap: () {
                          _tamEkranResimGoster(context, ders.graphicUrl);
                        },
                        child: CachedNetworkImage(
                          imageUrl: ders.graphicUrl,
                          fit: BoxFit.contain, // Grafiklerin kırpılmaması için contain kalmalı
                          placeholder: (context, url) => const SizedBox(
                            height: 200,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => const SizedBox(
                            height: 100,
                            child: Center(child: Icon(Icons.broken_image, size: 40)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _tamEkranResimGoster(BuildContext context, String url) {
  showDialog(
    context: context,
    barrierDismissible: true, // Resmin dışına basınca kapansın
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent, // Arka planı şeffaf yaptık ki sadece resim gözüksün
      insetPadding: const EdgeInsets.all(10), // Kenarlardan ufak bir boşluk
      child: GestureDetector(
        onTap: () => Navigator.pop(context), // Resme tekrar basınca da kapansın
        child: InteractiveViewer( // Kullanıcı iki parmağıyla resmi büyütebilsin (Zoom)
          panEnabled: true,
          maxScale: 4.0,
          child: Hero(
            tag: 'grafik_${ders.id}', // Yukarıdaki tag ile tamamen aynı olmalı
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    ),
  );
}
}