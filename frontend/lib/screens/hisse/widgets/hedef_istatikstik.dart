import 'package:flutter/material.dart';

class HisseHedefGridWidget extends StatelessWidget {
  final Color card, border, cyan;
  final bool analizBitti, analizYukleniyor;
  final double hedefDirenc, potansiyel, stopDestek;
  
  const HisseHedefGridWidget({required this.card, required this.border, required this.cyan, required this.analizBitti, required this.analizYukleniyor, required this.hedefDirenc, required this.potansiyel, required this.stopDestek});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
      child: () {
        if (analizYukleniyor) {
          return const Center(child: Text("Hedef Seviyeler Hesaplanıyor...", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)));
        }
        if (analizBitti) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _targetItem('DİRENÇ', '${hedefDirenc.toStringAsFixed(2)} ₺', Colors.greenAccent),
              Container(width: 1, height: 35, color: border),
              _targetItem('POTANSİYEL', '%${potansiyel.toStringAsFixed(2)}', cyan),
              Container(width: 1, height: 35, color: border),
              _targetItem('STOP', '${stopDestek.toStringAsFixed(2)} ₺', Colors.redAccent),
            ],
          );
        }
        return const Center(child: Text("Hedef & Stop Seviyeleri İçin Analiz Başlatın", style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w500)));
      }(),
    );
  }

  Widget _targetItem(String title, String val, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(val, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
      ],
    );
  }
}