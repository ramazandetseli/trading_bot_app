import 'package:flutter/material.dart';

class MarketSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;

  const MarketSearchBar({
    super.key,
    required this.controller,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: .4)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: .12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final hasText = value.text.isNotEmpty;
            return TextField(
              controller: controller,
              style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
              decoration: InputDecoration(
                border: InputBorder.none,
                prefixIcon: Icon(
                  Icons.search,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                hintText: 'Arama yap',
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: .7),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                suffixIcon: hasText
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: colorScheme.onSurfaceVariant,
                          size: 18,
                        ),
                        onPressed: onClear,
                      )
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }
}