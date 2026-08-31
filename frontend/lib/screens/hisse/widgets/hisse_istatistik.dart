import 'package:flutter/material.dart';

class HisseStatsRowWidget extends StatelessWidget {
  final Color card, border, gold;
  final double rsi, relVol;
  final bool isBullish, isVip, isAgresif;
  
  const HisseStatsRowWidget({
    super.key, 
    required this.card, 
    required this.border, 
    required this.rsi, 
    required this.relVol, 
    required this.isBullish, 
    required this.isVip, 
    required this.isAgresif, 
    required this.gold,
  });

  @override
  Widget build(BuildContext context) {
    // 🔥 Hacim Yorumlama Mantığı (Sıradan kullanıcı için)
    String hacimMetni;
    Color hacimRenk;
    
    if (relVol >= 2.0) {
      hacimMetni = 'YOĞUN';
      hacimRenk = Colors.greenAccent; // Hacim patlaması var
    } else if (relVol >= 0.8) {
      hacimMetni = 'NORMAL';
      hacimRenk = Colors.white70; // Standart akış
    } else {
      hacimMetni = 'SAKİN';
      hacimRenk = Colors.white54; // Yaprak kımıldamıyor
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // RSI
          _statChip(
            'RSI', 
            rsi.toStringAsFixed(0), 
            rsi < 35 ? Colors.greenAccent : rsi > 70 ? Colors.redAccent : Colors.white70,
          ),
          const SizedBox(width: 8),
          
          // Hacim (Artık 2x yerine "YOĞUN" yazacak)
          _statChip(
            'HACİM', 
            hacimMetni, 
            hacimRenk,
          ),
          const SizedBox(width: 8),
          
          // Trend
          _statChip(
            'TREND', 
            isBullish ? 'POZİTİF' : 'NEGATİF', 
            isBullish ? Colors.greenAccent : Colors.redAccent,
          ),
          const SizedBox(width: 8),
          
          // Sinyal
          _statChip(
            'SİNYAL', 
            isVip ? 'VIP' : isAgresif ? 'AGRESİF' : 'SAKİN', 
            isVip ? gold : isAgresif ? Colors.orangeAccent : Colors.white70,
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08), 
          borderRadius: BorderRadius.circular(14), 
          border: Border.all(color: color.withValues(alpha: 0.25)), 
        ),
        child: Column(
          children: [
            Text(
              label, 
              style: const TextStyle(
                color: Colors.white60, 
                fontSize: 9, 
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value, 
              style: TextStyle(
                color: color, 
                fontSize: 11, 
                fontWeight: FontWeight.w900,
              ), 
              maxLines: 1, 
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}