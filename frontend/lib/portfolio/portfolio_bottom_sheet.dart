import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; // ChangeNotifier kullanımı için
import 'package:trading_bot_app/models/portfolio_item.dart';
import 'package:trading_bot_app/portfolio/widgets/portfolio_controller.dart';
import 'package:trading_bot_app/portfolio/widgets/portfolio_theme.dart';
import 'package:trading_bot_app/portfolio/widgets/portfolio_widgets.dart';


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

  Widget _buildHeaderBar(PortfolioController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(children: [
            Icon(Icons.pie_chart_outline_rounded, color: PortfolioTheme.cyan, size: 20),
            SizedBox(width: 8),
            Text("Portföy Terminali", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          ]),
          IconButton(icon: const Icon(Icons.add_circle_outline_rounded, color: PortfolioTheme.cyan), onPressed: () => _showHisseEkleDialog(controller), tooltip: "Yeni Varlık Ekle"),
        ],
      ),
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

   void _showHisseEkleDialog(PortfolioController controller) {
    // Geçerli semboller listesi (Widget'a parametre olarak gelen anlık fiyatlar haritasından alınır)
    final List<String> gecerliSemboller = widget.anlikFiyatlar.keys.toList();
    
    final lotCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String? selectedSymbol; // Seçilen geçerli sembolü tutmak için

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PortfolioTheme.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: PortfolioTheme.border),
        ),
        title: const Text(
          "Portföye Ekle", 
          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)
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
                final aranan = textEditingValue.text.toUpperCase();
                return gecerliSemboller.where((sembol) => sembol.contains(aranan));
              },
              onSelected: (String secim) {
                selectedSymbol = secim;
              },
              fieldViewBuilder: (context, textEditingController, focusNode, onEditingComplete) {
                // Kullanıcı elle yazdığında da anlık olarak geçerli bir sembol mü kontrol et
                textEditingController.addListener(() {
                  final currentText = textEditingController.text.toUpperCase();
                  if (gecerliSemboller.contains(currentText)) {
                    selectedSymbol = currentText;
                  } else {
                    selectedSymbol = null; // Tam eşleşme yoksa geçersiz say
                  }
                });

                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Sembol Ara (örn: THYAO)",
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
                    elevation: 4,
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 180, maxWidth: 260),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          return ListTile(
                            dense: true,
                            title: Text(
                              option, 
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
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

            // --- 2. LOT MİKTARI ---
            TextField(
              controller: lotCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                // Sadece rakam, tek bir nokta (.) veya tek bir virgül (,) girilmesine izin verir
                FilteringTextInputFormatter.allow(RegExp(r'^[0-9]*[.,]?[0-9]*$')),
              ],
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Lot / Adet",
                labelStyle: TextStyle(color: Colors.white38, fontSize: 12),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            // --- 3. ALIŞ FİYATI ---
            TextField(
              controller: priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                // Sadece rakam, tek bir nokta (.) veya tek bir virgül (,) girilmesine izin verir
                FilteringTextInputFormatter.allow(RegExp(r'^[0-9]*[.,]?[0-9]*$')),
              ],
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Alış Fiyatı (Maliyet ₺)",
                labelStyle: TextStyle(color: Colors.white38, fontSize: 12),
                border: OutlineInputBorder(),
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
              // Virgülü noktaya çevirerek parse et
              final lot = double.tryParse(lotCtrl.text.replaceAll(',', '.')) ?? 0.0;
              final prc = double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0.0;
              
              // Autocomplete alanındaki son geçerli değeri al
              final sym = selectedSymbol?.trim().toUpperCase() ?? "";

              // --- KRİTİK DOĞRULAMA (VALIDATION) ---
              if (sym.isEmpty || !gecerliSemboller.contains(sym)) {
                Navigator.pop(ctx); // Dialog'u kapat
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⚠️ Lütfen listeden geçerli bir hisse/fon seçin!'),
                    backgroundColor: PortfolioTheme.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              if (lot <= 0 || prc <= 0) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⚠️ Lot ve fiyat değerleri 0\'dan büyük olmalıdır.'),
                    backgroundColor: PortfolioTheme.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              // Tüm kontroller geçtiyse backend'e gönder
              Navigator.pop(ctx);
              await controller.addItem(sym, lot, prc);
              
              // Başarı mesajı (Opsiyonel)
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ $sym başarıyla eklendi.'),
                    backgroundColor: PortfolioTheme.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text("Kaydet", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}