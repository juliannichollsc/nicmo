import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nicmo/il8n/app_localizations.dart';
import 'package:nicmo/screens/legal/terms_content.dart';
import 'package:nicmo/theme/metro_theme.dart';
import 'package:nicmo/widget/city/city_card.dart';
import 'package:nicmo/widget/shared/lightdark.dart';

/// Terms and conditions, reachable from the welcome steps and settings: a
/// short summary first, then the full text.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final content = TermsContent.of(locale);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : MetroPalette.ink;
    final accent = isDark ? MetroPalette.greenBright : MetroPalette.green;
    final updated = MaterialLocalizations.of(
      context,
    ).formatFullDate(DateTime.parse(kTermsVersion));

    void close() => context.canPop() ? context.pop() : context.go('/home');

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(themeBackground(context)),
            fit: BoxFit.cover,
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              foregroundColor: textColor,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: close,
              ),
              title: Text(
                l10n.termsTitle,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 12),
                child: Text(
                  l10n.termsUpdated(updated),
                  style: TextStyle(color: textColor.withValues(alpha: 0.6)),
                ),
              ),
            ),
            // Summary: what matters most, readable in a few seconds.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: StaggeredEntrance(
                  index: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                    decoration: BoxDecoration(
                      color: isDark ? MetroPalette.surface : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: accent.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.termsSummary.toUpperCase(),
                          style: TextStyle(
                            color: accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final (i, h) in content.highlights.indexed)
                          StaggeredEntrance(
                            index: i + 1,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.14),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      h.icon,
                                      size: 19,
                                      color: accent,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        h.text,
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.w600,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverList.builder(
              itemCount: content.sections.length,
              itemBuilder: (context, i) {
                final section = content.sections[i];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(28, 18, 28, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.title,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (final paragraph in section.paragraphs)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            paragraph,
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.82),
                              fontSize: 14.5,
                              height: 1.45,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            SliverToBoxAdapter(
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (kPrivacyContactEmail.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            content.contact(kPrivacyContactEmail),
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.82),
                            ),
                          ),
                        ),
                      FilledButton(
                        onPressed: close,
                        style: FilledButton.styleFrom(
                          backgroundColor: MetroPalette.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(l10n.termsUnderstood),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "By continuing you accept the Terms and conditions" with a link.
class TermsNotice extends StatelessWidget {
  final Color color;

  const TermsNotice({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '${l10n.termsAcceptNotice} ',
          style: TextStyle(color: color.withValues(alpha: 0.75), fontSize: 13),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => context.push('/terms'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Text(
              l10n.termsTitle,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
