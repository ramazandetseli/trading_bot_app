import 'package:flutter/material.dart';

class AiAnalizKartWidget extends StatelessWidget {
  final Color cardColor, borderColor, cyan, gold;
  final bool analizBitti, analizYukleniyor, isGelismisMod;
  final String aiYorum;
  final Function(bool) onAnalizTetikle;

  const AiAnalizKartWidget({
    super.key, 
    required this.cardColor, 
    required this.borderColor, 
    required this.cyan, 
    required this.gold, 
    required this.analizBitti, 
    required this.analizYukleniyor, 
    required this.isGelismisMod, 
    required this.aiYorum, 
    required this.onAnalizTetikle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor, 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_rounded, color: cyan, size: 22),
              const SizedBox(width: 8),
              Text(
                'YAPAY ZEKA ANALİZİ', 
                style: TextStyle(color: cyan, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (analizYukleniyor)
            Column(
              children: [
                LinearProgressIndicator(
                  color: isGelismisMod ? gold : cyan, 
                  backgroundColor: Colors.white10,
                ),
                const SizedBox(height: 12),
                Text(
                  isGelismisMod 
                      ? "Derin Yapay Zeka grafiği ve tahta akışını çözümlüyor..." 
                      : "Piyasa haberleri ve trendler okunuyor...", 
                  style: TextStyle(color: Colors.white.withValues(alpha: .5), fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            )
          else if (analizBitti)
            Text(aiYorum, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6))
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cyan.withValues(alpha: .1), 
                      foregroundColor: cyan, 
                      elevation: 0, 
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: cyan, width: 0.5)),
                    ),
                    icon: const Icon(Icons.bolt_rounded, size: 16),
                    label: const Text("Hızlı (Temel)\nAnaliz", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: () => onAnalizTetikle(false), 
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold.withValues(alpha: .15), 
                      foregroundColor: gold, 
                      elevation: 0, 
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: gold, width: 0.5)),
                    ),
                    icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: const Text("Derin Analiz\n(Premium)", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: () => onAnalizTetikle(true), 
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}