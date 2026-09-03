import 'package:flutter/material.dart';
import 'package:eme_app_package/l10n/app_localizations.dart';
import '../models/daily_challenge.dart';

class DailyChallengeSection extends StatelessWidget {
  final List<DailyChallengeItem> challenges;
  final Function(DailyChallengeItem item) onChallengeCompleted;

  const DailyChallengeSection({
    super.key,
    required this.challenges,
    required this.onChallengeCompleted,
  });

  DailyChallengeItem get todayChallenge {
    return challenges.firstWhere(
      (c) => c.isToday,
      orElse: () =>
          challenges.isNotEmpty ? challenges.last : _generateFallbackToday(),
    );
  }

  List<DailyChallengeItem> get pastDaysChallenges {
    return challenges.where((c) => !c.isToday).toList();
  }

  static DailyChallengeItem _generateFallbackToday() {
    final now = DateTime.now();
    return DailyChallengeItem(
      id: 'today',
      date: now,
      dayLabel: 'Today',
      dateLabel: '${now.month}/${now.day}',
      title: 'Sunday, August 23',
      totalQuestions: 20,
      completedQuestions: 3,
      isToday: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final today = todayChallenge;
    // final pastDays = pastDaysChallenges;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9100).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: Color(0xFFFF9100),
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.dailyChallenge,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF9100),
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Today's Challenge (Hero Card with Large Circular Progress)
        _buildTodayChallengeCard(context, today, l10n),
        const SizedBox(height: 18),

        // Past 6 Days Row
        // if (pastDays.isNotEmpty) ...[
        //   Padding(
        //     padding: const EdgeInsets.only(left: 2, bottom: 10),
        //     child: Row(
        //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //       children: [
        //         Text(
        //           l10n.last6Days,
        //           style: const TextStyle(
        //             fontSize: 11,
        //             fontWeight: FontWeight.w600,
        //             color: Colors.white60,
        //             letterSpacing: 0.5,
        //           ),
        //         ),
        //         Text(
        //           l10n.tapToFinish,
        //           style: const TextStyle(
        //             fontSize: 10,
        //             color: Color(0xFFFF9100),
        //             fontWeight: FontWeight.w500,
        //           ),
        //         ),
        //       ],
        //     ),
        //   ),
        //   _buildPastDaysList(context, pastDays, l10n),
        // ],
      ],
    );
  }

  Widget _buildTodayChallengeCard(
    BuildContext context,
    DailyChallengeItem today,
    AppLocalizations l10n,
  ) {
    final isCompleted = today.isCompleted;
    final progressColor = isCompleted
        ? const Color(0xFF00E676)
        : const Color(0xFFFF9100);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("This feature is not yet implemented")),
          );
        },
        borderRadius: BorderRadius.circular(18),
        splashColor: progressColor.withValues(alpha: 0.1),
        highlightColor: progressColor.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF1A2230), const Color(0xFF121720)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isCompleted
                  ? const Color(0xFF00E676).withValues(alpha: 0.4)
                  : const Color(0xFFFF9100).withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isCompleted
                    ? const Color(0xFF00E676).withValues(alpha: 0.1)
                    : const Color(0xFFFF9100).withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Large Circular Progress Bar
              Column(
                children: [
                  _buildLargeCircularProgress(
                    today,
                    isCompleted,
                    progressColor,
                  ),
                  const SizedBox(height: 8),
                  Text('Sections Completed'),
                ],
              ),
              const SizedBox(width: 18),
              Container(color: Colors.white24, width: 1, height: 100),
              const SizedBox(width: 18),

              // Challenge Information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6F00), Color(0xFFFF9100)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.dailyChallenge,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLargeCircularProgress(
    DailyChallengeItem today,
    bool isCompleted,
    Color progressColor,
  ) {
    final percent = (today.progress * 100).round();

    return SizedBox(
      width: 82,
      height: 82,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Circle Track
          SizedBox(
            width: 82,
            height: 82,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 8,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          // Active Circular Progress Indicator
          SizedBox(
            width: 82,
            height: 82,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: today.progress),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return CircularProgressIndicator(
                  value: value,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                );
              },
            ),
          ),
          // Center Text or Checkmark
          if (isCompleted)
            AnimatedScale(
              scale: 1.0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(
                Icons.check_rounded,
                color: Color(0xFF00E676),
                size: 34,
              ),
            )
          else
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
                Text(
                  '${today.completedQuestions}/${today.totalQuestions}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
