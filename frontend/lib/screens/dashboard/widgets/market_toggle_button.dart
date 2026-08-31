import 'package:flutter/material.dart';

class MarketToggleButton extends StatelessWidget {
  final bool isActive;
  final Color activeColor;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isAction;

  const MarketToggleButton({
    super.key,
    required this.isActive,
    required this.activeColor,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isAction = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: isAction ? 0 : 8,
        right: isAction ? 8 : 0,
        top: 6,
        bottom: 6,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: isActive
                  ? activeColor.withValues(alpha: .12)
                  : colorScheme.surfaceContainerHigh,
              border: Border.all(
                color: isActive ? activeColor : colorScheme.outlineVariant,
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                AnimatedAlign(
                  curve: Curves.easeInOut,
                  duration: const Duration(milliseconds: 300),
                  alignment: isActive ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 30,
                    height: 30,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? activeColor : colorScheme.outline,
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: isActive
                          ? colorScheme.surface
                          : colorScheme.surfaceContainerHigh,
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: isActive ? 0 : 25,
                      right: isActive ? 25 : 0,
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isActive ? activeColor : colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}