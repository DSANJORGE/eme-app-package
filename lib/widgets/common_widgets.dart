import 'package:flutter/material.dart';
import 'package:eme_app_package/l10n/app_localizations.dart';
import 'package:eme_app_package/models/topic.dart';
import 'package:eme_app_package/models/tutorial.dart';

class CommonWidgets {
  static Widget buildProgressColumn(
    TutorialProgress progress,
    Efficiency efficiency,
    AppLocalizations l10n,
  ) {
    final double progressValue;
    if (efficiency == Efficiency.beginner) {
      progressValue = progress.beginnerProgress;
    } else if (efficiency == Efficiency.competent) {
      progressValue = progress.competentProgress;
    } else {
      progressValue = progress.expertProgress;
    }
    final Color statusColor;
    if (efficiency == Efficiency.beginner) {
      statusColor = const Color(0xFFF50057);
    } else if (efficiency == Efficiency.competent) {
      statusColor = const Color(0xFF2196F3);
    } else {
      statusColor = const Color(0xFF38EF7D);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          efficiency.getLabel(l10n),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            value: progressValue,
            strokeWidth: 3,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${(progressValue * 100).toInt()}%',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
