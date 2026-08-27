import 'package:flutter/material.dart';
import 'package:eme_app_package/l10n/app_localizations.dart';
import 'package:eme_app_package/models/topic.dart';
import 'package:eme_app_package/widgets/common_widgets.dart';

import '../models/tutorial.dart';
import '../screens/rehearse_screen.dart';

class TutorialCard extends StatefulWidget {
  final Tutorial tutorial;
  final bool isListMode;

  const TutorialCard({
    super.key,
    required this.tutorial,
    this.isListMode = false,
  });

  @override
  State<TutorialCard> createState() => _TutorialCardState();
}

class _TutorialCardState extends State<TutorialCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusColor = widget.tutorial.progress.getStatusColor();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161C24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.white.withValues(alpha: 0.05),
              padding: EdgeInsets.all(12),
              child: Text(
                widget.tutorial.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 4),
                  CommonWidgets.buildCompetenceBadge(
                    efficiency: widget.tutorial.progress.getEfficiency(),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            CommonWidgets.buildProgressColumn(
                              widget.tutorial.progress,
                              Efficiency.beginner,
                              l10n,
                            ),
                            const SizedBox(width: 16),
                            CommonWidgets.buildProgressColumn(
                              widget.tutorial.progress,
                              Efficiency.competent,
                              l10n,
                            ),
                            const SizedBox(width: 16),
                            CommonWidgets.buildProgressColumn(
                              widget.tutorial.progress,
                              Efficiency.expert,
                              l10n,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RehearseScreen(
                                      tutorial: widget.tutorial,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: statusColor.withValues(
                                  alpha: 0.15,
                                ),
                                foregroundColor: statusColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: statusColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                widget.tutorial.progress.getEfficiency() ==
                                        Efficiency.expert
                                    ? l10n.refresh
                                    : l10n.improve,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.answersForgottenSummary(
                      widget.tutorial.answersForgotten.toStringAsFixed(2),
                      widget.tutorial.forgottenPeriod.toString(),
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
