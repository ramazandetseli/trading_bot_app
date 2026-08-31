import 'package:flutter/material.dart';
import 'package:trading_bot_app/models/fon_model.dart';
import 'package:trading_bot_app/screens/fon/fon_detay_screen.dart';
import 'package:trading_bot_app/screens/fon/widgets/fon_card.dart';

class FonListView extends StatelessWidget {
  final bool isLoading;
  final List<FonOzetModel> displayFonlar;
  final Future<void> Function() onRefresh;

  const FonListView({
    super.key,
    required this.isLoading,
    required this.displayFonlar,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: colorScheme.primary));
    }

    if (displayFonlar.isEmpty) {
      return Center(
        child: Text(
          'Eşleşen fon bulunamadı.',
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
        itemCount: displayFonlar.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final fon = displayFonlar[index];
          
          return RepaintBoundary(
            key: ValueKey(fon.kod),
            child: FonCard(
              fon: fon,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FonDetayScreen(fonKodu: fon.kod),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}