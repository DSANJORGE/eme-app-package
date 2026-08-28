import 'package:dio/dio.dart';
import 'package:eme_app_package/eme_app_package.dart';
import 'package:eme_app_package/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:eme_app_package/utils/dio.dart';

class DataCollectionConsentDialog extends StatefulWidget {
  final VoidCallback onConsentGiven;

  const DataCollectionConsentDialog({super.key, required this.onConsentGiven});

  static bool hasConsented() {
    return AuthService.currentUser?.dataConsent ?? false;
  }

  static Future<bool> saveConsent(bool consented) async {
    try {
      final mediaDbRoot = AuthService.mediaDBRoot;
      final targetUrl =
          '$mediaDbRoot/services/authentication/usersave.json?'
          'save=true&'
          'userid=${AuthService.userId}&'
          'username=${AuthService.userId}&'
          'field=dataconsent&dataconsent.value=${consented.toString()}';

      final response = await DioUtil.dio.post(
        targetUrl,
        options: Options(
          headers: {
            'X-tokentype': 'entermedia',
            'X-token': AuthService.token ?? '',
          },
        ),
      );
      if (response.statusCode != 200) {
        return false;
      }
      await AuthService.fetchUser();
      return true;
    } catch (e, stack) {
      logPrint('Failed to save consent: $e');
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'DataCollectionConsentDialog.saveConsent failed',
      );
      return false;
    }
  }

  static Future<void> showIfNeeded(BuildContext context) async {
    final consented = hasConsented();
    if (!consented && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => DataCollectionConsentDialog(
          onConsentGiven: () {
            if (ctx.mounted) {
              Navigator.of(ctx).pop();
            }
          },
        ),
      );
    }
  }

  @override
  State<DataCollectionConsentDialog> createState() =>
      _DataCollectionConsentDialogState();
}

class _DataCollectionConsentDialogState
    extends State<DataCollectionConsentDialog> {
  bool _isLoading = false;

  Future<void> _handleConsent(bool consented) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      await DataCollectionConsentDialog.saveConsent(consented);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        widget.onConsentGiven();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: const Color(0xFF141923),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38B6FF).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: Color(0xFF38B6FF),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.dataConsentTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.dataConsentBody,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildDataPoint(
                        icon: Icons.person_outline,
                        title: l10n.accountInfoTitle,
                        subtitle: l10n.accountInfoSubtitle,
                      ),
                      const SizedBox(height: 8),
                      _buildDataPoint(
                        icon: Icons.chat_bubble_outline,
                        title: l10n.interactiveChatLearningTitle,
                        subtitle: l10n.interactiveChatLearningSubtitle,
                      ),
                      const SizedBox(height: 8),
                      _buildDataPoint(
                        icon: Icons.security,
                        title: l10n.dataProtectionTitle,
                        subtitle: l10n.dataProtectionSubtitle,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isLoading
                            ? null
                            : () => _handleConsent(false),
                        child: Text(
                          l10n.declineConsent,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF38B6FF),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isLoading
                            ? null
                            : () => _handleConsent(true),
                        child: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.black,
                                  ),
                                ),
                              )
                            : Text(
                                l10n.acceptConsent,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataPoint({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF38B6FF)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
