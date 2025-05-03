import 'package:flutter/material.dart';
import 'colors.dart';

@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color? cardGradientStart;
  final Color? cardGradientEnd;
  final Color? interviewGradientStart;
  final Color? interviewGradientEnd;
  final Color? successColor;
  final Color? warningColor;
  final List<BoxShadow>? cardShadow;

  const AppThemeExtension({
    required this.cardGradientStart,
    required this.cardGradientEnd,
    required this.interviewGradientStart,
    required this.interviewGradientEnd,
    required this.successColor,
    required this.warningColor,
    required this.cardShadow,
  });

  // Light theme extension
  static const light = AppThemeExtension(
    cardGradientStart: AppColors.cardGradientStart,
    cardGradientEnd: AppColors.cardGradientEnd,
    interviewGradientStart: AppColors.interviewGradientStart,
    interviewGradientEnd: AppColors.interviewGradientEnd,
    successColor: AppColors.success,
    warningColor: AppColors.warning,
    cardShadow: [
      BoxShadow(
        color: Color(0x0A000000),
        blurRadius: 4,
        offset: Offset(0, 2),
      ),
    ],
  );

  // Dark theme extension
  static const dark = AppThemeExtension(
    cardGradientStart: AppColors.cardGradientStartDark,
    cardGradientEnd: AppColors.cardGradientEndDark,
    interviewGradientStart: AppColors.interviewGradientStartDark,
    interviewGradientEnd: AppColors.interviewGradientEndDark,
    successColor: AppColors.successDark,
    warningColor: AppColors.warningDark,
    cardShadow: [
      BoxShadow(
        color: Color(0x1AFFFFFF),
        blurRadius: 4,
        offset: Offset(0, 2),
      ),
    ],
  );

  @override
  AppThemeExtension copyWith({
    Color? cardGradientStart,
    Color? cardGradientEnd,
    Color? interviewGradientStart,
    Color? interviewGradientEnd,
    Color? successColor,
    Color? warningColor,
    List<BoxShadow>? cardShadow,
  }) {
    return AppThemeExtension(
      cardGradientStart: cardGradientStart ?? this.cardGradientStart,
      cardGradientEnd: cardGradientEnd ?? this.cardGradientEnd,
      interviewGradientStart: interviewGradientStart ?? this.interviewGradientStart,
      interviewGradientEnd: interviewGradientEnd ?? this.interviewGradientEnd,
      successColor: successColor ?? this.successColor,
      warningColor: warningColor ?? this.warningColor,
      cardShadow: cardShadow ?? this.cardShadow,
    );
  }

  @override
  AppThemeExtension lerp(AppThemeExtension? other, double t) {
    if (other is! AppThemeExtension) return this;
    
    return AppThemeExtension(
      cardGradientStart: Color.lerp(cardGradientStart, other.cardGradientStart, t),
      cardGradientEnd: Color.lerp(cardGradientEnd, other.cardGradientEnd, t),
      interviewGradientStart: Color.lerp(interviewGradientStart, other.interviewGradientStart, t),
      interviewGradientEnd: Color.lerp(interviewGradientEnd, other.interviewGradientEnd, t),
      successColor: Color.lerp(successColor, other.successColor, t),
      warningColor: Color.lerp(warningColor, other.warningColor, t),
      cardShadow: t < 0.5 ? cardShadow : other.cardShadow,
    );
  }
}
