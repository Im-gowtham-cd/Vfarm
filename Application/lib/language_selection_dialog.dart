import 'package:flutter/material.dart';
import 'package:vfarm/locale_manager.dart';
import 'package:vfarm/l10n/app_localizations.dart';

class LanguageSelectionDialog extends StatelessWidget {
  final VoidCallback? onLanguageChanged;

  const LanguageSelectionDialog({super.key, this.onLanguageChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeManager = LocaleManager.instance;

    return AlertDialog(
      title: Text(l10n.settings),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select Language / भाषा चुनें / Seleccionar idioma',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          ...localeManager.supportedLocales.map((locale) {
            return ListTile(
              title: Text(
                localeManager.getLocaleDisplayName(locale.languageCode),
              ),
              trailing:
                  localeManager.currentLocale.languageCode ==
                          locale.languageCode
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
              onTap: () async {
                await localeManager.changeLocale(locale);
                onLanguageChanged?.call();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            );
          }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}

// Helper function to show language selection dialog
void showLanguageSelectionDialog(
  BuildContext context, {
  VoidCallback? onLanguageChanged,
}) {
  showDialog(
    context: context,
    builder:
        (context) =>
            LanguageSelectionDialog(onLanguageChanged: onLanguageChanged),
  );
}
