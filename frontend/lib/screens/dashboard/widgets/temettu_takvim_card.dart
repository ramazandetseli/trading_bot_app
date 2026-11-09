import 'package:flutter/material.dart';
import 'package:trading_bot_app/models/temettu_model.dart';

class TemettuTakvimWidget extends StatefulWidget {
  const TemettuTakvimWidget({super.key});

  @override
  State<TemettuTakvimWidget> createState() => _TemettuTakvimWidgetState();
}

class _TemettuTakvimWidgetState extends State<TemettuTakvimWidget> {
  late Future<List<TemettuModel>> _temettuFuture;

  @override
  void initState() {
    super.initState();
    _temettuFuture = TemettuService.fetchTemettuTakvimi();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık Alanı
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Temettü Takvimi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
                onPressed: () {
                  setState(() {
                    _temettuFuture = TemettuService.fetchTemettuTakvimi();
                  });
                },
              ),
            ],
          ),
        ),

        // Future Veri Alanı
        SizedBox(
          height: 145,
          child: FutureBuilder<List<TemettuModel>>(
            future: _temettuFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.tealAccent),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Veri yüklenemedi',
                    style: TextStyle(color: Colors.redAccent.shade100, fontSize: 13),
                  ),
                );
              }

              final veriler = snapshot.data ?? [];
              if (veriler.isEmpty) {
                return const Center(
                  child: Text('Yaklaşan temettü yok', style: TextStyle(color: Colors.white54)),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                scrollDirection: Axis.horizontal,
                itemCount: veriler.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = veriler[index];
                  return _buildTemettuCard(item);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTemettuCard(TemettuModel item) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E222D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Üst Satır: Sembol ve Temettü Verimi Rozeti
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.sembol,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.tealAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.verim.isEmpty ? '-' : item.verim,
                  style: const TextStyle(
                    color: Colors.tealAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          // Şirket Başlığı
          Text(
            item.unvan,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),

          const Divider(color: Colors.white10, height: 8),

          // Alt Satır: Brüt Tutar ve Tarih
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Brüt / Pay', style: TextStyle(color: Colors.white38, fontSize: 10)),
                  Text(
                    item.payBasinaBrut,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Tarih', style: TextStyle(color: Colors.white38, fontSize: 10)),
                  Text(
                    item.tarih,
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}