import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nicmo/app_info.dart';
import 'package:nicmo/il8n/app_localizations.dart';
import 'package:nicmo/theme/metro_theme.dart';
import 'package:nicmo/state/locale_state.dart';
import 'package:nicmo/widget/shared/lightdark.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _linkedInUrl = 'https://www.linkedin.com/in/jnichollsc/';
  bool _pushNotificationsEnabled = true;

  String _languageLabelFor(Locale locale, AppLocalizations l10n) {
    final name = _languageName(locale.languageCode, l10n);
    // Following the device: "System language (Español)".
    return LocaleState.notifier.value == null
        ? '${l10n.systemLanguage} ($name)'
        : name;
  }

  String _languageName(String code, AppLocalizations l10n) {
    switch (code) {
      case 'es':
        return l10n.spanish;
      case 'de':
        return l10n.german;
      case 'zh':
        return l10n.mandarin;
      default:
        return l10n.english;
    }
  }

  Future<void> _showLanguageSelector(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final currentCode = LocaleState.notifier.value?.languageCode ?? 'system';
    final options = <Map<String, String>>[
      {'code': 'system', 'label': l10n.systemLanguage},
      {'code': 'en', 'label': l10n.english},
      {'code': 'es', 'label': l10n.spanish},
      {'code': 'de', 'label': l10n.german},
      {'code': 'zh', 'label': l10n.mandarin},
    ];
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options
                .map(
                  (option) => RadioListTile<String>(
                    title: Text(option['label']!),
                    value: option['code']!,
                    groupValue: currentCode,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      LocaleState.setLocale(
                        value == 'system' ? null : Locale(value),
                      );
                      Navigator.of(ctx).pop();
                    },
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  void _onPushNotificationsChanged(bool value) {
    setState(() => _pushNotificationsEnabled = value);
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        content: Text(
          value ? l10n.notificationsEnabled : l10n.notificationsDisabled,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLinkError() {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.couldNotOpenLink),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _safeLaunchUri(
    Uri uri, {
    LaunchMode mode = LaunchMode.platformDefault,
  }) async {
    try {
      final launched = await launchUrl(uri, mode: mode);
      if (!launched) {
        _showLinkError();
      }
      return launched;
    } catch (_) {
      _showLinkError();
      return false;
    }
  }

  Future<void> _openLinkedIn() async {
    await _safeLaunchUri(
      Uri.parse(_linkedInUrl),
      mode: LaunchMode.platformDefault,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? Colors.black38 : Colors.white60;
    final shadowColor = isDark
        ? Colors.black.withOpacity(0.15)
        : Colors.black.withOpacity(0.08);
    const labelStyle = TextStyle(fontFamily: 'Roboto', fontSize: 14);

    Widget sectionTitle(String text) {
      return Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: labelStyle.copyWith(
              color: textColor.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    Widget settingTile({
      required IconData icon,
      required String title,
      String? subtitle,
      VoidCallback? onTap,
      Widget? trailing,
    }) {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(icon, color: textColor, size: 22),
        title: Text(title, style: labelStyle.copyWith(color: textColor)),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: labelStyle.copyWith(
                  color: textColor.withOpacity(0.7),
                  fontSize: 12,
                ),
              )
            : null,
        trailing: trailing,
        onTap: onTap,
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(themeBackground(context)),
            fit: BoxFit.cover,
          ),
        ),
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      sectionTitle(AppLocalizations.of(context)!.appearance),
                      ValueListenableBuilder<ThemeMode>(
                        valueListenable: themeNotifier,
                        builder: (context, _, _) {
                          final l10n = AppLocalizations.of(context)!;
                          final isDark =
                              Theme.of(context).brightness == Brightness.dark;
                          return settingTile(
                            icon: isDark ? Icons.dark_mode : Icons.light_mode,
                            title: l10n.darkMode,
                            subtitle: isDark ? l10n.on : l10n.off,
                            trailing: Switch(
                              value: isDark,
                              onChanged: themeNotifier.setDark,
                            ),
                          );
                        },
                      ),
                      sectionTitle(AppLocalizations.of(context)!.notifications),
                      settingTile(
                        icon: Icons.notifications_outlined,
                        title: AppLocalizations.of(context)!.pushNotifications,
                        subtitle: AppLocalizations.of(
                          context,
                        )!.receiveAppAlerts,
                        trailing: Switch(
                          value: _pushNotificationsEnabled,
                          onChanged: _onPushNotificationsChanged,
                        ),
                      ),
                      sectionTitle(AppLocalizations.of(context)!.general),
                      settingTile(
                        icon: Icons.language,
                        title: AppLocalizations.of(context)!.language,
                        subtitle:
                            '${_languageLabelFor(Localizations.localeOf(context), AppLocalizations.of(context)!)}\n'
                            '${AppLocalizations.of(context)!.languageHint}',
                        onTap: () => _showLanguageSelector(context),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.change,
                              style: const TextStyle(
                                color: MetroPalette.green,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: MetroPalette.green,
                            ),
                          ],
                        ),
                      ),
                      sectionTitle(AppLocalizations.of(context)!.about),
                      settingTile(
                        icon: Icons.info_outline,
                        title: kAppName,
                        subtitle: AppLocalizations.of(context)!.aboutVersion,
                      ),
                      settingTile(
                        icon: Icons.gavel_rounded,
                        title: AppLocalizations.of(context)!.termsTitle,
                        onTap: () => context.push('/terms'),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: textColor.withValues(alpha: 0.7),
                        ),
                      ),
                      settingTile(
                        icon: Icons.person_outline_rounded,
                        title: AppLocalizations.of(context)!.createdBy,
                        subtitle:
                            '${AppLocalizations.of(context)!.julianNichollsC} · '
                            '${AppLocalizations.of(context)!.linkedIn}',
                        onTap: _openLinkedIn,
                        trailing: Icon(
                          Icons.open_in_new,
                          size: 18,
                          color: textColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
