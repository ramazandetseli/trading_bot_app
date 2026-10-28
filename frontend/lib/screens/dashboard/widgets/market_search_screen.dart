import 'package:flutter/material.dart';
import 'package:trading_bot_app/models/hisse_model.dart';
import 'package:trading_bot_app/screens/hisse/stock_detail_screen.dart'; // Hisse detay ekranı import yolu

class MarketSearchScreen extends StatefulWidget {
  final List<Hissemodel> hisseler;
  final List<dynamic> rawHisseResults; // Ham JSON listesi eklendi

  const MarketSearchScreen({
    super.key,
    required this.hisseler,
    required this.rawHisseResults,
  });

  @override
  State<MarketSearchScreen> createState() => _MarketSearchScreenState();
}

class _MarketSearchScreenState extends State<MarketSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Hissemodel> _filtrelenenHisseler = [];

  @override
  void initState() {
    super.initState();
    _filtrelenenHisseler = widget.hisseler;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtrelenenHisseler = widget.hisseler;
      } else {
        _filtrelenenHisseler = widget.hisseler.where((hisse) {
          return hisse.symbol.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Üst Search Bar & Geri Butonu
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'Hisse sembolü ara (THYAO, EREGL)...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () => _searchController.clear(),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Sonuç Listesi
            Expanded(
              child: _filtrelenenHisseler.isEmpty
                  ? Center(
                      child: Text(
                        'Sonuç bulunamadı.',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _filtrelenenHisseler.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                      ),
                      itemBuilder: (context, index) {
                        final hisse = _filtrelenenHisseler[index];
                        final fiyat = hisse.price.toString();
                        final degisim = hisse.change.toString();
                        final isPozitif = !degisim.startsWith('-');

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                            child: Text(
                              hisse.symbol.take(2),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          title: Text(
                            hisse.symbol,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₺$fiyat',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                degisim.contains('%') ? degisim : '%$degisim',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isPozitif
                                      ? const Color(0xFF00E676)
                                      : const Color(0xFFFF5252),
                                ),
                              ),
                            ],
                          ),
                          // 🔥 Detay sayfasına geçiş burada yapılıyor
                          onTap: () {
                            final rawHisse = widget.rawHisseResults.firstWhere(
                              (r) => r['symbol']?.toString().toUpperCase() == hisse.symbol.toUpperCase(),
                              orElse: () => null,
                            );

                            if (rawHisse != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => HisseDetayScreen(hisse: rawHisse),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String take(int n) => length <= n ? this : substring(0, n);
}