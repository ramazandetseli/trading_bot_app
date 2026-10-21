import 'package:flutter/material.dart';
import 'package:trading_bot_app/models/hisse_model.dart';
import 'package:trading_bot_app/screens/hisse/widgets/hisse_card.dart';
import 'package:trading_bot_app/screens/hisse/stock_detail_screen.dart';

class HisseListView extends StatelessWidget {
  final bool isLoading;
  final List<Hissemodel> displayHisseler;
  final List<dynamic> rawHisseResults;
  final Set<String> favoriHisseler;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final Function(String) onFavoriDegisti;

  const HisseListView({
    super.key,
    required this.isLoading,
    required this.displayHisseler,
    required this.rawHisseResults,
    required this.favoriHisseler,
    this.errorMessage,
    required this.onRefresh,
    required this.onFavoriDegisti,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: colorScheme.primary));
    }



    // 1. DURUM: Gerçek bir bağlantı / sunucu hatası varsa -> Tekrar Dene Butonu Çıksın
    if (errorMessage != null && displayHisseler.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 54, color: Colors.orangeAccent),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text("Tekrar Dene"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }


    
    return RefreshIndicator(
      color: colorScheme.primary,
      backgroundColor: colorScheme.surfaceContainerHigh,
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        itemCount: displayHisseler.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final model = displayHisseler[index];
          final isFav = favoriHisseler.contains(model.symbol);

          return RepaintBoundary(
            key: ValueKey(model.symbol),
            child: HisseCard(
              hisse: model,
              isFav: isFav,
              onTap: () {
                final rawHisse = rawHisseResults.firstWhere(
                  (r) => r['symbol'] == model.symbol,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HisseDetayScreen(hisse: rawHisse),
                  ),
                );
              },
              onFavoriDegisti: () => onFavoriDegisti(model.symbol),
            ),
          );
        },
      ),
    );
  }
}