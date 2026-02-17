import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/github_credentials.dart';
import '../l10n/app_localizations.dart';
import '../providers/bookmark_provider.dart';

const String _gitSyncMarksUrl = 'https://github.com/d0dg3r/GitSyncMarks';
const String _gitSyncMarksAndroidUrl =
    'https://github.com/d0dg3r/GitSyncMarks-Mobile';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.settings),
          bottom: TabBar(
            isScrollable: false,
            labelStyle: Theme.of(context).textTheme.labelSmall,
            tabs: [
              Tab(icon: const Icon(Icons.settings), text: AppLocalizations.of(context)!.settings),
              Tab(icon: const Icon(Icons.info_outline), text: AppLocalizations.of(context)!.about),
              Tab(icon: const Icon(Icons.help_outline), text: AppLocalizations.of(context)!.help),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _SettingsTabContent(),
            _AboutTab(launchUrl: _launchUrl),
            _HelpTab(launchUrl: _launchUrl),
          ],
        ),
      ),
    );
  }
}

class _SettingsTabContent extends StatefulWidget {
  @override
  State<_SettingsTabContent> createState() => _SettingsTabContentState();
}

class _SettingsTabContentState extends State<_SettingsTabContent> {
  final _tokenController = TextEditingController();
  final _ownerController = TextEditingController();
  final _repoController = TextEditingController();
  final _branchController = TextEditingController();
  final _basePathController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFromProvider());
  }

  void _loadFromProvider() {
    final provider = context.read<BookmarkProvider>();
    if (provider.credentials != null) {
      final c = provider.credentials!;
      _tokenController.text = c.token;
      _ownerController.text = c.owner;
      _repoController.text = c.repo;
      _branchController.text = c.branch;
      _basePathController.text = c.basePath;
    } else {
      _branchController.text = 'main';
      _basePathController.text = 'bookmarks';
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _ownerController.dispose();
    _repoController.dispose();
    _branchController.dispose();
    _basePathController.dispose();
    super.dispose();
  }

  GithubCredentials _buildCredentials() {
    return GithubCredentials(
      token: _tokenController.text.trim(),
      owner: _ownerController.text.trim(),
      repo: _repoController.text.trim(),
      branch: _branchController.text.trim().isEmpty
          ? 'main'
          : _branchController.text.trim(),
      basePath: _basePathController.text.trim().isEmpty
          ? 'bookmarks'
          : _basePathController.text.trim(),
    );
  }

  Future<void> _onSave() async {
    final creds = _buildCredentials();
    if (!creds.isValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.pleaseFillTokenOwnerRepo)),
        );
      }
      return;
    }
    await context.read<BookmarkProvider>().updateCredentials(creds, save: true);
    if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.settingsSaved)),
        );
    }
  }

  Future<void> _onTestConnection() async {
    final creds = _buildCredentials();
    if (!creds.isValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.pleaseFillTokenOwnerRepo)),
        );
      }
      return;
    }

    final success =
        await context.read<BookmarkProvider>().testConnection(creds);
    if (mounted) {
      final provider = context.read<BookmarkProvider>();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (provider.lastSuccessMessage ?? AppLocalizations.of(context)!.connectionSuccessful)
                : (provider.error ?? AppLocalizations.of(context)!.connectionFailed),
          ),
          backgroundColor:
              success ? null : Theme.of(context).colorScheme.errorContainer,
        ),
      );
    }
  }

  Future<void> _onSync() async {
    final creds = _buildCredentials();
    if (!creds.isValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.pleaseFillTokenOwnerRepo)),
        );
      }
      return;
    }

    final provider = context.read<BookmarkProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    await provider.updateCredentials(creds, save: true);
    final success = await provider.syncBookmarks(creds);

    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
              success
              ? (provider.lastSuccessMessage ?? AppLocalizations.of(context)!.syncComplete)
              : (provider.error ?? AppLocalizations.of(context)!.syncFailed),
        ),
        backgroundColor:
            success ? null : Theme.of(context).colorScheme.errorContainer,
      ),
    );
    if (success) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Consumer<BookmarkProvider>(
      builder: (context, provider, _) {
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.cloud, color: scheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.githubConnection,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _tokenController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.personalAccessToken,
                        hintText: AppLocalizations.of(context)!.tokenHint,
                        helperText: AppLocalizations.of(context)!.tokenHelper,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _ownerController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.repositoryOwner,
                        hintText: AppLocalizations.of(context)!.ownerHint,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _repoController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.repositoryName,
                        hintText: AppLocalizations.of(context)!.repoHint,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _branchController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.branch,
                        hintText: AppLocalizations.of(context)!.branchHint,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _basePathController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.basePath,
                        hintText: AppLocalizations.of(context)!.basePathHint,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (provider.availableRootFolderNames.isNotEmpty) ...[
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.folder_open, color: scheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.displayedFolders,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppLocalizations.of(context)!.displayedFoldersHelp,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.outline,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: provider.availableRootFolderNames
                            .map(
                              (name) => FilterChip(
                                label: Text(name),
                                selected:
                                    provider.selectedRootFolders.contains(name),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                onSelected: (selected) {
                                  final current = List<String>.from(
                                      provider.selectedRootFolders);
                                  if (selected) {
                                    current.add(name);
                                  } else {
                                    current.remove(name);
                                  }
                                  provider.setSelectedRootFolders(
                                      current, save: true);
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (provider.isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: _onSave,
                    icon: const Icon(Icons.save, size: 18),
                    label: Text(AppLocalizations.of(context)!.save),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    onPressed: _onTestConnection,
                    icon: const Icon(Icons.link, size: 18),
                    label: Text(AppLocalizations.of(context)!.testConnection),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _onSync,
                    icon: const Icon(Icons.sync, size: 18),
                    label: Text(AppLocalizations.of(context)!.syncBookmarks),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _AboutTab extends StatelessWidget {
  const _AboutTab({required this.launchUrl});

  final Future<void> Function(String url) launchUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Icon(
            Icons.bookmark,
            size: 56,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.appTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            AppLocalizations.of(context)!.version,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.outline,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            AppLocalizations.of(context)!.authorBy,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.outline,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.aboutDescription,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.projects,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppLocalizations.of(context)!.formatFromGitSyncMarks,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.outline,
                        ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => launchUrl(_gitSyncMarksUrl),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.extension, color: scheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.appTitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                Text(
                                  AppLocalizations.of(context)!.gitSyncMarksDesc,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: scheme.outline,
                                      ),
                                ),
                              ],
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
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.licenseMit,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}

class _HelpTab extends StatelessWidget {
  const _HelpTab({required this.launchUrl});

  final Future<void> Function(String url) launchUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.quickGuide,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          _HelpSection(
            title: AppLocalizations.of(context)!.help1Title,
            body: AppLocalizations.of(context)!.help1Body,
          ),
          _HelpSection(
            title: AppLocalizations.of(context)!.help2Title,
            body: AppLocalizations.of(context)!.help2Body,
          ),
          _HelpSection(
            title: AppLocalizations.of(context)!.help3Title,
            body: AppLocalizations.of(context)!.help3Body,
          ),
          _HelpSection(
            title: AppLocalizations.of(context)!.help4Title,
            body: AppLocalizations.of(context)!.help4Body,
          ),
          _HelpSection(
            title: AppLocalizations.of(context)!.help5Title,
            body: AppLocalizations.of(context)!.help5Body,
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.whichRepoFormat,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.repoFormatDescription,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.support,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.supportText,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => launchUrl(_gitSyncMarksAndroidUrl),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.bug_report, color: scheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.gitSyncMarksAndroidIssues,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            body,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
