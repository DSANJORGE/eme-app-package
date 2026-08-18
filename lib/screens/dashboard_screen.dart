import 'dart:math';

import 'package:flutter_eme_base/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_eme_base/utils/log.dart';
import 'package:flutter_eme_base/widgets/topics_card.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/topic.dart';
import '../models/workspace.dart';
import '../providers/workspace_provider.dart';
import '../services/auth_service.dart';
import '../services/topic_service.dart';
import '../services/workspace_service.dart';
import '../widgets/data_consent_dialog.dart';
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

  @override
  void initState() {
    super.initState();
    _loadTopics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DataCollectionConsentDialog.showIfNeeded(context);
    });
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
                                          'Failed to load topics: ${snapshot.error}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        ElevatedButton.icon(
                                          onPressed: _loadTopics,
                                          icon: const Icon(Icons.refresh),
                                          label: const Text('Retry'),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                final topics = snapshot.data ?? [];
                                if (topics.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 20.0,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'No topics available.',
                                        style: TextStyle(color: Colors.white60),
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
                                const Text(
                                  'View profile',
                                  style: TextStyle(
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
                                  'Could not open link: $url',
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
                                'Could not open link: $url',
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
                      const Text(
                        'Select Workspace',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // TextButton.icon(
                      //   onPressed: () async {
                      //     Navigator.pop(sheetContext);
                      //     await _showAddWorkspaceDialog(context);
                      //   },
                      //   icon: const Icon(
                      //     Icons.add_circle_outline_rounded,
                      //     size: 16,
                      //     color: Color(0xFF38B6FF),
                      //   ),
                      //   label: const Text(
                      //     'Add New',
                      //     style: TextStyle(
                      //       color: Color(0xFF38B6FF),
                      //       fontWeight: FontWeight.bold,
                      //     ),
                      //   ),
                      // ),
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
                                                'Workspace removed',
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
                                                'Failed to remove workspace',
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
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161C24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFF50057)),
              SizedBox(width: 8),
              Text(
                'Delete Workspace',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete workspace "${ws.name}" (${ws.mediaDBRoot})?',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF50057),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
