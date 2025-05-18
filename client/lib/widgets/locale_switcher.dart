import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/locale_provider.dart';

class LocaleSwitcher extends StatelessWidget {
  const LocaleSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLocale = localeProvider.locale;
    
    return PopupMenuButton<Locale>(
      tooltip: 'Change language',
      icon: const Icon(Icons.language),
      onSelected: (Locale locale) {
        localeProvider.setLocale(locale);
      },
      itemBuilder: (context) => [
        _buildPopupMenuItem(
          const Locale('en'), 
          'English', 
          currentLocale.languageCode == 'en'
        ),
        _buildPopupMenuItem(
          const Locale('es'), 
          'Español', 
          currentLocale.languageCode == 'es'
        ),
      ],
    );
  }
  
  PopupMenuItem<Locale> _buildPopupMenuItem(
    Locale locale, 
    String title, 
    bool isSelected
  ) {
    return PopupMenuItem<Locale>(
      value: locale,
      child: Row(
        children: [
          if (isSelected) 
            const Icon(Icons.check, size: 18),
          if (isSelected) 
            const SizedBox(width: 8),
          Text(title),
        ],
      ),
    );
  }
}
