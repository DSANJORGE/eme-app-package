import 'package:flutter/material.dart';
import 'package:flutter_eme_base/models/topic.dart';
import 'package:flutter_eme_base/models/tutorial.dart';

class CommonWidgets {
  static Future<void> showInfoDialog({
    required BuildContext context,
    required String title,
    required Widget description,
    String? buttonText,
  }) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(children: <Widget>[description]),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(buttonText ?? 'OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static Widget buildCompetenceBadge({required Efficiency efficiency}) {
    Color color;
    IconData icon;
    if (efficiency == Efficiency.beginner) {
      color = const Color(0xFFF50057);
      icon = Icons.local_florist;
    } else if (efficiency == Efficiency.competent) {
      color = const Color(0xFF2196F3);
      icon = Icons.stars;
    } else {
      color = const Color(0xFF38EF7D);
      icon = Icons.emoji_events;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              efficiency.name.toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Widget buildProgressColumn(
    TutorialProgress progress,
    Efficiency efficiency,
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
          efficiency.name.toUpperCase(),
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
