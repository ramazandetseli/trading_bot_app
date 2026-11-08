import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; // ChangeNotifier kullanımı için
import 'package:trading_bot_app/portfolio/widgets/portfolio_controller.dart';
import 'package:trading_bot_app/portfolio/widgets/portfolio_theme.dart';
import 'package:trading_bot_app/portfolio/widgets/portfolio_widgets.dart';
import 'package:trading_bot_app/screens/dashboard/widgets/varlik_avatar.dart';


class PortfolioBottomSheet extends StatefulWidget {
  final String userId;
  final Map<String, double> anlikFiyatlar;

  const PortfolioBottomSheet({super.key, required this.userId, required this.anlikFiyatlar});

  static Future<void> goster(BuildContext context, {required String userId, required Map<String, double> anlikFiyatlar}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PortfolioBottomSheet(userId: userId, anlikFiyatlar: anlikFiyatlar),
    );
  }

  @override
  State<PortfolioBottomSheet> createState() => _PortfolioBottomSheetState();
}

class _PortfolioBottomSheetState extends State<PortfolioBottomSheet> {
  late final PortfolioController _controller;

  @override
  void initState() {
    super.initState();
    // Controller'ı başlatıyoruz, kendi içinde loadData() çağrılacak
    _controller = PortfolioController(userId: widget.userId, anlikFiyatlar: widget.anlikFiyatlar);
  }

  @override
  void dispose() {
    _controller.dispose(); // Memory leak önleme
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<PortfolioController>(
        builder: (context, controller, child) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.90,
            decoration: const BoxDecoration(
              color: PortfolioTheme.bg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: PortfolioTheme.border)),
            ),
            child: Column(
              children: [
                _buildDragHandle(),
                _buildHeaderBar(controller),
                const Divider(color: PortfolioTheme.border, height: 1),
                Expanded(
                  child: controller.isLoading
                      ? const Center(child: CircularProgressIndicator(color: PortfolioTheme.cyan))
                      : controller.items.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: controller.loadData,
                              color: PortfolioTheme.cyan,
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    PortfolioDistributionBar(
                                      items: controller.items,
                                      toplamGuncelDeger: controller.toplamGuncelDeger,
                                    ),
                                    const SizedBox(height: 14),
                                    PortfolioFinancialSummary(
                                      toplamMaliyet: controller.toplamMaliyet,
                                      toplamGuncelDeger: controller.toplamGuncelDeger,
                                      toplamNetKarZarar: controller.toplamNetKarZarar,
                                      toplamKarZararYuzde: controller.toplamKarZararYuzde,
                                    ),
                                    const SizedBox(height: 20),
                                    const Text("VARLIKLARIM", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                                    const SizedBox(height: 10),
                                    PortfolioAssetList(
                                      items: controller.items,
                                      onDelete: controller.deleteItem,
                                    ),
                                    const SizedBox(height: 20),
                                    PortfolioInflationComparison(
                                      portfoyGetirisi: controller.toplamKarZararYuzde,
                                    ),
                                    const SizedBox(height: 30),
                                  ],
                                ),
                              ),
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(margin: const EdgeInsets.only(top: 10, bottom: 6), width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.white24),
        const SizedBox(height: 12),
        const Text("Portföyünüzde henüz varlık yok.", style: TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: () => _showHisseEkleDialog(_controller),
          icon: const Icon(Icons.add, size: 16, color: Colors.black),
          label: const Text("İlk Varlığını Ekle", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(backgroundColor: PortfolioTheme.cyan, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        ),
      ]),
    );
  }

   Widget _buildHeaderBar(PortfolioController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart_outline_rounded, color: PortfolioTheme.cyan, size: 20),
              const SizedBox(width: 8),
              const Text(
                "Portföy Terminali",
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 10),
              // 👈 Canlı Dolar Kuru Rozeti
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  "1\$ = ₺${controller.usdTryKuru.toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 10.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: PortfolioTheme.cyan),
            onPressed: () => _showHisseEkleDialog(controller),
            tooltip: "Yeni Varlık Ekle",
          ),
        ],
      ),
    );
  }

  // Sembolün Dolar mı TL mi olduğunu anlayan yardımcı
  bool _sembolDolarMi(String sym) {
    final s = sym.toUpperCase().trim();
    const kriptolar = {'BTC', 'ETH', 'SOL', 'AVAX', 'XRP', 'DOGE', 'BNB', 'ADA', 'DOT', 'TRX', 'LINK', 'MATIC', 'NEAR', 'SUI', 'PEPE', 'SHIB'};
    const usHisseleri = {'AAPL', 'NVDA', 'TSLA', 'MSFT', 'AMZN', 'GOOGL', 'GOOG', 'META', 'SPY', 'QQQ', 'AMD', 'INTC', 'NFLX', 'COIN', 'PLTR', 'BABA', 'BRK.B'};
    return s.endsWith('USDT') || kriptolar.contains(s) || usHisseleri.contains(s);
  }

  void _showHisseEkleDialog(PortfolioController controller) {
    final List<String> gecerliSemboller = controller.guncelFiyatHavuzu.keys.toList();

    final lotCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String selectedSymbol = "";
    bool seciliDolarMi = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final birim = seciliDolarMi ? "\$" : "₺";
          final canliFiyat = controller.guncelFiyatHavuzu[selectedSymbol] ?? 0.0;

          return AlertDialog(
            backgroundColor: PortfolioTheme.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: PortfolioTheme.border),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Portföye Ekle",
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                if (selectedSymbol.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (seciliDolarMi ? Colors.orangeAccent : Colors.blueAccent).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      seciliDolarMi ? "USD (\$) Bazlı" : "TRY (₺) Bazlı",
                      style: TextStyle(
                        color: seciliDolarMi ? Colors.orangeAccent : Colors.blueAccent,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- 1. SEMBOL AUTOCOMPLETE ALANI ---
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    final aranan = textEditingValue.text.toUpperCase().trim();
                    return gecerliSemboller.where((s) => s.contains(aranan)).take(25);
                  },
                  onSelected: (String secim) {
                    setDialogState(() {
                      selectedSymbol = secim;
                      seciliDolarMi = _sembolDolarMi(secim);
                      // Seçilen varlığın güncel fiyatı varsa kutuya kolaylık olsun diye otomatik yaz
                      final anlik = controller.guncelFiyatHavuzu[secim] ?? 0.0;
                      if (anlik > 0 && priceCtrl.text.isEmpty) {
                        priceCtrl.text = anlik.toString();
                      }
                    });
                  },
                  fieldViewBuilder: (context, textEditingController, focusNode, onEditingComplete) {
                    return TextField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedSymbol = val.toUpperCase().trim();
                          seciliDolarMi = _sembolDolarMi(selectedSymbol);
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: "Sembol Ara (THYAO, BTCUSDT, AAPL)",
                        labelStyle: TextStyle(color: Colors.white38, fontSize: 12),
                        prefixIcon: Icon(Icons.search, color: Colors.white38, size: 18),
                        border: OutlineInputBorder(),
                      ),
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 8,
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(10),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200, maxWidth: 280),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              final isUsd = _sembolDolarMi(option);
                              final f = controller.guncelFiyatHavuzu[option] ?? 0.0;
                              return ListTile(
                                dense: true,
                                title: Text(
                                  option,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                trailing: Text(
                                  f > 0 ? "${isUsd ? '\$' : '₺'}${f.toStringAsFixed(2)}" : (isUsd ? "USD" : "TRY"),
                                  style: TextStyle(
                                    color: isUsd ? Colors.orangeAccent : Colors.greenAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // --- 2. LOT / ADET ---
                TextField(
                  controller: lotCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^[0-9]*[.,]?[0-9]*$')),
                  ],
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Lot / Adet (Örn: 10 veya 0.05)",
                    labelStyle: TextStyle(color: Colors.white38, fontSize: 12),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                // --- 3. ALIŞ FİYATI (DİNAMİK $ VEYA ₺ GÖSTERİR) ---
                TextField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^[0-9]*[.,]?[0-9]*$')),
                  ],
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Alış Fiyatı (Maliyet $birim)",
                    helperText: canliFiyat > 0
                        ? "Güncel Piyasa Fiyatı: $birim${canliFiyat.toStringAsFixed(2)}"
                        : null,
                    helperStyle: const TextStyle(color: PortfolioTheme.cyan, fontSize: 11),
                    labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("İptal", style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: PortfolioTheme.cyan),
                onPressed: () async {
                  final lot = double.tryParse(lotCtrl.text.replaceAll(',', '.')) ?? 0.0;
                  final prc = double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0.0;
                  final sym = selectedSymbol.trim().toUpperCase();

                  if (sym.length < 2) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('⚠️ Lütfen geçerli bir sembol girin!'),
                        backgroundColor: PortfolioTheme.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  if (lot <= 0 || prc <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('⚠️ Lot ve fiyat 0\'dan büyük olmalıdır.'),
                        backgroundColor: PortfolioTheme.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(ctx);
                  await controller.addItem(sym, lot, prc);
                },
                child: const Text("Kaydet", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }
}