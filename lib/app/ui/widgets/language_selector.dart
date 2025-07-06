import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/language_controller.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();

    return GetBuilder<LanguageController>(
      builder: (controller) => PopupMenuButton(
        onSelected: (value) {
          switch (value) {
            case 'en_US':
              controller.changeLanguage('en', 'US');
              break;
            case 'ar':
              controller.changeLanguage('ar', null);
              break;
            case 'fr_FR':
              controller.changeLanguage('fr', 'FR');
              break;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'en_US',
            child: _buildLanguageItem(
              'English',
              controller.currentLocale.languageCode == 'en',
            ),
          ),
          PopupMenuItem(
            value: 'ar',
            child: _buildLanguageItem(
              'العربية',
              controller.currentLocale.languageCode == 'ar',
            ),
          ),
          PopupMenuItem(
            value: 'fr_FR',
            child: _buildLanguageItem(
              'Français',
              controller.currentLocale.languageCode == 'fr',
            ),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language),
              const SizedBox(width: 4),
              Text(_getLanguageText(controller.currentLocale.languageCode)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageItem(String text, bool isSelected) {
    return Row(
      children: [
        Text(text),
        if (isSelected) ...[
          const SizedBox(width: 8),
          const Icon(Icons.check, color: Colors.green),
        ],
      ],
    );
  }

  String _getLanguageText(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      case 'fr':
        return 'Français';
      default:
        return 'English';
    }
  }
}
