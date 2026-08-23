import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trading_bot_app/models/hisse_model.dart';
import 'package:trading_bot_app/screens/hisse/alarm_kur.dart';

class HisseCard extends StatelessWidget {
  final Hissemodel hisse;
  final bool isFav;
  final VoidCallback onTap;

  static const String baseUrl = 'http://10.15.166.50:8000';

 final VoidCallback? onFavoriDegisti;

  const HisseCard({
    super.key,
    required this.hisse,
    required this.isFav,
    required this.onTap,
    this.onFavoriDegisti,
  });

  Future<void> _favoriIslem(BuildContext context) async {
  final String? userId = Supabase.instance.client.auth.currentUser?.id;
  print("👤 USER ID: $userId");  
  if (userId == null) {
    print("🚨 KULLANICI GİRİŞ YAPMAMIŞ!");
    return;
  }

  final endpoint = isFav ? '/favori-sil' : '/favori-ekle';
  print("📡 İSTEK ATILIYOR: $baseUrl$endpoint");  // 👈
  
  final url = Uri.parse('$baseUrl$endpoint');

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId, "symbol": hisse.symbol}),
    );

    debugPrint('🛰️ Favori isteği cevap: ${response.statusCode}');
    debugPrint('🛰️ Cevap gövdesi: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      onFavoriDegisti?.call();  // 👈 dashboard'a haber ver
      final mesaj = isFav
          ? "${hisse.symbol} favorilerden kaldırıldı."
          : "${hisse.symbol} favorilere eklendi.";
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mesaj), backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Favori işlemi başarısız: ${response.statusCode}')),
      );
    }
  } catch (e) {
    debugPrint("HisseCard Favori Hatası: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Favori isteği sırasında hata oluştu: $e')),
    );
  }
}

 

  Color _statusColor(bool isDark) {
    if (isFav) return Colors.yellowAccent;
    if (hisse.signal.contains('VIP')) return Colors.greenAccent;
    if (hisse.signal.contains('AGRASİF')) return Colors.orangeAccent;
    return isDark ? Colors.grey[700]! : Colors.grey[400]!;
  }

  Color _bgColor(Color statusColor, bool isDark) {
    final isSpecial = isFav || hisse.signal.contains('VIP') || hisse.signal.contains('AGRASİF');
    if (isSpecial) return statusColor.withValues(alpha: 0.1);
    return isDark ? const Color(0xFF161B22) : Colors.grey[100]!;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final statusColor = _statusColor(isDark);
    final bgColor = _bgColor(statusColor, isDark);

    final isSpecial = isFav || hisse.signal.contains('VIP') || hisse.signal.contains('AGRASİF');
    final isPositive = hisse.change >= 0;

    // 🧱 MERKEZİ KAYDIRMA ZIRHI: Dismissible artık kartın tam göbeğinde amk!
    return Dismissible(
      key: ValueKey('dismissible_${hisse.symbol}'),
      direction: DismissDirection.horizontal,
      
      // Sola kaydırınca çıkacak Favori Alanı aga
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isFav ? Colors.redAccent : Colors.amber,
          borderRadius: BorderRadius.circular(22),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(
          isFav ? Icons.star_border : Icons.star,
          color: Colors.white,
        ),
      ),
      
      // Sağa kaydırınca çıkacak Alarm Alanı aga
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(22),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.notifications_active, color: Colors.white),
      ),
      
      // Kaydırma bırakıldığı an kendi içindeki fonksiyonları ateşler amk
      confirmDismiss: (direction) async {
      print("🔥 KAYDIRMA ALGILANDI: $direction");  // 👈
      if (direction == DismissDirection.startToEnd) {
        print("⭐ FAVORİ ISLEMI BASLADI: ${hisse.symbol}");  // 👈
        await _favoriIslem(context);
      } else {
        AlarmKur.goster(
            context: context, 
            symbol: hisse.symbol, 
            anlikFiyat: hisse.price,
          );
          }
      return false;
    },
      
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: statusColor.withValues(alpha: isDark ? 1.0 : 0.5),
              width: isSpecial ? 1.5 : 0.5,
            ),
            boxShadow: (!isDark && isSpecial)
                ? [BoxShadow(color: statusColor.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 2))]
                : null,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: statusColor,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.network(
                    "https://storage.fintables.com/media/uploads/company-logos/${hisse.symbol.toLowerCase()}_icon.png",
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white54),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(child: Text(hisse.symbol[0]));
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          hisse.symbol,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                        ),
                        const SizedBox(width: 6),
                        _buildBadge(),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hisse.signal.isNotEmpty ? hisse.signal : 'Hacim: ${hisse.relVol}',
                      style: TextStyle(color: statusColor.withValues(alpha: 0.85), fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${hisse.price} ₺',
                    style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '%${hisse.change}',
                    style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge() {
    if (isFav) return const Icon(Icons.star, color: Colors.yellowAccent, size: 15);
    if (hisse.signal.contains('VIP')) return const Icon(Icons.bolt, color: Colors.greenAccent, size: 15);
    if (hisse.signal.contains('AGRASİF')) return const Icon(Icons.whatshot, color: Colors.orangeAccent, size: 15);
    return const SizedBox.shrink();
  }
}