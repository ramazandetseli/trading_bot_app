import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Paket import edildi
import 'package:trading_bot_app/services/api_service.dart';
import 'package:trading_bot_app/models/rehber_models.dart';
import 'package:trading_bot_app/screens/rehber/rehber_detail_screen.dart';

class RehberScreen extends StatefulWidget {
  const RehberScreen({super.key});

  @override
  State<RehberScreen> createState() => _RehberScreenState();
}

class _RehberScreenState extends State<RehberScreen> {
  String seciliRehber = "Teknik Analiz";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Strateji Rehberi"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          _kategoriButton(),
          Expanded(
            child: FutureBuilder<List<RehberModels>>(
              future: ApiService().rehberleriGetir(seciliRehber),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.greenAccent));
                } else if (snapshot.hasError) {
                  return Center(child: Text("Veriler yüklenirken hata oluştu: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Bu kategoride henüz ders yok."));
                }

                final rehberListesi = snapshot.data!;

                return ListView.builder(
                  itemCount: rehberListesi.length,
                  itemBuilder: (context, index) {
                    final ders = rehberListesi[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: ders.resimUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const SizedBox(
                              width: 60,
                              height: 60,
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.greenAccent)),
                            ),
                            errorWidget: (context, url, error) => const SizedBox(
                              width: 60,
                              height: 60,
                              child: Icon(Icons.image),
                            ),
                          ),
                        ),
                        title: Text(ders.baslik),
                        subtitle: Text(ders.ozet, maxLines: 2, overflow: TextOverflow.ellipsis),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RehberDetailScreen(ders: ders),
                            ),
                          );
                        },  
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _kategoriButton() {
    List<String> kategoriler = ["Grafik Analiz", "Teknik Analiz", "Takas Analizi", "Haber Analizi", "Risk Yönetimi"];
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: kategoriler.map((kat) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ElevatedButton( 
            style: ElevatedButton.styleFrom(
              backgroundColor: seciliRehber == kat ? Colors.greenAccent : Colors.grey[300],
              foregroundColor: seciliRehber == kat ? Colors.white : Colors.black,
            ),
            onPressed: () {
              setState(() {
                seciliRehber = kat;
              });
            },
            child: Text(kat),
          ),
        )).toList(),
      ),
    );
  }
}