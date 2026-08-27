import 'package:flutter_eme_base/models/tag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_eme_base/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transparent_image/transparent_image.dart';
import '../services/auth_service.dart';
import '../utils/error_handler.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = AuthService.currentUser;

    final String portraitUrl = user?.assetPortrait.isNotEmpty == true
        ? user!.assetPortrait
        : "https://eme.world/finder/find/theme/images/user.svg";

    final String email = user?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        backgroundColor: const Color(0xFF141923),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B0F13), Color(0xFF141923), Color(0xFF0F1319)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.profile,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF38B6FF),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF161C24).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
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
                                imageErrorBuilder:
                                    (context, error, stackTrace) => const Icon(
                                      Icons.person,
                                      size: 40,
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
                                user!.displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (email.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  email,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'SKILLS',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF38B6FF),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              _buildProfileTags(context),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A8DC6),
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: Text(
                      l10n.editProfile,
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                    ),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                      _refresh();
                    },
                  ),

                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFFF50057,
                      ).withValues(alpha: 0.05),
                      side: BorderSide(
                        color: const Color(0xFFF50057).withValues(alpha: 0.3),
                      ),
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(
                      Icons.delete_forever,
                      size: 18,
                      color: Color(0xFFF50057),
                    ),
                    label: Text(
                      l10n.deleteAccount,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFF50057),
                      ),
                    ),
                    onPressed: _showDeleteAccountDialog,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141923),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFF50057)),
            const SizedBox(width: 10),
            Text(
              l10n.deleteAccount,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          l10n.deleteAccountConfirm,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF50057),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await AuthService.logout();
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (mounted) {
                  AppErrorHandler.showUserSuccess(
                    context,
                    l10n.accountDataCleared,
                  );
                  await AuthService.logout();
                  if (mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                }
              } catch (e, stack) {
                AppErrorHandler.recordNonFatal(
                  e,
                  stack,
                  reason: 'ProfileScreen delete account failed',
                );
                if (mounted) {
                  AppErrorHandler.showUserError(
                    context,
                    l10n.failedToClearAccountData,
                  );
                }
              }
            },
            child: Text(
              l10n.deleteAccount,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTags(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sortedTags = List<Tag>.from(mockTags)
      ..sort((a, b) => b.score.compareTo(a.score));

    final bestTags = sortedTags.where((t) => t.score >= 70).toList();
    final previewTags = bestTags.take(3).toList();
    final remainingCount = bestTags.length - previewTags.length;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tag in previewTags)
          _buildProfileTagItem(
            label: tag.name,
            icon: Icons.emoji_events_rounded,
            onTap: () => _showAchievementsBottomSheet(context),
          ),
        if (remainingCount > 0)
          InkWell(
            onTap: () => _showAchievementsBottomSheet(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blueAccent.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                l10n.plusMoreCount(remainingCount.toString()),
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileTagItem({
    required String label,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 240),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.blue.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: Colors.blue),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAchievementsBottomSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sorted = List<Tag>.from(mockTags)
      ..sort((a, b) => b.score.compareTo(a.score));
    final top10 = sorted.where((t) => t.score >= 70).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF141923),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border(top: BorderSide(color: Colors.white12, width: 1)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Column(
                children: [
                  // Drag indicator
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            l10n.topicsYouExcelAt,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  // Grid of top 10 topics
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(24),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 400,
                            mainAxisExtent: 90,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: top10.length,
                      itemBuilder: (context, index) {
                        final tag = top10[index];
                        return _buildExcelTopicCard(tag, index + 1, context);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildExcelTopicCard(Tag tag, int rank, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Color rankColor;
    if (rank == 1) {
      rankColor = const Color(0xFFFFD700); // Gold
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0); // Silver
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32); // Bronze
    } else {
      rankColor = Colors.white54;
    }

    Color scoreColor;
    String scoreLevel;
    if (tag.score < 30) {
      scoreColor = Colors.redAccent;
      scoreLevel = l10n.beginner;
    } else if (tag.score < 70) {
      scoreColor = Colors.yellowAccent;
      scoreLevel = l10n.intermediate;
    } else {
      scoreColor = Colors.greenAccent;
      scoreLevel = l10n.expert;
    }

    Color competenceColor;
    IconData competenceIcon;
    if (tag.score < 30) {
      competenceColor = Colors.green;
      competenceIcon = Icons.local_florist_rounded;
    } else if (tag.score < 70) {
      competenceColor = Colors.yellow;
      competenceIcon = Icons.stars_rounded;
    } else {
      competenceColor = Colors.orange;
      competenceIcon = Icons.emoji_events_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1D2633),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? rankColor.withValues(alpha: 0.15)
                  : Colors.transparent,
              shape: BoxShape.circle,
              border: rank <= 3
                  ? Border.all(color: rankColor, width: 1.5)
                  : null,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  color: rankColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Title & Badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tag.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                // Competence pill
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(competenceIcon, size: 10, color: competenceColor),
                    const SizedBox(width: 4),
                    Text(
                      scoreLevel,
                      style: TextStyle(
                        color: competenceColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  value: tag.score / 100.0,
                  strokeWidth: 3,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                ),
              ),
              Text(
                '${tag.score.toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
