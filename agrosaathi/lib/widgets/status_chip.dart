import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/localization_service.dart';

/// Reusable status badge / chip for Risk Level, Water Requirement, Match Score, etc.
class StatusChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;

  const StatusChip({
    super.key,
    required this.label,
    this.icon,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
  });

  factory StatusChip.risk(String riskLevel) {
    Color bg;
    Color fg;
    IconData ic;
    String displayLabel;

    switch (riskLevel.toLowerCase()) {
      case 'low':
        bg = AppColors.primaryLight;
        fg = AppColors.riskLow;
        ic = Icons.shield_outlined;
        displayLabel = LocalizationService.tr('risk_low');
        break;
      case 'medium':
        bg = const Color(0xFFFFF3E0);
        fg = AppColors.riskMedium;
        ic = Icons.warning_amber_outlined;
        displayLabel = LocalizationService.tr('risk_medium');
        break;
      case 'high':
      default:
        bg = AppColors.warningLight;
        fg = AppColors.riskHigh;
        ic = Icons.error_outline;
        displayLabel = LocalizationService.tr('risk_high');
        break;
    }

    return StatusChip(
      label: displayLabel,
      icon: ic,
      backgroundColor: bg,
      textColor: fg,
      borderColor: fg.withValues(alpha: 0.3),
    );
  }

  factory StatusChip.water(String waterNeed) {
    String displayWater;
    switch (waterNeed.toLowerCase()) {
      case 'low':
        displayWater = LocalizationService.tr('water_low');
        break;
      case 'high':
        displayWater = LocalizationService.tr('water_high');
        break;
      case 'medium':
      default:
        displayWater = LocalizationService.tr('water_medium');
        break;
    }

    return StatusChip(
      label: displayWater,
      icon: Icons.water_drop_outlined,
      backgroundColor: AppColors.accentLight,
      textColor: AppColors.accent,
      borderColor: AppColors.accent.withValues(alpha: 0.3),
    );
  }

  factory StatusChip.score(int score) {
    final isHigh = score >= 80;
    return StatusChip(
      label: '$score% Match',
      icon: isHigh ? Icons.check_circle_outline : Icons.info_outline,
      backgroundColor: isHigh ? AppColors.primaryLight : const Color(0xFFFFF8E1),
      textColor: isHigh ? AppColors.primaryDark : AppColors.secondary,
      borderColor: isHigh ? AppColors.primary : AppColors.secondary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: borderColor != null ? Border.all(color: borderColor!, width: 1) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
