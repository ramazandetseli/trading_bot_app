import 'dart:async';
import 'package:flutter/material.dart';

class CanliFiyatText extends StatefulWidget {
  final String fiyatMetni;
  final TextStyle? style;
  final TextAlign? textAlign;

  const CanliFiyatText({
    super.key,
    required this.fiyatMetni,
    this.style,
    this.textAlign,
  });

  @override
  State<CanliFiyatText> createState() => _CanliFiyatTextState();
}

class _CanliFiyatTextState extends State<CanliFiyatText> {
  Color? _flashColor;
  Color _bgFlashColor = Colors.transparent;
  Timer? _timer;

  // "₺6,486.15" veya "$102.40" gibi metinleri saf sayıya çevirir
  double _parseFiyat(String text) {
    String clean = text.replaceAll(RegExp(r'[^0-9.,-]'), '');
    if (clean.contains(',') && clean.contains('.')) {
      if (clean.lastIndexOf(',') > clean.lastIndexOf('.')) {
        clean = clean.replaceAll('.', '').replaceAll(',', '.');
      } else {
        clean = clean.replaceAll(',', '');
      }
    } else if (clean.contains(',')) {
      clean = clean.replaceAll(',', '.');
    }
    return double.tryParse(clean) ?? 0.0;
  }

  @override
  void didUpdateWidget(covariant CanliFiyatText oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.fiyatMetni != widget.fiyatMetni) {
      final eski = _parseFiyat(oldWidget.fiyatMetni);
      final yeni = _parseFiyat(widget.fiyatMetni);

      if (eski != 0.0 && yeni != 0.0 && eski != yeni) {
        final yukseldi = yeni > eski;
        final renk = yukseldi ? const Color(0xFF00E676) : const Color(0xFFFF3D00);

        setState(() {
          _flashColor = renk;
          _bgFlashColor = renk.withValues(alpha: 0.18);
        });

        _timer?.cancel();
        _timer = Timer(const Duration(milliseconds: 650), () {
          if (mounted) {
            setState(() {
              _flashColor = null;
              _bgFlashColor = Colors.transparent;
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = widget.style ?? const TextStyle();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: _bgFlashColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 250),
        style: baseStyle.copyWith(
          color: _flashColor ?? baseStyle.color,
        ),
        child: Text(
          widget.fiyatMetni,
          textAlign: widget.textAlign,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}