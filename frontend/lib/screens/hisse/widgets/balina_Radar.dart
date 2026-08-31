import 'package:flutter/material.dart';

class WhaleLiveMetricsWidget extends StatelessWidget {
  final Color card, cyan;
  final double riskSkoru;
  final String stratejiEtiketi, fonAkisi;

  const WhaleLiveMetricsWidget({
    super.key,
    required this.card,
    required this.cyan,
    required this.riskSkoru,
    required this.stratejiEtiketi,
    required this.fonAkisi,
  });

  @override
  Widget build(BuildContext context) {
    bool isHighRisk = riskSkoru > 65;
    Color riskColor = isHighRisk ? Colors.redAccent : Colors.greenAccent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cyan.withValues(alpha: 0.3)),
        // AI kartı olduğu için çok hafif bir ışıma (glow) ekliyoruz
        boxShadow: [
          BoxShadow(
            color: cyan.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            children: [
              Icon(Icons.radar_rounded, color: cyan, size: 18),
              const SizedBox(width: 8),
              Text(
                'BALİNA RADARI & YAPAY ZEKA',
                style: TextStyle(
                  color: cyan,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Strateji
          _buildMetricRow(
            icon: Icons.auto_graph_rounded,
            iconColor: Colors.orangeAccent,
            label: 'Tahtacı Stratejisi',
            value: stratejiEtiketi,
          ),
          const SizedBox(height: 14),

          // Fon Akışı
          _buildMetricRow(
            icon: Icons.waves_rounded,
            iconColor: Colors.tealAccent,
            label: 'Fon Akış Durumu',
            value: fonAkisi,
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white10, height: 1),
          ),

          // Risk Metre
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Algoritmik Risk Skoru",
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "%${riskSkoru.toInt()}",
                  style: TextStyle(
                    color: riskColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: riskSkoru / 100,
              color: riskColor,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              minHeight: 8, // Barı biraz daha dolgun yaptık
            ),
          ),
        ],
      ),
    );
  }

  // Tekrarlayan satırları temiz tutmak için yardımcı widget
  Widget _buildMetricRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}