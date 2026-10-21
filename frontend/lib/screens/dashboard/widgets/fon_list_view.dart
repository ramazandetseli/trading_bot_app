import 'package:flutter/material.dart';
import 'package:trading_bot_app/models/fon_model.dart';
import 'package:trading_bot_app/screens/fon/fon_detay_screen.dart';
import 'package:trading_bot_app/screens/fon/widgets/fon_card.dart';

class FonListView extends StatelessWidget {
  final bool isLoading;
  final List<FonOzetModel> displayFonlar;
  final String? errorMessage;
  final Future<void> Function() onRefresh;

  const FonListView({
    super.key,
    required this.isLoading,
    required this.displayFonlar,
    this.errorMessage,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: colorScheme.primary));
    }

    if (errorMessage != null && displayFonlar.isEmpty) {
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