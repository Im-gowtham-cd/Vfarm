import 'package:flutter/material.dart';
import 'package:vfarm/home.dart';
import 'package:vfarm/l10n/app_localizations.dart';

class AskExpertScreen extends StatelessWidget {
  const AskExpertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return MainWrapper(
      currentRoute: '/askExpert',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.question_answer,
              size: 64,
              color: Color(0xFF0A9D88),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.askExpert,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.professionalFarmingAdvice,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
