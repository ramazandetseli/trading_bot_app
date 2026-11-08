import 'package:flutter/material.dart';
import 'package:trading_bot_app/models/portfolio_item.dart';
import 'package:trading_bot_app/screens/dashboard/widgets/varlik_avatar.dart';
import 'portfolio_theme.dart';

// --- 1. Dağılım Çubuğu ---
class PortfolioDistributionBar extends StatelessWidget {
  final List<PortfolioItem> items;
  final double toplamGuncelDeger;

  const PortfolioDistributionBar({super.key, required this.items, required this.toplamGuncelDeger});

  @override
  Widget build(BuildContext context) {
    if (toplamGuncelDeger <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: PortfolioTheme.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: PortfolioTheme.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Varlık Dağılımı (TL Karşılığı)", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(
                children: items.asMap().entries.map((entry) {
                  final oran = entry.value.currentValue / toplamGuncelDeger;
                  final color = PortfolioTheme.segmentColors[entry.key % PortfolioTheme.segmentColors.length];
                  return Expanded(flex: (oran * 1000).toInt().clamp(1, 1000), child: Container(color: color));
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12, runSpacing: 6,
            children: items.asMap().entries.map((entry) {
              final yuzde = (entry.value.currentValue / toplamGuncelDeger) * 100;
              final color = PortfolioTheme.segmentColors[entry.key % PortfolioTheme.segmentColors.length];
              return Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text("${entry.value.symbol} %${yuzde.toStringAsFixed(1)}", style: const TextStyle(color: Colors.white60, fontSize: 10)),
              ]);
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// --- 2. Finansal Özet Kartı ---
class PortfolioFinancialSummary extends StatelessWidget {
  final double toplamMaliyet;
  final double toplamGuncelDeger;
  final double toplamNetKarZarar;
  final double toplamKarZararYuzde;

  const PortfolioFinancialSummary({super.key, required this.toplamMaliyet, required this.toplamGuncelDeger, required this.toplamNetKarZarar, required this.toplamKarZararYuzde});

  @override
  Widget build(BuildContext context) {
    final bool isPositive = toplamNetKarZarar >= 0;
    final Color statusColor = isPositive ? PortfolioTheme.green : PortfolioTheme.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: PortfolioTheme.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: PortfolioTheme.border)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("Toplam Portföy Değeri (TL)", style: TextStyle(color: Colors.white54, fontSize: 11)),
                const SizedBox(height: 4),
                Text("₺${toplamGuncelDeger.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
                child: Row(children: [
                  Icon(isPositive ? Icons.trending_up : Icons.trending_down, color: statusColor, size: 14),
                  const SizedBox(width: 4),
                  Text("%${toplamKarZararYuzde.toStringAsFixed(2)}", style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: PortfolioTheme.border, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metricItem("Yatırılan Para", "₺${toplamMaliyet.toStringAsFixed(2)}", Colors.white70),
              _metricItem("Net Kâr / Zarar", "${isPositive ? '+' : ''}₺${toplamNetKarZarar.toStringAsFixed(2)}", statusColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricItem(String label, String value, Color valColor) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(color: valColor, fontSize: 13, fontWeight: FontWeight.bold)),
    ]);
  }
}

// --- 3. Varlık Listesi ---
class PortfolioAssetList extends StatelessWidget {
  final List<PortfolioItem> items;
  final Function(String) onDelete;

  const PortfolioAssetList({super.key, required this.items, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final Color statusColor = item.isProfitable ? PortfolioTheme.green : PortfolioTheme.red;
        
        // Varlığın kendi para birimi sembolü ($ veya ₺)
        final birim = item.currencySymbol;
        final aktifFiyat = item.currentPrice > 0 ? item.currentPrice : item.buyPrice;

        return Dismissible(
          key: Key(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.2), 
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.redAccent),
          ),
          // 👇 Kritik Düzeltme: Kaydırma bittiği an önce yerel listeden siliyoruz, sonra controller'a bildiriyoruz
          onDismissed: (direction) {
            final silinecekId = item.id;
            // Listeden anında uçur ki dismissed widget ağaçta kalmasın
            items.removeWhere((element) => element.id == silinecekId);
            // Ardından controller'daki silme fonksiyonunu tetikle
            onDelete(silinecekId);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PortfolioTheme.card, 
              borderRadius: BorderRadius.circular(14), 
              border: Border.all(color: PortfolioTheme.border),
            ),
            child: Row(
              children: [
                VarlikLogoWidget(
                  symbol: item.symbol,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(item.symbol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(width: 6),
                          if (item.isUsdAsset)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.orangeAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text("USD", style: TextStyle(color: Colors.orangeAccent, fontSize: 8.5, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${item.lotQuantity.toStringAsFixed(item.lotQuantity.truncateToDouble() == item.lotQuantity ? 0 : 2)} Adet • $birim${item.buyPrice.toStringAsFixed(2)} maliyet",
                        style: const TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "$birim${item.nativeCurrentValue.toStringAsFixed(2)}",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${item.isProfitable ? '+' : ''}%${item.profitLossPercentage.toStringAsFixed(2)}",
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- 4. Enflasyon Kıyaslama ---
class PortfolioInflationComparison extends StatelessWidget {
  final double portfoyGetirisi;

  const PortfolioInflationComparison({super.key, required this.portfoyGetirisi});

  @override
  Widget build(BuildContext context) {
    const double tahminiTefeTufe = 62.0;
    final bool enflasyonuEzdi = portfoyGetirisi >= tahminiTefeTufe;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: PortfolioTheme.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: PortfolioTheme.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("Yıllık Reel Getiri vs Enflasyon", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          Icon(Icons.insights_rounded, color: PortfolioTheme.cyan, size: 16),
        ]),
        const SizedBox(height: 12),
        _kiyaslamaBar("Portföy Getirin", portfoyGetirisi, portfoyGetirisi >= 0 ? PortfolioTheme.green : PortfolioTheme.red),
        const SizedBox(height: 8),
        _kiyaslamaBar("Yıllık TÜFE (Referans)", tahminiTefeTufe, Colors.orangeAccent),
        const SizedBox(height: 12),
        Text(enflasyonuEzdi ? "🎯 Tebrikler! Portföyünüz enflasyonun üzerinde getiri sağladı." : "⚠️ Portföyünüz henüz yıllık enflasyon oranını yakalayamadı.", style: TextStyle(color: enflasyonuEzdi ? PortfolioTheme.green : Colors.white38, fontSize: 10, height: 1.3)),
      ]),
    );
  }

  Widget _kiyaslamaBar(String baslik, double oran, Color barColor) {
    final double normalizeVal = (oran.abs() / 100.0).clamp(0.05, 1.0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(baslik, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        Text("%${oran.toStringAsFixed(1)}", style: TextStyle(color: barColor, fontSize: 10, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: normalizeVal, minHeight: 5, color: barColor, backgroundColor: Colors.white10)),
    ]);
  }
}