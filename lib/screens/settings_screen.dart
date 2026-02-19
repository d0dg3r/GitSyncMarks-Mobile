import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/github_credentials.dart';
import '../l10n/app_localizations.dart';
import '../models/profile.dart';
import '../providers/bookmark_provider.dart';
import '../services/settings_import_export.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _tokenController = TextEditingController();
  final _ownerController = TextEditingController();
  final _repoController = TextEditingController();
  final _branchController = TextEditingController();
  final _basePathController = TextEditingController();
  final _importExport = SettingsImportExportService();
  String? _loadedProfileId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFromProvider());
  }

  void _loadFromProvider() {
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
    if (mounted) {
      _showSnackBar(AppLocalizations.of(context)!.settingsSaved);
    }
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
    final l = AppLocalizations.of(context)!;
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) return;
      final content = await File(path).readAsString();
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
      await context.read<BookmarkProvider>().replaceProfiles(
            parsed.profiles,
            activeId: parsed.activeProfileId,
          );
      if (mounted) {
        _showSnackBar(l.importSuccess(parsed.profiles.length));
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(l.importFailed(e.toString()), isError: true);
      }
    }
  }

  Future<void> _onExport() async {
    final l = AppLocalizations.of(context)!;
    try {
      final provider = context.read<BookmarkProvider>();
      await _importExport.exportAndShare(
        provider.profiles,
        provider.activeProfileId ?? provider.profiles.first.id,
      );
      if (mounted) _showSnackBar(l.exportSuccess);
    } catch (e) {
      if (mounted) _showSnackBar(e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<BookmarkProvider>(
      builder: (context, provider, _) {
        if (_loadedProfileId != provider.activeProfileId) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _loadFromProvider());
        }

        return Scaffold(
          appBar: AppBar(title: Text(l.settings)),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              // ── Section: Connection ──
              _SectionHeader(title: l.githubConnection),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _tokenController,
                        decoration: InputDecoration(
                          labelText: l.personalAccessToken,
                          hintText: l.tokenHint,
                          helperText: l.tokenHelper,
                          helperMaxLines: 3,
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _ownerController,
                        decoration: InputDecoration(
                          labelText: l.repositoryOwner,
                          hintText: l.ownerHint,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _repoController,
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
                              controller: _branchController,
                              decoration: InputDecoration(
                                labelText: l.branch,
                                hintText: l.branchHint,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _basePathController,
                              decoration: InputDecoration(
                                labelText: l.basePath,
                                hintText: l.basePathHint,
                              ),
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
                        FilledButton(
                          onPressed: _onSave,
                          child: Text(l.save),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: _onTestConnection,
                          child: Text(l.testConnection),
                        ),
                        const SizedBox(height: 8),
                        FilledButton.tonal(
                          onPressed: _onSync,
                          child: Text(l.syncBookmarks),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Section: Profile ──
              _SectionHeader(
                title: l.profile,
                trailing: Text(
                  l.profileCount(provider.profiles.length, maxProfiles),
                  style: textTheme.bodySmall?.copyWith(color: scheme.outline),
                ),
              ),
              Card(
                child: Column(
                  children: [
                    for (final (i, profile)
                        in provider.profiles.indexed) ...[
                      if (i > 0)
                        Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: scheme.outlineVariant),
                      _ProfileTile(
                        profile: profile,
                        isActive:
                            profile.id == provider.activeProfileId,
                        onSelect: () =>
                            provider.switchProfile(profile.id),
                        onRename: () async {
                          final name = await _showTextDialog(
                            context,
                            title: l.renameProfile,
                            label: l.profileName,
                            action: l.rename,
                            initialValue: profile.name,
                          );
                          if (name == null || name.trim().isEmpty) return;
                          await provider.renameProfile(
                              profile.id, name.trim());
                          if (context.mounted) {
                            _showSnackBar(
                                l.profileRenamed(name.trim()));
                          }
                        },
                        onDelete: provider.profiles.length > 1
                            ? () async {
                                final confirmed =
                                    await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(l.deleteProfile),
                                    content: Text(
                                        l.deleteProfileConfirm(
                                            profile.name)),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: Text(l.cancel),
                                      ),
                                      FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: scheme.error,
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: Text(l.delete),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed != true) return;
                                await provider.deleteProfile(profile.id);
                                if (context.mounted) {
                                  _showSnackBar(l.profileDeleted);
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
                      final name = await _showTextDialog(
                        context,
                        title: l.addProfile,
                        label: l.profileName,
                        action: l.add,
                      );
                      if (name == null || name.trim().isEmpty) return;
                      final profile =
                          await provider.addProfile(name.trim());
                      if (context.mounted) {
                        _showSnackBar(l.profileAdded(profile.name));
                      }
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l.addProfile),
                  ),
                ),

              const SizedBox(height: 24),

              // ── Section: Folders ──
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
                          style: textTheme.bodySmall
                              ?.copyWith(color: scheme.outline),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: provider.availableRootFolderNames
                              .map((name) {
                            final selected = provider.selectedRootFolders
                                .contains(name);
                            return FilterChip(
                              label: Text(name),
                              selected: selected,
                              showCheckmark: true,
                              onSelected: (sel) {
                                final current = List<String>.from(
                                    provider.selectedRootFolders);
                                if (sel) {
                                  current.add(name);
                                } else {
                                  current.remove(name);
                                }
                                provider.setSelectedRootFolders(current,
                                    save: true);
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ── Section: Import / Export ──
              _SectionHeader(title: l.importExport),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l.importSettingsDesc,
                        style: textTheme.bodySmall
                            ?.copyWith(color: scheme.outline),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _onImport,
                              icon: const Icon(Icons.file_download, size: 18),
                              label: Text(l.importSettings),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _onExport,
                              icon: const Icon(Icons.file_upload, size: 18),
                              label: Text(l.exportSettings),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

// =============================================================================
// Section header
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

// =============================================================================
// Profile tile
// =============================================================================

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
