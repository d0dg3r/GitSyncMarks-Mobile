import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';

const String _gitSyncMarksUrl = 'https://github.com/d0dg3r/GitSyncMarks';
const String _gitSyncMarksAndroidUrl =
    'https://github.com/d0dg3r/GitSyncMarks-Mobile';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l.info)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // ── About ──
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    width: 72,
                    height: 72,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l.appTitle,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final v = snapshot.data?.version ?? '...';
                    return Text(
                      l.version(v),
                      style: textTheme.bodyMedium
                          ?.copyWith(color: scheme.outline),
                    );
                  },
                ),
                const SizedBox(height: 2),
                Text(
                  l.authorBy,
                  style:
                      textTheme.bodyMedium?.copyWith(color: scheme.outline),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Text(
            l.aboutDescription,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium,
          ),

          const SizedBox(height: 24),

          // ── Projects card ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.projects,
                    style: textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.formatFromGitSyncMarks,
                    style:
                        textTheme.bodySmall?.copyWith(color: scheme.outline),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _launchUrl(_gitSyncMarksUrl),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                      child: Row(
                        children: [
                          Icon(Icons.extension,
                              color: scheme.primary, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l.appTitle,
                                    style: textTheme.titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w500)),
                                const SizedBox(height: 2),
                                Text(l.gitSyncMarksDesc,
                                    style: textTheme.bodySmall
                                        ?.copyWith(color: scheme.outline)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.open_in_new,
                              size: 18, color: scheme.outline),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),
          Center(
            child: Text(
              l.licenseMit,
              style: textTheme.bodySmall?.copyWith(color: scheme.outline),
            ),
          ),

          const SizedBox(height: 28),

          // ── Quick guide ──
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
            child: Text(
              l.quickGuide.toUpperCase(),
              style: textTheme.labelMedium?.copyWith(
                color: scheme.outline,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _HelpStep(number: '1', title: l.help1Title, body: l.help1Body),
                  _HelpStep(number: '2', title: l.help2Title, body: l.help2Body),
                  _HelpStep(number: '3', title: l.help3Title, body: l.help3Body),
                  _HelpStep(number: '4', title: l.help4Title, body: l.help4Body),
                  _HelpStep(
                      number: '5',
                      title: l.help5Title,
                      body: l.help5Body,
                      isLast: true),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Support card ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.support,
                    style: textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(l.supportText, style: textTheme.bodySmall),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _launchUrl(_gitSyncMarksAndroidUrl),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                      child: Row(
                        children: [
                          Icon(Icons.bug_report,
                              color: scheme.primary, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l.gitSyncMarksAndroidIssues,
                              style: textTheme.bodyMedium
                                  ?.copyWith(color: scheme.primary),
                            ),
                          ),
                          Icon(Icons.open_in_new,
                              size: 18, color: scheme.outline),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Repo format card ──
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.whichRepoFormat,
                    style: textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(l.repoFormatDescription,
                      style: textTheme.bodySmall),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// =============================================================================
// Help step
// =============================================================================

class _HelpStep extends StatelessWidget {
  const _HelpStep({
    required this.number,
    required this.title,
    required this.body,
    this.isLast = false,
  });

  final String number;
  final String title;
  final String body;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 3),
                Text(body, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
