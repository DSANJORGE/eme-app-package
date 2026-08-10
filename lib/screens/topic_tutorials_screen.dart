import 'dart:math' show min;

import 'package:flutter_eme_base/l10n/app_localizations.dart';
import 'package:flutter_eme_base/providers/workspace_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_eme_base/widgets/topics_card.dart';

import '../models/topic.dart';
import '../models/tutorial.dart';
import '../services/topic_service.dart';
import '../widgets/tutorial_card.dart';

class TopicTutorialsScreen extends ConsumerStatefulWidget {
  final Topic topic;

  const TopicTutorialsScreen({super.key, required this.topic});

  @override
  ConsumerState<TopicTutorialsScreen> createState() => _TopicTutorialsScreenState();
}

class _TopicTutorialsScreenState extends ConsumerState<TopicTutorialsScreen> {
  final TopicService _topicService = TopicService();
  late Future<List<Tutorial>> _tutorialsFuture;

  @override
  void initState() {
    super.initState();
    _loadTutorials();
  }

  void _loadTutorials() {
    setState(() {
      _tutorialsFuture = _topicService.fetchTutorialsForTopic(widget.topic.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final mainColor = const Color(0xFF38B6FF);

    ref.watch(localeProvider);
    return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0B0F13),
                  Color(0xFF141923),
                  Color(0xFF0F1319),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Row with Back Button
                  _buildHeader(context, mainColor),

                  // Scrollable list of tutorials
                  Expanded(
                    child: SingleChildScrollView(
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 40 : 20,
                            vertical: 24,
                          ),
                          width: min(700, size.width),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Topic Overview Details
                              TopicCard(topic: widget.topic),
                              const SizedBox(height: 32),

                              // Section Title
                              Text(
                                '${widget.topic.totalTutorials} ${l10n.tutorials}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: mainColor,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Dynamic List of tutorials loaded from API
                              FutureBuilder<List<Tutorial>>(
                                future: _tutorialsFuture,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 40.0,
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Color(0xFF38B6FF),
                                              ),
                                        ),
                                      ),
                                    );
                                  }

                                  if (snapshot.hasError) {
                                    return Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF161C24),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: [
                                          const Icon(
                                            Icons.error_outline,
                                            color: Color(0xFFF50057),
                                            size: 36,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Failed to load tutorials: ${snapshot.error}',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          ElevatedButton.icon(
                                            onPressed: _loadTutorials,
                                            icon: const Icon(Icons.refresh),
                                            label: const Text('Retry'),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  final tutorials = snapshot.data ?? [];
                                  if (tutorials.isEmpty) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 20.0,
                                      ),
                                      child: Center(
                                        child: Text(
                                          'No tutorials available.',
                                          style: TextStyle(
                                            color: Colors.white60,
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  return ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: tutorials.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 16),
                                    itemBuilder: (context, index) {
                                      final tutorial = tutorials[index];
                                      return TutorialCard(
                                        tutorial: tutorial,
                                        isListMode: true,
                                      );
                                    },
                                  );
                                },
                              ),

                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
  }

  Widget _buildHeader(BuildContext context, Color mainColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161C24).withValues(alpha: 0.4),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF263238), width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white70,
              size: 20,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.topic.title,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
