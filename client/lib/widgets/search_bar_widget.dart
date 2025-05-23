import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/theme_utils.dart';
import '../utils/design_system.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: DS.buttonHeightXl,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(DS.borderRadiusFull),
        border: Border.all(
          color: context.colorScheme.outline,
          width: 1.0,
        ),
        boxShadow: context.cardShadow,
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context).search,
          hintStyle: TextStyle(
            color: context.onSurfaceVariantColor,
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: context.onSurfaceVariantColor,
            size: DS.iconSizeS,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: DS.spacingM,
            vertical: DS.spacingM,
          ),
        ),
        style: TextStyle(
          color: context.onSurfaceColor,
          fontSize: 16,
        ),
      ),
    );
  }
}
