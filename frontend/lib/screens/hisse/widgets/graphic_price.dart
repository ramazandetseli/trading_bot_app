import 'package:flutter/material.dart';
import 'package:trading_bot_app/screens/hisse/widgets/hisse_grafik.dart';

/// 1. GÖMÜLÜ GRAFİK VE FİYAT WIDGET'I (SAYFANIN YILDIZI)
class HisseHeroVeGrafikWidget extends StatelessWidget {
  final String fullName, symbol;
  final double price, change;
  final bool isPositive;
  final Color bg;
  final Function(double, double) onDataFetched;
  final Function(String) onPeriodChanged;

  const HisseHeroVeGrafikWidget({
    required this.fullName, 
    required this.price, 
    required this.change, 
    required this.symbol, 
    required this.isPositive, 
    required this.bg,
    required this.onDataFetched,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? Colors.greenAccent : Colors.redAccent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 100, bottom: 20), 
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.10), bg], 
        ),
      ),
      child: Column(
        children: [
          Text(fullName, style: TextStyle(color: Colors.white.withValues(alpha: .5), fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(price.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w900, letterSpacing: -2)),
              const Text(' ₺', style: TextStyle(color: Colors.white30, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: color.withValues(alpha: .15), borderRadius: BorderRadius.circular(20)),
            child: Text('${isPositive ? '+' : ''}${change.toStringAsFixed(2)}%', style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
          
          SizedBox(
            height: 300,
            child: HisseGrafikWidget(symbol: symbol, onDataFetched: onDataFetched, onPeriodChanged: onPeriodChanged), 
          ),
        ],
      ),
    );
  }
}