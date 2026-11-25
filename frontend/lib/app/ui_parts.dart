import 'package:flutter/material.dart';

import 'app_theme.dart';

/// A rounded chip with a calendar icon for a day or an Earning Window; tappable when [onTap] is set.
/// [accent] draws it in the brand blue, for a chip that is a filter rather than a link.
class CalendarChip extends StatelessWidget {
  const CalendarChip({super.key, required this.label, this.onTap, this.accent = false, this.height = 32});

  final String label;
  final VoidCallback? onTap;
  final bool accent;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final foreground = accent ? colors.accent : colors.text;
    final shape = StadiumBorder(side: BorderSide(color: accent ? colors.accent : colors.chipBorder));
    return Material(
      color: colors.card,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: foreground),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: foreground, fontFeatures: tabularFigures),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small rounded label, green with a check mark for something covered.
class CoveredChip extends StatelessWidget {
  const CoveredChip({super.key, this.label = 'Pokrytý'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: colors.earnedContainer, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, size: 12, color: colors.earned),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.earned)),
        ],
      ),
    );
  }
}
