import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';

class BloodGroupBadge extends StatelessWidget {
  final String bloodGroup;
  final double size;
  final bool showLabel;

  const BloodGroupBadge({
    super.key,
    required this.bloodGroup,
    this.size = 56,
    this.showLabel = true,
  });

  Color get _color =>
      AppColors.bloodGroupColors[bloodGroup] ?? AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_color, _color.withValues(alpha: 0.7)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _color.withValues(alpha: 0.45),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              bloodGroup,
              style: AppTextStyles.bloodGroupLabel.copyWith(
                fontSize: size * 0.28,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 6),
          Text('Blood Type', style: AppTextStyles.caption),
        ],
      ],
    );
  }
}

/// Compact version used in lists
class BloodGroupChip extends StatelessWidget {
  final String bloodGroup;

  const BloodGroupChip({super.key, required this.bloodGroup});

  Color get _color =>
      AppColors.bloodGroupColors[bloodGroup] ?? AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.5)),
      ),
      child: Text(
        bloodGroup,
        style: AppTextStyles.labelMedium.copyWith(
          color: _color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
