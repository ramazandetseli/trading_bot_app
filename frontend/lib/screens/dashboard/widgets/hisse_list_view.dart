import 'package:flutter/material.dart';
import 'package:trading_bot_app/models/hisse_model.dart';
import 'package:trading_bot_app/screens/hisse/widgets/hisse_card.dart';
import 'package:trading_bot_app/screens/hisse/stock_detail_screen.dart';

class HisseListView extends StatelessWidget {
  final bool isLoading;
  final List<Hissemodel> displayHisseler;
  final List<dynamic> rawHisseResults;
  final Set<String> favoriHisseler;
  final Future<void> Function() onRefresh;
  final Function(String) onFavoriDegisti;

  const HisseListView({
    super.key,
    required this.isLoading,
    required this.displayHisseler,
    required this.rawHisseResults,
    required this.favoriHisseler,
    required this.onRefresh,
    required this.onFavoriDegisti,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: colorScheme.primary));
    }

    if (displayHisseler.isEmpty) {
      return Center(
        child: Text(
          'Eşleşen hisse bulunamadı.',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
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