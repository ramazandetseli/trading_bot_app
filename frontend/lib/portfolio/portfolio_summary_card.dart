import 'package:flutter/material.dart';
import 'package:trading_bot_app/models/portfolio_item.dart';
import 'package:trading_bot_app/portfolio/portfolio_bottom_sheet.dart';
import 'package:trading_bot_app/services/portfolio_service.dart';

class PortfolioSummaryCard extends StatefulWidget {
  final String userId;
  final Map<String, double> anlikFiyatlar;

  const PortfolioSummaryCard({
    super.key,
    required this.userId,
    required this.anlikFiyatlar,
  });

  @override
  State<PortfolioSummaryCard> createState() => _PortfolioSummaryCardState();
}

class _PortfolioSummaryCardState extends State<PortfolioSummaryCard> {
  bool _yukleniyor = true;
  List<PortfolioItem> _items = [];

  static const Color _cardBg = Color(0xFF0D1420);
  static const Color _border = Color(0xFF1E293B);
  static const Color _cyan = Color(0xFF00D4FF);
  static const Color _green = Color(0xFF00E676);
  static const Color _red = Color(0xFFFF5252);

  @override
  void initState() {
    super.initState();
    _ozetVerisiniCek();
  }

  @override
  void didUpdateWidget(covariant PortfolioSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.anlikFiyatlar != widget.anlikFiyatlar) {
      _fiyatlariGuncelle();
    }
  }

  Future<void> _ozetVerisiniCek() async {
    final veriler = await PortfolioService.fetchPortfolio(widget.userId);
    if (!mounted) return;

    for (var item in veriler) {
      if (widget.anlikFiyatlar.containsKey(item.symbol)) {
        item.currentPrice = widget.anlikFiyatlar[item.symbol]!;
      }
    }

    setState(() {
      _items = veriler;
      _yukleniyor = false;
    });
  }

  void _fiyatlariGuncelle() {
    for (var item in _items) {
      if (widget.anlikFiyatlar.containsKey(item.symbol)) {
        item.currentPrice = widget.anlikFiyatlar[item.symbol]!;
      }
    }
    setState(() {});
  }

  double get _toplamMaliyet => _items.fold(0.0, (acc, item) => acc + item.totalCost);
  double get _toplamGuncelDeger => _items.fold(0.0, (acc, item) => acc + item.currentValue);
  double get _netKarZarar => _toplamGuncelDeger - _toplamMaliyet;
  double get _karZararYuzde =>
      _toplamMaliyet > 0 ? (_netKarZarar / _toplamMaliyet) * 100 : 0.0;

  @override
  Widget build(BuildContext context) {
    final bool isPositive = _netKarZarar >= 0;
    final Color statusColor = isPositive ? _green : _red;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await PortfolioBottomSheet.goster(
              context,
              userId: widget.userId,
              anlikFiyatlar: widget.anlikFiyatlar,
            );
            _ozetVerisiniCek();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: _yukleniyor
                ? const SizedBox(
                    height: 42,
                    child: Center(
                      child: SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: _cyan),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2254).withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF7C4DFF).withValues(alpha: 0.3)),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Color(0xFFB39DDB),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Portföy Değeri",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _items.isEmpty
                                  ? "₺0,00"
                                  : "₺${_toplamGuncelDeger.toStringAsFixed(2)}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_items.isNotEmpty) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                  color: statusColor,
                                  size: 15,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  "%${_karZararYuzde.abs().toStringAsFixed(2)}",
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${isPositive ? '+' : '-'}₺${_netKarZarar.abs().toStringAsFixed(2)}",
                              style: TextStyle(
                                color: statusColor.withValues(alpha: 0.85),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        const Text(
                          "Varlık Ekle",
                          style: TextStyle(color: _cyan, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right_rounded, color: Colors.white30, size: 20),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}