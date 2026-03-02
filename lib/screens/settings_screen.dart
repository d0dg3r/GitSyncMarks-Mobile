import 'dart:io';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/github_credentials.dart';
import '../models/bookmark_node.dart';
import '../services/github_api.dart';
import '../services/settings_sync_service.dart';
import '../services/storage_service.dart';
import '../l10n/app_localizations.dart';
import '../models/profile.dart';
import '../providers/app_locale_controller.dart';
import '../providers/app_theme_controller.dart';
import '../providers/bookmark_provider.dart';
import '../services/bookmark_export.dart';
import '../services/settings_crypto.dart';
import '../services/settings_import_export.dart';
import '../services/web_import_picker_stub.dart'
    if (dart.library.html) '../services/web_import_picker_web.dart';

const String _gitSyncMarksUrl = 'https://github.com/d0dg3r/GitSyncMarks';
const String _gitSyncMarksAppUrl = 'https://github.com/d0dg3r/GitSyncMarks-App';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late TabController _githubSubTabController;
  late TabController _filesSubTabController;

  final _tokenController = TextEditingController();
  final _ownerController = TextEditingController();
  final _repoController = TextEditingController();
  final _branchController = TextEditingController();
  final _basePathController = TextEditingController();
  final _importExport = SettingsImportExportService();
  final _bookmarkExport = BookmarkExportService();
  String? _loadedProfileId;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 6,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 5),
    );
    _githubSubTabController = TabController(length: 3, vsync: this);
    _filesSubTabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFromProvider());
  }

  void _loadFromProvider() {
    if (!mounted) return;
    final provider = context.read<BookmarkProvider>();
    _loadedProfileId = provider.activeProfileId;
    if (provider.credentials != null) {
      final c = provider.credentials!;
      _tokenController.text = c.token;
      _ownerController.text = c.owner;
      _repoController.text = c.repo;
      _branchController.text = c.branch;
      _basePathController.text = c.basePath;
    } else {
      _tokenController.text = '';
      _ownerController.text = '';
      _repoController.text = '';
      _branchController.text = 'main';
      _basePathController.text = 'bookmarks';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _githubSubTabController.dispose();
    _filesSubTabController.dispose();
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

  void _showSnackBar(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor:
            isError ? Theme.of(context).colorScheme.errorContainer : null,
      ),
    );
  }

  Future<void> _onSave() async {
    final creds = _buildCredentials();
    if (!creds.isValid) {
      _showSnackBar(AppLocalizations.of(context)!.pleaseFillTokenOwnerRepo);
      return;
    }
    await context.read<BookmarkProvider>().updateCredentials(creds, save: true);
    if (mounted) _showSnackBar(AppLocalizations.of(context)!.settingsSaved);
  }

  Future<void> _onTestConnection() async {
    final creds = _buildCredentials();
    if (!creds.isValid) {
      _showSnackBar(AppLocalizations.of(context)!.pleaseFillTokenOwnerRepo);
      return;
    }
    final success =
        await context.read<BookmarkProvider>().testConnection(creds);
    if (mounted) {
      final provider = context.read<BookmarkProvider>();
      _showSnackBar(
        success
            ? (provider.lastSuccessMessage ??
                AppLocalizations.of(context)!.connectionSuccessful)
            : (provider.error ??
                AppLocalizations.of(context)!.connectionFailed),
        isError: !success,
      );
    }
  }

  Future<void> _onSync() async {
    final creds = _buildCredentials();
    if (!creds.isValid) {
      _showSnackBar(AppLocalizations.of(context)!.pleaseFillTokenOwnerRepo);
      return;
    }
    final provider = context.read<BookmarkProvider>();
    await provider.updateCredentials(creds, save: true);
    final success = await provider.syncBookmarks(creds);
    if (!mounted) return;
    _showSnackBar(
      success
          ? (provider.lastSuccessMessage ??
              AppLocalizations.of(context)!.syncComplete)
          : (provider.error ?? AppLocalizations.of(context)!.syncFailed),
      isError: !success,
    );
  }

  Future<void> _onBrowseBasePath() async {
    final l = AppLocalizations.of(context)!;
    final token = _tokenController.text.trim();
    final owner = _ownerController.text.trim();
    final repo = _repoController.text.trim();
    final branch = _branchController.text.trim().isEmpty
        ? 'main'
        : _branchController.text.trim();
    if (token.isEmpty || owner.isEmpty || repo.isEmpty) {
      _showSnackBar(l.pleaseFillTokenOwnerRepo, isError: true);
      return;
    }

    var currentPath = _basePathController.text.trim();
    if (currentPath.isEmpty) currentPath = 'bookmarks';

    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return _BasePathBrowserDialog(
          token: token,
          owner: owner,
          repo: repo,
          branch: branch,
          initialPath: currentPath,
        );
      },
    );
    if (selected != null && selected.trim().isNotEmpty) {
      setState(() {
        _basePathController.text = selected.trim();
      });
    }
  }

  Future<String?> _showTextDialog(
    BuildContext context, {
    required String title,
    required String label,
    required String action,
    String? initialValue,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
          autofocus: true,
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(action),
          ),
        ],
      ),
    );
    return result;
  }

  Future<void> _onImport() async {
    if (_isImporting) return;
    final l = AppLocalizations.of(context)!;
    try {
      final result = kIsWeb
          ? null
          : await FilePicker.platform.pickFiles(
              type: FileType.any,
              allowMultiple: false,
              withData: false,
            );
      WebPickedFile? webFallback;
      if (kIsWeb && (result == null || result.files.isEmpty)) {
        webFallback = await pickFileBytesWithWebFallback();
      }
      if ((result == null || result.files.isEmpty) && webFallback == null) {
        if (mounted) {
          _showSnackBar('No file selected.', isError: true);
        }
        return;
      }
      final picked =
          result?.files.isNotEmpty == true ? result!.files.single : null;
      String content;
      if (kIsWeb) {
        final bytes = picked?.bytes ?? webFallback?.bytes;
        if (bytes == null) return;
        content = utf8.decode(bytes);
      } else {
        final path = picked?.path;
        if (path == null) return;
        content = await File(path).readAsString();
      }

      if (SettingsImportExportService.isEncrypted(content)) {
        if (!mounted) return;
        final password = await _showPasswordDialog(
          context,
          title: l.importPasswordTitle,
          hint: l.importPasswordHint,
          action: l.import_,
          allowEmpty: false,
        );
        if (password == null || password.isEmpty) return;
        try {
          content = await SettingsCrypto.decryptWithPassword(content, password);
        } on FormatException {
          if (mounted) _showSnackBar(l.wrongPassword, isError: true);
          return;
        }
      }

      if (!mounted) return;
      setState(() => _isImporting = true);
      try {
        final parsed = _importExport.parseSettingsJson(content);
        if (!mounted) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l.importSettings),
            content: Text(l.importConfirm(parsed.profiles.length)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.replace),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
        var activeId = parsed.activeProfileId;
        if (!parsed.profiles.any((p) => p.id == activeId)) {
          activeId = parsed.profiles.first.id;
        }
        final selected = parsed.profiles.firstWhere((p) => p.id == activeId);
        if (!selected.credentials.isValid) {
          for (final p in parsed.profiles) {
            if (p.credentials.isValid) {
              activeId = p.id;
              break;
            }
          }
        }
        if (!mounted) return;
        await context.read<BookmarkProvider>().replaceProfiles(
              parsed.profiles,
              activeId: activeId,
              triggerSync: false,
            );
        if (mounted) {
          _loadFromProvider();
          _showSnackBar(l.importSuccess(parsed.profiles.length));
          final provider = context.read<BookmarkProvider>();
          if (provider.hasCredentials) {
            provider.syncBookmarks();
          }
        }
      } finally {
        if (mounted) setState(() => _isImporting = false);
      }
    } catch (e) {
      if (mounted) _showSnackBar(l.importFailed(e.toString()), isError: true);
    }
  }

  Future<void> _onExport() async {
    final l = AppLocalizations.of(context)!;
    try {
      final provider = context.read<BookmarkProvider>();
      if (provider.profiles.isEmpty) {
        _showSnackBar(l.noBookmarksYet, isError: true);
        return;
      }

      final password = await _showPasswordDialog(
        context,
        title: l.exportPasswordTitle,
        hint: l.exportPasswordHint,
        action: l.export_,
      );
      if (password == null) return;

      await _importExport.exportAndShare(
        provider.profiles,
        provider.activeProfileId ?? provider.profiles.first.id,
        password: password.isEmpty ? null : password,
      );
      if (mounted) _showSnackBar(l.exportSuccess);
    } catch (e) {
      if (mounted) _showSnackBar(e.toString(), isError: true);
    }
  }

  Future<String?> _showPasswordDialog(
    BuildContext context, {
    required String title,
    required String hint,
    required String action,
    bool allowEmpty = true,
  }) async {
    final l = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        var isObscured = true;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: Text(title),
            content: TextField(
              controller: controller,
              obscureText: isObscured,
              decoration: InputDecoration(
                hintText: hint,
                suffixIcon: IconButton(
                  tooltip: isObscured ? l.showSecret : l.hideSecret,
                  onPressed: () {
                    setDialogState(() => isObscured = !isObscured);
                  },
                  icon: Icon(
                    isObscured ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
              autofocus: true,
              onSubmitted: (v) => Navigator.pop(ctx, v),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, controller.text),
                child: Text(action),
              ),
            ],
          ),
        );
      },
    );
    return result;
  }

  Future<void> _onExportBookmarks() async {
    final l = AppLocalizations.of(context)!;
    try {
      final provider = context.read<BookmarkProvider>();
      if (provider.rootFolders.isEmpty) {
        _showSnackBar(l.noBookmarksYet, isError: true);
        return;
      }
      await _bookmarkExport.exportAndShare(provider.rootFolders);
      if (mounted) _showSnackBar(l.exportSuccess);
    } catch (e) {
      if (mounted) _showSnackBar(e.toString(), isError: true);
    }
  }

  Future<void> _onClearCache() async {
    final l = AppLocalizations.of(context)!;
    try {
      await context.read<BookmarkProvider>().clearCacheAndSync();
      if (mounted) _showSnackBar(l.clearCacheSuccess);
    } catch (e) {
      if (mounted) _showSnackBar(e.toString(), isError: true);
    }
  }

  Future<void> _onReset() async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.resetConfirmTitle),
        content: Text(l.resetConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.resetAll),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<BookmarkProvider>().resetAll();
    if (mounted) {
      _loadFromProvider();
      _showSnackBar(l.resetSuccess);
      Navigator.of(context).pop();
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Consumer<BookmarkProvider>(
      builder: (context, provider, _) {
        if (_loadedProfileId != provider.activeProfileId) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _loadFromProvider());
        }

        return Stack(
          children: [
            Scaffold(
              appBar: AppBar(
                title: Text(l.settings),
                bottom: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                  tabs: [
                    Tab(text: l.tabGitHub),
                    Tab(text: l.tabSync),
                    Tab(text: l.tabFiles),
                    Tab(text: l.tabGeneral),
                    Tab(text: l.tabHelp),
                    Tab(text: l.tabAbout),
                  ],
                ),
              ),
              body: TabBarView(
                controller: _tabController,
                children: [
                  _GitHubTab(
                    provider: provider,
                    tokenController: _tokenController,
                    ownerController: _ownerController,
                    repoController: _repoController,
                    branchController: _branchController,
                    basePathController: _basePathController,
                    subTabController: _githubSubTabController,
                    onSave: _onSave,
                    onTestConnection: _onTestConnection,
                    onSync: _onSync,
                    onBrowseBasePath: _onBrowseBasePath,
                    showTextDialog: _showTextDialog,
                  ),
                  _SyncTab(provider: provider),
                  _FilesTab(
                    provider: provider,
                    isImporting: _isImporting,
                    onImport: _onImport,
                    onExport: _onExport,
                    onExportBookmarks: _onExportBookmarks,
                    onClearCache: _onClearCache,
                    subTabController: _filesSubTabController,
                  ),
                  const _GeneralTab(),
                  _HelpTab(),
                  _AboutTab(launchUrl: _launchUrl, onReset: _onReset),
                ],
              ),
            ),
            if (_isImporting)
              const Positioned.fill(
                child: ModalBarrier(dismissible: false),
              ),
            if (_isImporting)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(l.importingSettings),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

// =============================================================================
// GitHub Tab (Profile + Connection sub-tabs)
// =============================================================================

class _GitHubTab extends StatelessWidget {
  const _GitHubTab({
    required this.provider,
    required this.tokenController,
    required this.ownerController,
    required this.repoController,
    required this.branchController,
    required this.basePathController,
    required this.subTabController,
    required this.onSave,
    required this.onTestConnection,
    required this.onSync,
    required this.onBrowseBasePath,
    required this.showTextDialog,
  });

  final BookmarkProvider provider;
  final TextEditingController tokenController;
  final TextEditingController ownerController;
  final TextEditingController repoController;
  final TextEditingController branchController;
  final TextEditingController basePathController;
  final TabController subTabController;
  final VoidCallback onSave;
  final VoidCallback onTestConnection;
  final VoidCallback onSync;
  final Future<void> Function() onBrowseBasePath;
  final Future<String?> Function(BuildContext,
      {required String title,
      required String label,
      required String action,
      String? initialValue}) showTextDialog;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TabBar(
            controller: subTabController,
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
            tabs: [
              Tab(text: l.subTabProfile),
              Tab(text: l.subTabConnection),
              Tab(text: l.subTabFolders),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: subTabController,
            children: [
              _ProfileSubTab(
                provider: provider,
                showTextDialog: showTextDialog,
              ),
              _ConnectionSubTab(
                provider: provider,
                tokenController: tokenController,
                ownerController: ownerController,
                repoController: repoController,
                branchController: branchController,
                basePathController: basePathController,
                onSave: onSave,
                onTestConnection: onTestConnection,
                onSync: onSync,
                onBrowseBasePath: onBrowseBasePath,
              ),
              _FoldersSubTab(provider: provider),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileSubTab extends StatelessWidget {
  const _ProfileSubTab({
    required this.provider,
    required this.showTextDialog,
  });

  final BookmarkProvider provider;
  final Future<String?> Function(BuildContext,
      {required String title,
      required String label,
      required String action,
      String? initialValue}) showTextDialog;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(
          title: l.profile,
          trailing: Text(
            l.profileCount(provider.profiles.length, maxProfiles),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.outline,
                ),
          ),
        ),
        Card(
          child: Column(
            children: [
              for (final (i, profile) in provider.profiles.indexed) ...[
                if (i > 0)
                  Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: scheme.outlineVariant),
                _ProfileTile(
                  profile: profile,
                  isActive: profile.id == provider.activeProfileId,
                  onSelect: () => provider.switchProfile(profile.id),
                  onRename: () async {
                    final name = await showTextDialog(context,
                        title: l.renameProfile,
                        label: l.profileName,
                        action: l.rename,
                        initialValue: profile.name);
                    if (name == null || name.trim().isEmpty) return;
                    await provider.renameProfile(profile.id, name.trim());
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(l.profileRenamed(name.trim()))));
                    }
                  },
                  onDelete: provider.profiles.length > 1
                      ? () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(l.deleteProfile),
                              content:
                                  Text(l.deleteProfileConfirm(profile.name)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(l.cancel),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: scheme.error,
                                  ),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text(l.delete),
                                ),
                              ],
                            ),
                          );
                          if (confirmed != true) return;
                          await provider.deleteProfile(profile.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l.profileDeleted)));
                          }
                        }
                      : null,
                ),
              ],
            ],
          ),
        ),
        if (provider.canAddProfile)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: OutlinedButton.icon(
              onPressed: () async {
                final name = await showTextDialog(context,
                    title: l.addProfile, label: l.profileName, action: l.add);
                if (name == null || name.trim().isEmpty) return;
                final profile = await provider.addProfile(name.trim());
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.profileAdded(profile.name))));
                }
              },
              icon: const Icon(Icons.add, size: 18),
              label: Text(l.addProfile),
            ),
          ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _ConnectionSubTab extends StatefulWidget {
  const _ConnectionSubTab({
    required this.provider,
    required this.tokenController,
    required this.ownerController,
    required this.repoController,
    required this.branchController,
    required this.basePathController,
    required this.onSave,
    required this.onTestConnection,
    required this.onSync,
    required this.onBrowseBasePath,
  });

  final BookmarkProvider provider;
  final TextEditingController tokenController;
  final TextEditingController ownerController;
  final TextEditingController repoController;
  final TextEditingController branchController;
  final TextEditingController basePathController;
  final VoidCallback onSave;
  final VoidCallback onTestConnection;
  final VoidCallback onSync;
  final Future<void> Function() onBrowseBasePath;

  @override
  State<_ConnectionSubTab> createState() => _ConnectionSubTabState();
}

class _ConnectionSubTabState extends State<_ConnectionSubTab> {
  bool _obscureToken = true;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final provider = widget.provider;
    final tokenController = widget.tokenController;
    final ownerController = widget.ownerController;
    final repoController = widget.repoController;
    final branchController = widget.branchController;
    final basePathController = widget.basePathController;
    final onSave = widget.onSave;
    final onTestConnection = widget.onTestConnection;
    final onSync = widget.onSync;
    final onBrowseBasePath = widget.onBrowseBasePath;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(title: l.githubConnection),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: tokenController,
                  decoration: InputDecoration(
                    labelText: l.personalAccessToken,
                    hintText: l.tokenHint,
                    helperText: l.tokenHelper,
                    helperMaxLines: 3,
                    suffixIcon: IconButton(
                      tooltip: _obscureToken ? l.showSecret : l.hideSecret,
                      onPressed: () {
                        setState(() => _obscureToken = !_obscureToken);
                      },
                      icon: Icon(
                        _obscureToken ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                  ),
                  obscureText: _obscureToken,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: ownerController,
                  decoration: InputDecoration(
                    labelText: l.repositoryOwner,
                    hintText: l.ownerHint,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: repoController,
                  decoration: InputDecoration(
                    labelText: l.repositoryName,
                    hintText: l.repoHint,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: branchController,
                        decoration: InputDecoration(
                          labelText: l.branch,
                          hintText: l.branchHint,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: basePathController,
                              decoration: InputDecoration(
                                labelText: l.basePath,
                                hintText: l.basePathHint,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.outlined(
                            tooltip: l.basePathBrowseTitle,
                            onPressed: onBrowseBasePath,
                            icon: const Icon(Icons.folder_open),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (provider.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  FilledButton(onPressed: onSave, child: Text(l.save)),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: onTestConnection,
                    child: Text(l.testConnection),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: onSync,
                    child: Text(l.syncBookmarks),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _FoldersSubTab extends StatelessWidget {
  const _FoldersSubTab({required this.provider});

  final BookmarkProvider provider;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (provider.fullRootFolders.isNotEmpty) ...[
          _SectionHeader(title: l.rootFolder),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.rootFolderHelp,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.folder_open),
                    title: Text(provider.viewRootFolder ?? l.allFolders),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showRootFolderPicker(context, provider, l),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (provider.availableRootFolderNames.isNotEmpty) ...[
          _SectionHeader(title: l.displayedFolders),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.displayedFoldersHelp,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: provider.availableRootFolderNames.map((name) {
                      final selected =
                          provider.selectedRootFolders.contains(name);
                      return FilterChip(
                        label: Text(name),
                        selected: selected,
                        showCheckmark: true,
                        onSelected: (sel) {
                          final current =
                              List<String>.from(provider.selectedRootFolders);
                          if (sel) {
                            current.add(name);
                          } else {
                            current.remove(name);
                          }
                          provider.setSelectedRootFolders(current, save: true);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  void _showRootFolderPicker(
    BuildContext context,
    BookmarkProvider provider,
    AppLocalizations l,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (_, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    l.selectRootFolder,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.folder_copy),
                        title: Text(l.allFolders),
                        selected: provider.viewRootFolder == null,
                        onTap: () {
                          provider.setViewRootFolder(null, save: true);
                          Navigator.pop(ctx);
                        },
                      ),
                      const Divider(),
                      ..._buildFolderTree(
                        ctx,
                        provider,
                        provider.fullRootFolders,
                        '',
                        0,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<Widget> _buildFolderTree(
    BuildContext context,
    BookmarkProvider provider,
    List<BookmarkFolder> folders,
    String parentPath,
    int depth,
  ) {
    final widgets = <Widget>[];
    for (final folder in folders) {
      final dirName = folder.dirName ?? folder.title;
      final path = parentPath.isEmpty ? dirName : '$parentPath/$dirName';
      final subfolders = folder.children.whereType<BookmarkFolder>().toList();
      final isSelected = provider.viewRootFolder == path;

      widgets.add(
        ListTile(
          contentPadding: EdgeInsets.only(left: 16.0 + depth * 24.0, right: 16),
          leading: Icon(
            subfolders.isNotEmpty ? Icons.folder : Icons.folder_outlined,
          ),
          title: Text(folder.title),
          selected: isSelected,
          onTap: () {
            provider.setViewRootFolder(path, save: true);
            Navigator.pop(context);
          },
        ),
      );

      if (subfolders.isNotEmpty) {
        widgets.addAll(
          _buildFolderTree(context, provider, subfolders, path, depth + 1),
        );
      }
    }
    return widgets;
  }
}

class _BasePathBrowserDialog extends StatefulWidget {
  const _BasePathBrowserDialog({
    required this.token,
    required this.owner,
    required this.repo,
    required this.branch,
    required this.initialPath,
  });

  final String token;
  final String owner;
  final String repo;
  final String branch;
  final String initialPath;

  @override
  State<_BasePathBrowserDialog> createState() => _BasePathBrowserDialogState();
}

class _BasePathBrowserDialogState extends State<_BasePathBrowserDialog> {
  late String _currentPath;
  bool _isLoading = false;
  String? _error;
  List<ContentEntry> _dirs = [];

  @override
  void initState() {
    super.initState();
    _currentPath = widget.initialPath.trim();
    _load(_currentPath);
  }

  Future<void> _load(String path) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final api = GithubApi(
      token: widget.token,
      owner: widget.owner,
      repo: widget.repo,
      branch: widget.branch,
      basePath: '',
    );
    try {
      final entries = await api.getContents(path);
      final dirs = entries.where((e) => e.type == 'dir').toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      if (!mounted) return;
      setState(() {
        _currentPath = path;
        _dirs = dirs;
        _isLoading = false;
      });
    } on GithubApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.message;
      });
    } finally {
      api.close();
    }
  }

  String _parentOf(String path) {
    final clean = path.trim().replaceAll(RegExp(r'/+$'), '');
    if (clean.isEmpty || !clean.contains('/')) return '';
    return clean.substring(0, clean.lastIndexOf('/'));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l.basePathBrowseTitle),
      content: SizedBox(
        width: 520,
        height: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _currentPath.isEmpty ? '/' : _currentPath,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            if (_currentPath.isNotEmpty)
              ListTile(
                dense: true,
                leading: const Icon(Icons.arrow_upward),
                title: const Text('..'),
                onTap: () => _load(_parentOf(_currentPath)),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: _dirs.length,
                          itemBuilder: (_, i) {
                            final dir = _dirs[i];
                            final nextPath = _currentPath.isEmpty
                                ? dir.name
                                : '$_currentPath/${dir.name}';
                            return ListTile(
                              leading: const Icon(Icons.folder),
                              title: Text(dir.name),
                              onTap: () => _load(nextPath),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
              context, _currentPath.isEmpty ? 'bookmarks' : _currentPath),
          child: Text(l.selectFolder),
        ),
      ],
    );
  }
}

// =============================================================================
// Sync Tab
// =============================================================================

class _SyncTab extends StatelessWidget {
  const _SyncTab({required this.provider});

  final BookmarkProvider provider;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final active = provider.activeProfile;
    final selectedProfile = active?.syncProfile ?? 'normal';
    final isCustomProfile = selectedProfile == 'custom';
    const customIntervalMin = 1;
    const customIntervalMax = 1440;

    String syncProfileLabel(String key) {
      switch (key) {
        case 'realtime':
          return l.syncProfileRealtime;
        case 'frequent':
          return l.syncProfileFrequent;
        case 'normal':
          return l.syncProfileNormal;
        case 'powersave':
          return l.syncProfilePowersave;
        case 'custom':
          return l.syncProfileCustom;
        default:
          return l.syncProfileNormal;
      }
    }

    Future<void> saveCustomInterval(String raw) async {
      final parsed = int.tryParse(raw.trim());
      if (parsed == null ||
          parsed < customIntervalMin ||
          parsed > customIntervalMax) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l.customSyncIntervalErrorRange(
                    customIntervalMin, customIntervalMax),
              ),
            ),
          );
        }
        return;
      }
      if (parsed == active?.customIntervalMinutes) return;
      await provider.updateSyncSettings(customIntervalMinutes: parsed);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(title: l.tabSync),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: Text(l.automaticSync),
                  value: active?.autoSyncEnabled ?? false,
                  onChanged: (v) async {
                    await provider.updateSyncSettings(autoSyncEnabled: v);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Auto-sync updated')));
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Sync profile'),
                  trailing: DropdownButton<String>(
                    value: selectedProfile,
                    items: [
                      'realtime',
                      'frequent',
                      'normal',
                      'powersave',
                      'custom'
                    ]
                        .map((k) => DropdownMenuItem<String>(
                              value: k,
                              child: Text(syncProfileLabel(k)),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        provider.updateSyncSettings(syncProfile: v);
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.syncProfileMeaningTitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text('• ${l.syncProfileMeaningRealtime}'),
                      Text('• ${l.syncProfileMeaningFrequent}'),
                      Text('• ${l.syncProfileMeaningNormal}'),
                      Text('• ${l.syncProfileMeaningPowersave}'),
                      Text('• ${l.syncProfileMeaningCustom}'),
                      if (isCustomProfile) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          key: ValueKey(
                            'custom-sync-${active?.id ?? 'none'}-${active?.customIntervalMinutes ?? 15}',
                          ),
                          initialValue:
                              (active?.customIntervalMinutes ?? 15).toString(),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: l.customSyncIntervalLabel,
                            hintText: l.customSyncIntervalHint,
                          ),
                          onChanged: (raw) {
                            final parsed = int.tryParse(raw.trim());
                            if (parsed == null ||
                                parsed < customIntervalMin ||
                                parsed > customIntervalMax) {
                              return;
                            }
                            if (parsed != active?.customIntervalMinutes) {
                              provider.updateSyncSettings(
                                  customIntervalMinutes: parsed);
                            }
                          },
                          onFieldSubmitted: saveCustomInterval,
                        ),
                      ],
                    ],
                  ),
                ),
                SwitchListTile(
                  title: Text(l.syncOnStart),
                  value: active?.syncOnStart ?? false,
                  onChanged: (v) {
                    provider.updateSyncSettings(syncOnStart: v);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// =============================================================================
// Files Tab
// =============================================================================

class _FilesTab extends StatelessWidget {
  const _FilesTab({
    required this.provider,
    required this.isImporting,
    required this.onImport,
    required this.onExport,
    required this.onExportBookmarks,
    required this.onClearCache,
    required this.subTabController,
  });

  final BookmarkProvider provider;
  final bool isImporting;
  final VoidCallback onImport;
  final VoidCallback onExport;
  final VoidCallback onExportBookmarks;
  final Future<void> Function() onClearCache;
  final TabController subTabController;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TabBar(
            controller: subTabController,
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
            tabs: [
              Tab(text: l.subTabExportImport),
              Tab(text: l.subTabSettings),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: subTabController,
            children: [
              _ExportImportSubTab(
                isImporting: isImporting,
                onImport: onImport,
                onExport: onExport,
                onExportBookmarks: onExportBookmarks,
                onClearCache: onClearCache,
              ),
              _SettingsSyncSubTab(provider: provider),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExportImportSubTab extends StatelessWidget {
  const _ExportImportSubTab({
    required this.isImporting,
    required this.onImport,
    required this.onExport,
    required this.onExportBookmarks,
    required this.onClearCache,
  });

  final bool isImporting;
  final VoidCallback onImport;
  final VoidCallback onExport;
  final VoidCallback onExportBookmarks;
  final Future<void> Function() onClearCache;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(title: l.importExport),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.importSettingsDesc,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.outline),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isImporting ? null : onImport,
                        icon: const Icon(Icons.file_download, size: 18),
                        label: Text(l.importSettings),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onExport,
                        icon: const Icon(Icons.file_upload, size: 18),
                        label: Text(l.exportSettings),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: onExportBookmarks,
                  icon: const Icon(Icons.bookmark, size: 18),
                  label: Text(l.exportBookmarks),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SectionHeader(title: l.clearCache),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.clearCacheDesc,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.outline),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => onClearCache(),
                  icon: const Icon(Icons.cleaning_services, size: 18),
                  label: Text(l.clearCache),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _SettingsSyncSubTab extends StatefulWidget {
  const _SettingsSyncSubTab({required this.provider});

  final BookmarkProvider provider;

  @override
  State<_SettingsSyncSubTab> createState() => _SettingsSyncSubTabState();
}

class _SettingsSyncSubTabState extends State<_SettingsSyncSubTab> {
  final _syncService = SettingsSyncService();
  final _storage = StorageService();
  final _passwordController = TextEditingController();
  final _clientNameController = TextEditingController();
  bool _isLoading = false;
  bool _syncSettingsToGit = false;
  String _settingsSyncMode = 'individual';
  bool _hasStoredPassword = false;
  bool _obscureSettingsSyncPassword = true;
  String? _clientName;
  List<DeviceConfigEntry> _deviceConfigs = [];
  String? _selectedDeviceFilename;

  @override
  void initState() {
    super.initState();
    _loadStoredState();
  }

  Future<void> _loadStoredState() async {
    final syncToGit = await _storage.loadSyncSettingsToGit();
    final mode = await _storage.loadSettingsSyncMode();
    final has = await _storage.hasSettingsSyncPassword();
    final clientName = await _storage.loadSettingsSyncClientName();
    if (mounted) {
      setState(() {
        _syncSettingsToGit = syncToGit;
        _settingsSyncMode = mode;
        _hasStoredPassword = has;
        _clientName = clientName;
        _clientNameController.text = clientName ?? '';
      });
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _clientNameController.dispose();
    super.dispose();
  }

  void _showSnackBar(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor:
            isError ? Theme.of(context).colorScheme.errorContainer : null,
      ),
    );
  }

  Future<String> _getPassword() async {
    final entered = _passwordController.text.trim();
    if (entered.isNotEmpty) return entered;
    final stored = await _storage.loadSettingsSyncPassword();
    return stored ?? '';
  }

  Future<void> _onToggleSyncToGit(bool v) async {
    await _storage.saveSyncSettingsToGit(v);
    if (!v) {
      await _storage.deleteSettingsSyncPassword();
      _passwordController.clear();
    }
    if (mounted) {
      setState(() {
        _syncSettingsToGit = v;
        _hasStoredPassword = v && _hasStoredPassword;
      });
    }
  }

  Future<void> _onPush() async {
    final l = AppLocalizations.of(context)!;
    final creds = widget.provider.credentials;
    if (creds == null || !creds.isValid) {
      _showSnackBar(l.pleaseFillTokenOwnerRepo, isError: true);
      return;
    }
    final password = await _getPassword();
    if (password.isEmpty) {
      _showSnackBar(l.settingsSyncPasswordMissing, isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final deviceId = await _storage.getOrCreateDeviceId();
      final syncToGit = await _storage.loadSyncSettingsToGit();
      final mode = await _storage.loadSettingsSyncMode();
      final clientName = await _storage.loadSettingsSyncClientName();
      if (clientName == null || clientName.isEmpty) {
        if (mounted) {
          _showSnackBar(l.settingsSyncClientNameRequired, isError: true);
        }
        return;
      }
      await _syncService.push(
        creds,
        widget.provider.profiles,
        widget.provider.activeProfileId ?? widget.provider.profiles.first.id,
        password,
        mode: mode,
        deviceId: deviceId,
        clientName: clientName,
        syncSettingsToGit: syncToGit,
        settingsSyncMode: mode,
      );
      await _storage.saveSettingsSyncPassword(password);
      if (mounted) _showSnackBar(l.settingsSaved);
    } catch (e) {
      if (mounted) _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onPull() async {
    final l = AppLocalizations.of(context)!;
    final creds = widget.provider.credentials;
    if (creds == null || !creds.isValid) {
      _showSnackBar(l.pleaseFillTokenOwnerRepo, isError: true);
      return;
    }
    final password = await _getPassword();
    if (password.isEmpty) {
      _showSnackBar(l.settingsSyncPasswordMissing, isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      const mode = 'individual';
      final clientName = await _storage.loadSettingsSyncClientName();
      final result = await _syncService.pull(
        creds,
        password,
        mode: mode,
        clientName: clientName,
      );
      await _storage.saveSettingsSyncPassword(password);
      if (result.syncSettingsToGit != null) {
        await _storage.saveSyncSettingsToGit(result.syncSettingsToGit!);
      }
      if (result.settingsSyncMode != null) {
        await _storage.saveSettingsSyncMode(result.settingsSyncMode!);
      }
      await widget.provider.replaceProfiles(
        result.profiles,
        activeId: result.activeProfileId,
      );
      if (mounted) {
        await _loadStoredState();
        _showSnackBar(l.importSuccess(result.profiles.length));
      }
    } catch (e) {
      if (mounted) _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onSavePassword() async {
    final l = AppLocalizations.of(context)!;
    final pw = _passwordController.text.trim();
    if (pw.isEmpty) {
      _showSnackBar(l.settingsSyncPasswordMissing, isError: true);
      return;
    }
    await _storage.saveSettingsSyncPassword(pw);
    if (mounted) setState(() => _hasStoredPassword = true);
    _showSnackBar(l.settingsSaved);
  }

  Future<void> _onClearPassword() async {
    await _storage.deleteSettingsSyncPassword();
    if (mounted) setState(() => _hasStoredPassword = false);
  }

  Future<void> _onLoadConfigs() async {
    final l = AppLocalizations.of(context)!;
    final creds = widget.provider.credentials;
    if (creds == null || !creds.isValid) {
      _showSnackBar(l.pleaseFillTokenOwnerRepo, isError: true);
      return;
    }
    final clientName = (_clientNameController.text).trim();
    if (clientName.isEmpty) {
      _showSnackBar(l.settingsSyncClientNameRequired, isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final configs = await _syncService.listRemoteDeviceConfigs(creds);
      if (mounted) {
        setState(() {
          _deviceConfigs = configs;
          _selectedDeviceFilename =
              configs.isNotEmpty ? configs.first.filename : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar(e.toString(), isError: true);
      }
    }
  }

  String _configLabel(DeviceConfigEntry c) {
    return c.filename == 'settings.enc'
        ? 'Global (${c.filename})'
        : 'Client ${c.deviceId} (${c.filename})';
  }

  void _showConfigPicker() {
    if (_deviceConfigs.isEmpty) return;
    showModalBottomSheet<String?>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  AppLocalizations.of(context)!.settingsSyncImportTitle,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _deviceConfigs.length,
                  itemBuilder: (_, i) {
                    final c = _deviceConfigs[i];
                    final selected = _selectedDeviceFilename == c.filename;
                    return ListTile(
                      title: Text(
                        _configLabel(c),
                        maxLines: 2,
                        overflow: TextOverflow.fade,
                      ),
                      selected: selected,
                      onTap: () {
                        setState(() => _selectedDeviceFilename = c.filename);
                        Navigator.pop(ctx, c.filename);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onImportDeviceConfig() async {
    final l = AppLocalizations.of(context)!;
    final filename = _selectedDeviceFilename;
    if (filename == null || filename.isEmpty) {
      _showSnackBar(l.settingsSyncImportEmpty, isError: true);
      return;
    }
    final creds = widget.provider.credentials;
    if (creds == null || !creds.isValid) {
      _showSnackBar(l.pleaseFillTokenOwnerRepo, isError: true);
      return;
    }
    final clientName = (_clientNameController.text).trim();
    if (clientName.isEmpty) {
      _showSnackBar(l.settingsSyncClientNameRequired, isError: true);
      return;
    }
    final password = await _getPassword();
    if (password.isEmpty) {
      _showSnackBar(l.settingsSyncPasswordMissing, isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _syncService.importDeviceConfig(
        creds,
        filename,
        password,
        storage: _storage,
        applyProfiles: (r) => widget.provider.replaceProfiles(
          r.profiles,
          activeId: r.activeProfileId,
        ),
      );
      await _storage.saveSettingsSyncPassword(password);
      if (mounted) {
        await _loadStoredState();
        _showSnackBar(l.settingsSyncImportSuccess);
      }
    } catch (e) {
      if (mounted) _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onCreateClientSetting() async {
    final l = AppLocalizations.of(context)!;
    final clientName = _clientNameController.text.trim();
    if (clientName.isEmpty) {
      _showSnackBar(l.settingsSyncClientNameRequired, isError: true);
      return;
    }
    await _storage.saveSettingsSyncClientName(clientName);
    if (mounted) {
      setState(() => _clientName = clientName);
    }
    await _onPush();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(title: l.settingsSyncToGit),
        // Card 1: Main toggle, sync mode, password
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SwitchListTile(
                  value: _syncSettingsToGit,
                  onChanged: (v) => _onToggleSyncToGit(v),
                  title: Text(l.settingsSyncToGit),
                  contentPadding: EdgeInsets.zero,
                ),
                if (_syncSettingsToGit) ...[
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _settingsSyncMode,
                    decoration: InputDecoration(
                      labelText: l.settingsSyncModeLabel,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'individual',
                        child: Text(l.settingsSyncModeIndividual),
                      ),
                    ],
                    onChanged: null,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _clientNameController,
                    decoration: InputDecoration(
                      labelText: l.settingsSyncClientName,
                      hintText: l.settingsSyncClientNameHint,
                    ),
                    onChanged: (value) async {
                      final trimmed = value.trim();
                      if (trimmed.isEmpty) {
                        await _storage.saveSettingsSyncClientName('');
                      } else {
                        await _storage.saveSettingsSyncClientName(trimmed);
                      }
                      if (mounted) {
                        setState(
                          () => _clientName = trimmed.isEmpty ? null : trimmed,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_hasStoredPassword)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l.settingsSyncPasswordSaved,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          TextButton(
                            onPressed: _isLoading ? null : _onClearPassword,
                            child: Text(l.settingsSyncClearPassword),
                          ),
                        ],
                      ),
                    ),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscureSettingsSyncPassword,
                    decoration: InputDecoration(
                      labelText: l.settingsSyncPassword,
                      hintText: l.settingsSyncPasswordHint,
                      suffixIcon: IconButton(
                        tooltip: _obscureSettingsSyncPassword
                            ? l.showSecret
                            : l.hideSecret,
                        onPressed: () {
                          setState(() {
                            _obscureSettingsSyncPassword =
                                !_obscureSettingsSyncPassword;
                          });
                        },
                        icon: Icon(
                          _obscureSettingsSyncPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _onPush(),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _isLoading ? null : _onSavePassword,
                    child: Text(l.settingsSyncSaveBtn),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_syncSettingsToGit) ...[
          const SizedBox(height: 20),
          // Card 2: Import from other device
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.settingsSyncImportTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _isLoading ||
                            (_clientName == null || _clientName!.isEmpty)
                        ? null
                        : _onLoadConfigs,
                    child: Text(l.settingsSyncLoadConfigs),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _isLoading ||
                            (_clientName == null || _clientName!.isEmpty)
                        ? null
                        : _onCreateClientSetting,
                    child: Text(l.settingsSyncCreateBtn),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _deviceConfigs.isEmpty ? null : _showConfigPicker,
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              Theme.of(context).colorScheme.outline.withValues(
                                    alpha: 0.5,
                                  ),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedDeviceFilename != null
                                  ? _configLabel(_deviceConfigs.firstWhere(
                                      (c) =>
                                          c.filename == _selectedDeviceFilename,
                                      orElse: () => DeviceConfigEntry(
                                        filename: _selectedDeviceFilename!,
                                        deviceId: '?',
                                      ),
                                    ))
                                  : l.settingsSyncImportEmpty,
                              maxLines: 2,
                              overflow: TextOverflow.fade,
                            ),
                          ),
                          if (_deviceConfigs.isNotEmpty)
                            Icon(
                              Icons.arrow_drop_down,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _isLoading ||
                            _selectedDeviceFilename == null ||
                            (_clientName == null || _clientName!.isEmpty)
                        ? null
                        : _onImportDeviceConfig,
                    child: Text(l.settingsSyncImport),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (_syncSettingsToGit) ...[
          const SizedBox(height: 20),
          // Card 3: Push / Pull
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _onPush,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload, size: 18),
                      label: Text(l.settingsSyncPush),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _onPull,
                      icon: const Icon(Icons.download, size: 18),
                      label: Text(l.settingsSyncPull),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}

// =============================================================================
// General Tab
// =============================================================================

class _GeneralTab extends StatelessWidget {
  const _GeneralTab();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final localeController = context.watch<AppLocaleController>();
    final themeController = context.watch<AppThemeController>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(title: l.tabGeneral),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.generalLanguageTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key:
                      ValueKey('app-language-${localeController.languageCode}'),
                  initialValue: localeController.languageCode,
                  decoration: InputDecoration(labelText: l.appLanguage),
                  items: [
                    DropdownMenuItem(
                      value: 'system',
                      child: Text(l.appLanguageSystem),
                    ),
                    DropdownMenuItem(
                      value: 'de',
                      child: Text(l.appLanguageGerman),
                    ),
                    DropdownMenuItem(
                      value: 'en',
                      child: Text(l.appLanguageEnglish),
                    ),
                    DropdownMenuItem(
                      value: 'es',
                      child: Text(l.appLanguageSpanish),
                    ),
                    DropdownMenuItem(
                      value: 'fr',
                      child: Text(l.appLanguageFrench),
                    ),
                    DropdownMenuItem(
                      value: 'pt_BR',
                      child: Text(l.appLanguagePortugueseBrazil),
                    ),
                    DropdownMenuItem(
                      value: 'it',
                      child: Text(l.appLanguageItalian),
                    ),
                    DropdownMenuItem(
                      value: 'ja',
                      child: Text(l.appLanguageJapanese),
                    ),
                    DropdownMenuItem(
                      value: 'zh_CN',
                      child: Text(l.appLanguageChineseSimplified),
                    ),
                    DropdownMenuItem(
                      value: 'ko',
                      child: Text(l.appLanguageKorean),
                    ),
                    DropdownMenuItem(
                      value: 'ru',
                      child: Text(l.appLanguageRussian),
                    ),
                    DropdownMenuItem(
                      value: 'tr',
                      child: Text(l.appLanguageTurkish),
                    ),
                    DropdownMenuItem(
                      value: 'pl',
                      child: Text(l.appLanguagePolish),
                    ),
                  ],
                  onChanged: (value) async {
                    if (value == null) return;
                    await localeController.setLanguageCode(value);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l.settingsSaved)),
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  l.generalThemeTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey('app-theme-${themeController.themeModeKey}'),
                  initialValue: themeController.themeModeKey,
                  decoration: InputDecoration(labelText: l.appTheme),
                  items: [
                    DropdownMenuItem(
                      value: 'system',
                      child: Text(l.appThemeSystem),
                    ),
                    DropdownMenuItem(
                      value: 'light',
                      child: Text(l.appThemeLight),
                    ),
                    DropdownMenuItem(
                      value: 'dark',
                      child: Text(l.appThemeDark),
                    ),
                  ],
                  onChanged: (value) async {
                    if (value == null) return;
                    await themeController.setThemeModeKey(value);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l.settingsSaved)),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// =============================================================================
// Help Tab
// =============================================================================

class _HelpTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(title: l.quickGuide),
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
        _SectionHeader(title: l.support),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.supportText,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                _HelpLink(
                  icon: Icons.bug_report,
                  label: l.reportIssue,
                  url: '$_gitSyncMarksAppUrl/issues',
                  onLaunch: () async {
                    await launchUrl(Uri.parse('$_gitSyncMarksAppUrl/issues'),
                        mode: LaunchMode.externalApplication);
                  },
                ),
                const SizedBox(height: 8),
                _HelpLink(
                  icon: Icons.description,
                  label: l.documentation,
                  url: '$_gitSyncMarksUrl/tree/main/docs',
                  onLaunch: () async {
                    await launchUrl(
                        Uri.parse('$_gitSyncMarksUrl/tree/main/docs'),
                        mode: LaunchMode.externalApplication);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _HelpLink extends StatelessWidget {
  const _HelpLink({
    required this.icon,
    required this.label,
    required this.url,
    required this.onLaunch,
  });

  final IconData icon;
  final String label;
  final String url;
  final VoidCallback onLaunch;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onLaunch,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: scheme.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: scheme.primary),
              ),
            ),
            Icon(Icons.open_in_new, size: 18, color: scheme.outline),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// About Tab
// =============================================================================

class _AboutTab extends StatelessWidget {
  const _AboutTab({required this.launchUrl, required this.onReset});

  final Future<void> Function(String) launchUrl;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
                    style:
                        textTheme.bodyMedium?.copyWith(color: scheme.outline),
                  );
                },
              ),
              const SizedBox(height: 2),
              Text(
                l.authorBy,
                style: textTheme.bodyMedium?.copyWith(color: scheme.outline),
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
                  style: textTheme.bodySmall?.copyWith(color: scheme.outline),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => launchUrl(_gitSyncMarksUrl),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Row(
                      children: [
                        Icon(Icons.extension, color: scheme.primary, size: 22),
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
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => launchUrl(_gitSyncMarksAppUrl),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Row(
                      children: [
                        Icon(Icons.phone_android,
                            color: scheme.primary, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'GitSyncMarks-App',
                            style: textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w500),
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
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: onReset,
                  icon:
                      Icon(Icons.delete_forever, size: 18, color: scheme.error),
                  label: Text(
                    l.resetAll,
                    style: TextStyle(color: scheme.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side:
                        BorderSide(color: scheme.error.withValues(alpha: 0.5)),
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
        const SizedBox(height: 32),
      ],
    );
  }
}

// =============================================================================
// Shared widgets
// =============================================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8, top: 4),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.profile,
    required this.isActive,
    required this.onSelect,
    required this.onRename,
    this.onDelete,
  });

  final Profile profile;
  final bool isActive;
  final VoidCallback onSelect;
  final VoidCallback onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(
        isActive ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isActive ? scheme.primary : scheme.outline,
        size: 20,
      ),
      title: Text(
        profile.name,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: profile.credentials.isValid
          ? Text(
              '${profile.credentials.owner}/${profile.credentials.repo}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.outline),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 18, color: scheme.outline),
            onPressed: onRename,
            visualDensity: VisualDensity.compact,
          ),
          if (onDelete != null)
            IconButton(
              icon: Icon(Icons.delete_outline, size: 18, color: scheme.error),
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
      onTap: isActive ? null : onSelect,
    );
  }
}

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
