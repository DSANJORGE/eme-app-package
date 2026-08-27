import 'package:dio/dio.dart';
import 'package:flutter_eme_base/flutter_eme_base.dart';
import 'package:flutter_eme_base/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_eme_base/utils/dio.dart';
import 'package:intl/intl.dart';
import '../widgets/data_consent_dialog.dart';

class ComplianceScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const ComplianceScreen({super.key, this.onLogout});

  @override
  State<ComplianceScreen> createState() => _ComplianceScreenState();
}

class _ComplianceScreenState extends State<ComplianceScreen> {
  bool _hasConsented = true;

  @override
  void initState() {
    super.initState();
    _loadConsentStatus();
  }

  void _loadConsentStatus() {
    if (mounted) {
      setState(() {
        _hasConsented = DataCollectionConsentDialog.hasConsented();
      });
    }
  }

  Future<void> _toggleConsent(bool value) async {
    try {
      setState(() {
        _hasConsented = value;
      });

      final success = await DataCollectionConsentDialog.saveConsent(value);
      if (!success && mounted) {
        setState(() {
          _hasConsented = !value;
        });
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        AppErrorHandler.showUserSuccess(
          context,
          value
              ? l10n.consentUpdatedAccepted
              : l10n.consentUpdatedEssential,
        );
      }
    } catch (e, stack) {
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'ComplianceScreen _toggleConsent failed',
      );
      if (mounted) {
        setState(() {
          _hasConsented = !_hasConsented;
        });
        final l10n = AppLocalizations.of(context)!;
        AppErrorHandler.showUserError(
          context,
          l10n.failedToUpdateConsent,
        );
      }
    }
  }

  void _showDeleteDataDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141923),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        title: Row(
          children: [
            const Icon(Icons.delete_sweep_rounded, color: Colors.orangeAccent),
            const SizedBox(width: 10),
            Text(
              l10n.deleteData,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          l10n.deleteDataConfirm,
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
              backgroundColor: Colors.orangeAccent,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final now = DateTime.now();
                final dateValue = DateFormat('yyyy-MM-dd').format(now);
                final hourValue = DateFormat('HH').format(now);
                final minuteValue = DateFormat('mm').format(now);

                final mediaDbRoot = AuthService.mediaDBRoot;
                final targetUrl =
                    '$mediaDbRoot/services/authentication/usersave.json?'
                    'save=true&'
                    'userid=${AuthService.userId}&'
                    'username=${AuthService.userId}&'
                    'field=datadeleterequested&'
                    'datadeleterequested.value=$dateValue&'
                    'datadeleterequested.hour=$hourValue&'
                    'datadeleterequested.minute=$minuteValue';
                await DioUtil.dio.post(
                  targetUrl,
                  options: Options(
                    headers: {
                      'X-tokentype': 'entermedia',
                      'X-token': AuthService.token ?? '',
                    },
                  ),
                );
                if (mounted) {
                  AppErrorHandler.showUserSuccess(
                    context,
                    l10n.dataDeletionRequested,
                  );
                }
              } catch (e, stack) {
                AppErrorHandler.recordNonFatal(
                  e,
                  stack,
                  reason: 'ComplianceScreen delete progress cache failed',
                );
                if (mounted) {
                  AppErrorHandler.showUserError(
                    context,
                    l10n.failedToRequestDataDeletion,
                  );
                }
              }
            },
            child: Text(
              l10n.confirm,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1319),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F13),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.appCompliance,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              title: l10n.privacyPolicy,
              icon: Icons.privacy_tip_outlined,
              iconColor: const Color(0xFF38EF7D),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.dataConsentBody,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            l10n.dataCollectionConsentStatus,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Switch(
                          value: _hasConsented,
                          activeThumbColor: const Color(0xFF38B6FF),
                          onChanged: _toggleConsent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section 4: Data & Account Erasure Options
            _buildSectionCard(
              title: l10n.accountManagementTitle,
              icon: Icons.manage_accounts_outlined,
              iconColor: Colors.orange,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.accountManagementBody,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      backgroundColor: Colors.orange.withValues(alpha: 0.05),
                      side: BorderSide(
                        color: Colors.orange.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(
                      Icons.cleaning_services,
                      size: 16,
                      color: Colors.orange,
                    ),
                    label: Text(
                      l10n.deleteData,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.orange,
                      ),
                    ),
                    onPressed: _showDeleteDataDialog,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141923),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
