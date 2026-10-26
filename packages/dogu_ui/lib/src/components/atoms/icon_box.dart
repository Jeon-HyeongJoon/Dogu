import 'package:flutter/material.dart';

import '../atoms/badge_pill.dart';
import '../../tokens/tokens.dart';

class IconBox extends StatelessWidget {
  const IconBox({
    required this.icon,
    required this.label,
    this.inverted = false,
    this.count,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool inverted;
  final String? count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: inverted ? AppColors.accent : AppColors.bg,
                  border: Border.all(color: inverted ? AppColors.accent : AppColors.line),
                ),
                child: Icon(icon, size: 18, color: inverted ? AppColors.invert : AppColors.ink),
              ),
              if (count != null)
                Positioned(
                  top: -5,
                  right: -1,
                  child: BadgePill(text: count!, color: AppColors.alert, compact: true),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
