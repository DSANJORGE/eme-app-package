import 'package:flutter_eme_base/l10n/app_localizations.dart';
import 'package:flutter_eme_base/providers/workspace_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_eme_base/models/topic.dart';
import 'package:flutter_eme_base/widgets/common_widgets.dart';
import 'package:transparent_image/transparent_image.dart';

import '../screens/topic_tutorials_screen.dart';

class TopicCard extends ConsumerWidget {
  final Topic topic;
  final bool isClickable;

  const TopicCard({
    super.key,
    required this.topic,
    this.isClickable = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final mainColor = const Color(0xFF38B6FF);
    ref.watch(localeProvider);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isClickable
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TopicTutorialsScreen(topic: topic),
                  ),
                );
              }
            : null,
        borderRadius: BorderRadius.circular(16),
        splashColor: mainColor.withValues(alpha: 0.1),
        highlightColor: mainColor.withValues(alpha: 0.05),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFF161C24).withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail on the left
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Container(
                      width: 120,
                      height: 120,
                      clipBehavior: Clip.hardEdge,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      child: FadeInImage.memoryNetwork(
                        placeholder: kTransparentImage,
                        image: topic.thumbnail,
                        imageErrorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey,
                            child: const Icon(
                              Icons.error,
                              color: Colors.white,
                            ),
                          );
                        },
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Title, Subtitle, Progress and Stat
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        right: 8,
                        top: 8,
                        bottom: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topic.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.tutorialsCount(
                              topic.totalTutorials.toString(),
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white60,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            topic.description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Text(
                              l10n.averageRank.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            CommonWidgets.buildCompetenceBadge(
                              efficiency: topic.progress.getEfficiency(),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            CommonWidgets.buildProgressColumn(
                              topic.progress,
                              Efficiency.beginner,
                            ),
                            const SizedBox(width: 16),
                            CommonWidgets.buildProgressColumn(
                              topic.progress,
                              Efficiency.competent,
                            ),
                            const SizedBox(width: 16),
                            CommonWidgets.buildProgressColumn(
                              topic.progress,
                              Efficiency.expert,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.answersForgottenSummary(
                        topic.answersForgotten.toStringAsFixed(2),
                        topic.forgottenPeriod.toString(),
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
      ),
    );
  }
}

