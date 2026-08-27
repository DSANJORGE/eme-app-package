import 'dart:math';

import 'package:eme_app_package/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eme_app_package/utils/log.dart';
import 'package:eme_app_package/widgets/topics_card.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/daily_challenge.dart';
import '../models/mistake_item.dart';
import '../models/topic.dart';
import '../models/workspace.dart';
import '../providers/workspace_provider.dart';
import '../services/auth_service.dart';
import '../services/topic_service.dart';
import '../services/workspace_service.dart';
import '../widgets/daily_challenge_section.dart';
import '../widgets/data_consent_dialog.dart';
import '../widgets/mistakes_section.dart';
import 'compliance_screen.dart';
import 'profile_screen.dart';
import '../utils/error_handler.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final String fullName;
  final VoidCallback? onLogout;
  final VoidCallback? onWorkspaceChanged;

  const DashboardScreen({
    super.key,
    required this.fullName,
    this.onLogout,
    this.onWorkspaceChanged,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TopicService _topicService = TopicService();
  late Future<List<Topic>> _topicsFuture;
  Workspace _activeWorkSpace = WorkspaceService.activeWorkspace;
  String selectedTab = 'Catalog';

  late List<DailyChallengeItem> _dailyChallenges;
  late List<MistakeItem> _mistakes;

  @override
  void initState() {
    super.initState();
    _dailyChallenges = _initDailyChallenges();
    _mistakes = _initMistakes();
    _loadTopics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DataCollectionConsentDialog.showIfNeeded(context);
    });
  }

  List<DailyChallengeItem> _initDailyChallenges() {
    final now = DateTime.now();
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final List<DailyChallengeItem> list = [];

    for (int i = 6; i >= 1; i--) {
      final date = now.subtract(Duration(days: i));
      final dayLabel = weekdays[date.weekday - 1];
      final dateLabel = '${date.month}/${date.day}';
      final isCompleted = (i == 6 || i == 5 || i == 4 || i == 2);
      final completedQuestions = isCompleted ? 5 : (i == 3 ? 3 : 2);

      list.add(
        DailyChallengeItem(
          id: 'day-$i',
          date: date,
          dayLabel: dayLabel,
          dateLabel: dateLabel,
          title: 'Daily Practice • $dayLabel',
          totalQuestions: 5,
          completedQuestions: completedQuestions,
          isToday: false,
        ),
      );
    }

    // Today
    list.add(
      DailyChallengeItem(
        id: 'today',
        date: now,
        dayLabel: 'Today',
        dateLabel: '${now.month}/${now.day}',
        title: 'Sunday, August 27',
        totalQuestions: 20,
        completedQuestions: 3,
        isToday: true,
      ),
    );

    return list;
  }

  List<MistakeItem> _initMistakes() {
    return [
      MistakeItem(
        id: 'm1',
        topicTitle: 'Algebra & Calculus',
        question:
            'What is the derivative of f(x) = 3x² + 5x - 4 with respect to x?',
        options: ['6x + 5', '3x + 5', '6x² + 5', '6x - 4'],
        correctOptionIndex: 0,
        explanation:
            'Applying the power rule d/dx[xⁿ] = n·xⁿ⁻¹, the derivative of 3x² is 6x and 5x is 5. Constant 4 becomes 0.',
      ),
      MistakeItem(
        id: 'm2',
        topicTitle: 'Language & Grammar',
        question:
            'Identify the sentence that uses the subjunctive mood correctly:',
        options: [
          'If I was you, I would take the offer.',
          'If I were you, I would accept the opportunity.',
          'I wish I was taller.',
          'He acts like he was the owner.',
        ],
        correctOptionIndex: 1,
        explanation:
            'In contrary-to-fact conditional clauses, "were" is used for the subjunctive mood with singular subjects ("If I were you").',
      ),
      MistakeItem(
        id: 'm3',
        topicTitle: 'Physics & Circuits',
        question:
            'When an additional parallel resistor is connected in an active circuit, the total equivalent resistance:',
        options: [
          'Increases',
          'Decreases',
          'Remains unchanged',
          'Becomes zero',
        ],
        correctOptionIndex: 1,
        explanation:
            'In parallel circuits, 1/R_eq = 1/R1 + 1/R2. Adding more pathways reduces overall total resistance and increases total current.',
      ),
    ];
  }

  void _onChallengeCompleted(DailyChallengeItem item) {
    setState(() {
      item.complete();
    });
  }

  void _onMistakeResolved(MistakeItem mistake) {
    setState(() {
      mistake.isResolved = true;
    });
  }

  void _onAllMistakesResolved() {
    setState(() {});
  }

  void _loadTopics() {
    setState(() {
      _topicsFuture = _topicService.fetchTopics();
    });
  }

  Future<void> _refreshTopics() async {
    final newTopics = await _topicService.fetchTopics();
    setState(() {
      _topicsFuture = Future.value(newTopics);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    final user = AuthService.currentUser;

    final String portraitUrl = user?.assetPortrait.isNotEmpty == true
        ? user!.assetPortrait
        : "https://eme.world/finder/find/theme/images/user.svg";

    ref.watch(localeProvider);
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(user!.displayName, portraitUrl),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B0F13), Color(0xFF141923), Color(0xFF0F1319)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Sleek Modern Header
              _buildHeader(context, isDesktop, _activeWorkSpace),

              // 2. Main Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshTopics,
                  color: const Color(0xFF38B6FF),
                  backgroundColor: const Color(0xFF1E2638),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Center(
                      child: Container(
                        width: min(700, size.width),
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 40 : 20,
                          vertical: 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // // Daily Challenge Section
                            DailyChallengeSection(
                              challenges: _dailyChallenges,
                              onChallengeCompleted: _onChallengeCompleted,
                            ),
                            const SizedBox(height: 24),

                            // Mistakes Section
                            MistakesSection(
                              mistakes: _mistakes,
                              onMistakeResolved: _onMistakeResolved,
                              onAllMistakesResolved: _onAllMistakesResolved,
                            ),
                            const SizedBox(height: 28),

                            // Section Title
                            Text(
                              l10n.topics,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF38B6FF),
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Dynamic Topics List from API Service
                            FutureBuilder<List<Topic>>(
                              future: _topicsFuture,
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
                                      color: const Color(0xFF1E2638),
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
                                          l10n.failedToLoadTopics(
                                            snapshot.error.toString(),
                                          ),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        ElevatedButton.icon(
                                          onPressed: _loadTopics,
                                          icon: const Icon(Icons.refresh),
                                          label: Text(l10n.retry),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                final topics = snapshot.data ?? [];
                                if (topics.isEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 20.0,
                                    ),
                                    child: Center(
                                      child: Text(
                                        l10n.noTopicsAvailable,
                                        style: const TextStyle(
                                          color: Colors.white60,
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                return ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: topics.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 16),
                                  itemBuilder: (context, index) {
                                    return TopicCard(topic: topics[index]);
                                  },
                                );
                              },
                            ),
                          ],
                        ),
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

  Widget _buildHeader(
    BuildContext context,
    bool isDesktop,
    Workspace workspace,
  ) {
    // final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : 20,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF161C24).withValues(alpha: 0.4),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF263238), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white70),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
              const SizedBox(width: 8),
              Container(
                height: 40,
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: 32, maxWidth: 150),
                  child: workspace.iconAsset != null
                      ? FadeInImage.memoryNetwork(
                          image: workspace.iconAsset!,
                          placeholder: kTransparentImage,
                          imageErrorBuilder: (context, _, _) => Text(
                            workspace.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      : Text(
                          workspace.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ),
            ],
          ),

          // Row(
          //   children: [
          //     PopupMenuButton<int>(
          //       offset: const Offset(0, 48),
          //       color: const Color(0xFF161C24),
          //       elevation: 8,
          //       shadowColor: Colors.black.withValues(alpha: 0.5),
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(16),
          //         side: BorderSide(
          //           color: Colors.white.withValues(alpha: 0.08),
          //           width: 1.5,
          //         ),
          //       ),
          //       child: Stack(
          //         clipBehavior: Clip.none,
          //         children: [
          //           Container(
          //             width: 38,
          //             height: 38,
          //             decoration: BoxDecoration(
          //               shape: BoxShape.circle,
          //               color: Colors.white.withValues(alpha: 0.04),
          //               border: Border.all(
          //                 color: Colors.white.withValues(alpha: 0.08),
          //               ),
          //             ),
          //             child: const Center(
          //               child: Icon(
          //                 Icons.notifications_outlined,
          //                 size: 18,
          //                 color: Color(0xFF38B6FF),
          //               ),
          //             ),
          //           ),
          //           Positioned(
          //             top: 0,
          //             right: 0,
          //             child: Container(
          //               width: 8,
          //               height: 8,
          //               decoration: const BoxDecoration(
          //                 color: Color(0xFFF50057),
          //                 shape: BoxShape.circle,
          //               ),
          //             ),
          //           ),
          //         ],
          //       ),
          //       itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
          // PopupMenuItem<int>(
          //   value: -1,
          //   enabled: false,
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //     children: [
          //       Text(
          //         l10n.notifications,
          //         style: const TextStyle(
          //           fontWeight: FontWeight.bold,
          //           color: Colors.white,
          //           fontSize: 14,
          //         ),
          //       ),
          //       Container(
          //         padding: const EdgeInsets.symmetric(
          //           horizontal: 6,
          //           vertical: 2,
          //         ),
          //         decoration: BoxDecoration(
          //           color: const Color(
          //             0xFFF50057,
          //           ).withValues(alpha: 0.15),
          //           borderRadius: BorderRadius.circular(10),
          //         ),
          //         child: Text(
          //           l10n.newTutorials,
          //           style: const TextStyle(
          //             color: Color(0xFFF50057),
          //             fontSize: 9,
          //             fontWeight: FontWeight.bold,
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          // const PopupMenuDivider(height: 1),
          // PopupMenuItem<int>(
          //   value: 0,
          //   child: _buildNotificationItem(
          //     title: l10n.newTutorialTitle,
          //     body: l10n.newTutorialBody,
          //     time: l10n.time5m,
          //     isNew: true,
          //   ),
          // ),
          // PopupMenuItem<int>(
          //   value: 1,
          //   child: _buildNotificationItem(
          //     title: l10n.achievementTitle,
          //     body: l10n.achievementBody,
          //     time: l10n.time2h,
          //     isNew: true,
          //   ),
          // ),
          // ],
          // ),
          //     const SizedBox(width: 10),
          //     Container(
          //       width: 38,
          //       height: 38,
          //       decoration: BoxDecoration(
          //         shape: BoxShape.circle,
          //         color: Colors.white.withValues(alpha: 0.04),
          //         border: Border.all(
          //           color: Colors.white.withValues(alpha: 0.08),
          //         ),
          //       ),
          //       child: const Center(
          //         child: Icon(
          //           Icons.analytics_outlined,
          //           size: 18,
          //           color: Colors.white70,
          //         ),
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }

  // Widget _buildNotificationItem({
  //   required String title,
  //   required String body,
  //   required String time,
  //   required bool isNew,
  // }) {
  //   return Container(
  //     width: 280,
  //     padding: const EdgeInsets.symmetric(vertical: 4),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             if (isNew)
  //               Container(
  //                 margin: const EdgeInsets.only(right: 6),
  //                 width: 6,
  //                 height: 6,
  //                 decoration: const BoxDecoration(
  //                   color: Color(0xFF38B6FF),
  //                   shape: BoxShape.circle,
  //                 ),
  //               ),
  //             Expanded(
  //               child: Text(
  //                 title,
  //                 style: TextStyle(
  //                   color: isNew ? Colors.white : Colors.white70,
  //                   fontWeight: isNew ? FontWeight.bold : FontWeight.w600,
  //                   fontSize: 12,
  //                 ),
  //               ),
  //             ),
  //             Text(
  //               time,
  //               style: const TextStyle(color: Colors.white38, fontSize: 10),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 4),
  //         Text(
  //           body,
  //           maxLines: 2,
  //           overflow: TextOverflow.ellipsis,
  //           style: const TextStyle(color: Colors.white54, fontSize: 11),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildDrawer(String displayName, String portraitUrl) {
    final l10n = AppLocalizations.of(context)!;

    return Drawer(
      backgroundColor: const Color(0xFF0F1319),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B0F13), Color(0xFF141923)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              shape: BoxShape.circle,
                            ),
                            child: OverflowBox(
                              alignment: Alignment.center,
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: FadeInImage.memoryNetwork(
                                  placeholder: kTransparentImage,
                                  image: portraitUrl,
                                  fit: BoxFit.cover,
                                  imageErrorBuilder:
                                      (context, error, stackTrace) =>
                                          const Icon(
                                            Icons.person,
                                            size: 28,
                                            color: Colors.white54,
                                          ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.viewProfile,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF38B6FF),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      _buildDrawerItem(
                        icon: Icons.dashboard_rounded,
                        title: l10n.catalogDashboard,
                        selected: selectedTab == 'Catalog',
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.person_outline,
                        title: l10n.profile,
                        selected: false,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileScreen(),
                            ),
                          );
                        },
                      ),
                      Expanded(child: Container()),
                      _buildDrawerItem(
                        icon: Icons.verified_user_outlined,
                        title: l10n.appCompliance,
                        selected: false,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ComplianceScreen(onLogout: widget.onLogout),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.workspace,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => _showWorkspaceModalSheet(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2631),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    WorkspaceService.activeWorkspace.id ==
                                        'minsur'
                                    ? const Color(0xFF0072FF)
                                    : WorkspaceService.activeWorkspace.id ==
                                          'eme'
                                    ? const Color(0xFF00C853)
                                    : const Color(0xFF8A2387),
                              ),
                              child: const Icon(
                                Icons.hub_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _activeWorkSpace.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: Colors.white70,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white54,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      l10n.language,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2631),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: Workspace.currentLanguage.languageCode == 'es'
                              ? 'Español'
                              : 'English',
                          dropdownColor: const Color(0xFF1E2631),
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white54,
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: Colors.white70,
                          ),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              final langCode = newValue == 'Español'
                                  ? 'es'
                                  : 'en';
                              ref
                                  .read(localeProvider.notifier)
                                  .setLocale(Locale(langCode));
                            }
                          },
                          items: <String>['English', 'Español']
                              .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        value == 'English' ? '🇺🇸' : '🇪🇸',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(value),
                                    ],
                                  ),
                                );
                              })
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        if (widget.onLogout != null) widget.onLogout!();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.logout_rounded,
                              color: Color(0xFFF50057),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              l10n.logout,
                              style: const TextStyle(
                                color: Color(0xFFF50057),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: InkWell(
                        onTap: () async {
                          final url = Uri.parse('https://eme.world');
                          try {
                            if (await canLaunchUrl(url)) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              logPrint('Could not launch $url');
                              if (mounted) {
                                AppErrorHandler.showUserError(
                                  context,
                                  l10n.couldNotOpenLink(url.toString()),
                                );
                              }
                            }
                          } catch (e, stack) {
                            AppErrorHandler.recordNonFatal(
                              e,
                              stack,
                              reason: 'DashboardScreen URL launch failed',
                              customKeys: {'url': url.toString()},
                            );
                            if (mounted) {
                              AppErrorHandler.showUserError(
                                context,
                                l10n.couldNotOpenLink(url.toString()),
                              );
                            }
                          }
                        },
                        child: Text(
                          l10n.poweredBy,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white30,
                            letterSpacing: 0.5,
                          ),
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

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? const Color(0xFF38B6FF).withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFF38B6FF).withValues(alpha: 0.15)
                  : Colors.transparent,
            ),
          ),
          child: ListTile(
            leading: Icon(
              icon,
              color: selected ? const Color(0xFF38B6FF) : Colors.white54,
              size: 20,
            ),
            title: Text(
              title,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            onTap: onTap,
          ),
        ),
      ),
    );
  }

  void _showWorkspaceModalSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (modalContext, setSheetState) {
            final workspaces = WorkspaceService.workspaces;
            final activeWs = WorkspaceService.activeWorkspace;
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF161C24),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                border: Border(
                  top: BorderSide(color: Colors.white12, width: 1),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.selectWorkspace,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: workspaces.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final ws = workspaces[index];
                        final isSelected = ws.id == activeWs.id;
                        final color = ws.id == 'minsur'
                            ? const Color(0xFF0072FF)
                            : ws.id == 'eme'
                            ? const Color(0xFF00C853)
                            : const Color(0xFF8A2387);
                        final canDelete = WorkspaceService.canDeleteWorkspace(
                          ws,
                        );

                        return Material(
                          color: isSelected
                              ? const Color(0xFF1E2638)
                              : const Color(0xFF0F1319),
                          borderRadius: BorderRadius.circular(14),
                          clipBehavior: Clip.antiAlias,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(
                                        0xFF38B6FF,
                                      ).withValues(alpha: 0.4)
                                    : Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            child: ListTile(
                              onTap: () async {
                                Navigator.pop(sheetContext);
                                await AuthService.switchWorkspace(ws);
                                setState(() {
                                  _activeWorkSpace = ws;
                                  _loadTopics();
                                });
                                widget.onWorkspaceChanged?.call();
                              },
                              leading: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color.withValues(alpha: 0.15),
                                  border: Border.all(color: color, width: 1.5),
                                ),
                                child: Icon(
                                  Icons.hub_rounded,
                                  size: 16,
                                  color: color,
                                ),
                              ),
                              title: Text(
                                ws.name,
                                style: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFF38B6FF)
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                ws.mediaDBRoot,
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: canDelete
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Color(0xFFF50057),
                                        size: 20,
                                      ),
                                      onPressed: () async {
                                        final confirmed =
                                            await _showConfirmDeleteDialog(
                                              modalContext,
                                              ws,
                                            );
                                        if (confirmed) {
                                          try {
                                            await WorkspaceService.removeWorkspace(
                                              ws,
                                            );
                                            await AuthService.loadSessionForActiveWorkspace();
                                            if (mounted) {
                                              setState(() {
                                                _activeWorkSpace =
                                                    WorkspaceService
                                                        .activeWorkspace;
                                                _loadTopics();
                                              });
                                              AppErrorHandler.showUserSuccess(
                                                this.context,
                                                l10n.workspaceRemoved,
                                              );
                                              widget.onWorkspaceChanged?.call();
                                            }
                                            setSheetState(() {});
                                          } catch (e, stack) {
                                            AppErrorHandler.recordNonFatal(
                                              e,
                                              stack,
                                              reason:
                                                  'DashboardScreen remove workspace failed',
                                              customKeys: {
                                                'workspaceId': ws.id,
                                              },
                                            );
                                            if (mounted) {
                                              AppErrorHandler.showUserError(
                                                this.context,
                                                l10n.failedToRemoveWorkspace,
                                              );
                                            }
                                          }
                                        }
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _showConfirmDeleteDialog(
    BuildContext context,
    Workspace ws,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161C24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFF50057)),
              const SizedBox(width: 8),
              Text(
                l10n.deleteWorkspace,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          content: Text(
            l10n.deleteWorkspaceConfirm(ws.name, ws.mediaDBRoot),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                l10n.cancel,
                style: const TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF50057),
              ),
              child: Text(
                l10n.delete,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
