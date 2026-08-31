import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AlarmCard extends StatelessWidget {
  final Map<String, dynamic> alarm;
  final VoidCallback onSil;
  final Function(String yeniFiyat) onGuncelle;

  const AlarmCard({
    super.key,
    required this.alarm,
    required this.onSil,
    required this.onGuncelle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final symbol = alarm["symbol"] ?? "Belirsiz";
    final targetPrice = alarm['target_price']?.toString() ?? "0.0";
    final currentPrice = double.tryParse(alarm['current_price']?.toString() ?? "0") ?? 0.0;
    final target = double.tryParse(targetPrice) ?? 0.0;
    final yukselisBekleniyor = target >= currentPrice;
    final yonRengi = yukselisBekleniyor ? colorScheme.primary : Colors.redAccent;

    return Dismissible(
      key: ValueKey('alarm_$symbol'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        onSil();
        return false;
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: yonRengi.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                yukselisBekleniyor ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                color: yonRengi,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(symbol, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colorScheme.onSurface)),
                  const SizedBox(height: 3),
                  Text(
                    "Hedef ${yukselisBekleniyor ? '>' : '<'} $targetPrice ₺",
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit_rounded, color: colorScheme.onSurfaceVariant, size: 19),
              onPressed: () => _duzenleDialogGoster(context, symbol, targetPrice),
            ),
          ],
        ),
      ),
    );
  }

  void _duzenleDialogGoster(BuildContext context, String symbol, String mevcutFiyat) {
    final colorScheme = Theme.of(context).colorScheme;
    TextEditingController editController = TextEditingController(text: mevcutFiyat);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("$symbol Düzenle", style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
        content: TextField(
          maxLength: 7,
          controller: editController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: "Yeni Hedef Fiyat",
            labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colorScheme.outline)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colorScheme.primary, width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("İptal", style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              onGuncelle(editController.text);
            },
            child: const Text("Güncelle"),
          ),
        ],
      ),
    );
  }
}