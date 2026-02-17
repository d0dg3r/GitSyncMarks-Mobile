import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/bookmark_node.dart';
import '../providers/bookmark_provider.dart';
import '../utils/favicon_utils.dart';

class BookmarkListScreen extends StatelessWidget {
  const BookmarkListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(Icons.bookmark, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(AppLocalizations.of(context)!.appTitle),
        centerTitle: true,
        actions: [
          Consumer<BookmarkProvider>(
            builder: (context, provider, _) {
              if (!provider.hasCredentials) return const SizedBox.shrink();
              return IconButton(
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                onPressed: provider.isLoading ? null : () => provider.syncBookmarks(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Consumer<BookmarkProvider>(
        builder: (context, provider, _) {
          if (provider.error != null) {
            return _ErrorView(
              message: provider.error!,
              onRetry: () {
                provider.clearError();
                provider.syncBookmarks();
              },
              onSettings: () => Navigator.pushNamed(context, '/settings'),
            );
          }

          if (!provider.hasCredentials) {
            return _EmptyState(onOpenSettings: () {
              Navigator.pushNamed(context, '/settings');
            });
          }

          if (provider.isLoading && !provider.hasBookmarks) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!provider.hasBookmarks) {
            return _EmptyState(
              hasCredentials: true,
              onSync: () => provider.syncBookmarks(),
              onOpenSettings: () => Navigator.pushNamed(context, '/settings'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.syncBookmarks().then((_) async {}),
            child: _BookmarkTreeView(folders: provider.displayedRootFolders),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    this.hasCredentials = false,
    this.onSync,
    required this.onOpenSettings,
  });

  final bool hasCredentials;
  final VoidCallback? onSync;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 48,
              color: scheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.noBookmarksYet,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              hasCredentials
                  ? AppLocalizations.of(context)!.tapSyncToFetch
                  : AppLocalizations.of(context)!.configureInSettings,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (hasCredentials && onSync != null)
              FilledButton.icon(
                onPressed: onSync,
                icon: const Icon(Icons.sync, size: 18),
                label: Text(AppLocalizations.of(context)!.sync),
              ),
            if (hasCredentials && onSync != null) const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: onOpenSettings,
              icon: const Icon(Icons.settings, size: 18),
              label: Text(AppLocalizations.of(context)!.openSettings),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.onSettings,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: scheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.error,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.error,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(AppLocalizations.of(context)!.retry),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: onSettings,
              icon: const Icon(Icons.settings, size: 18),
              label: Text(AppLocalizations.of(context)!.settings),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookmarkTreeView extends StatelessWidget {
  const _BookmarkTreeView({required this.folders});

  final List<BookmarkFolder> folders;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: folders.length,
      itemBuilder: (context, index) {
        return _FolderTile(folder: folders[index], level: 0);
      },
    );
  }
}

class _FolderTile extends StatelessWidget {
  const _FolderTile({required this.folder, this.level = 0});

  final BookmarkFolder folder;
  final int level;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExpansionTile(
      leading: Icon(Icons.folder, color: scheme.primary, size: 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      dense: true,
      childrenPadding: const EdgeInsets.symmetric(vertical: 2),
      title: Text(
        folder.title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
      ),
      children: folder.children
          .map(
            (node) => switch (node) {
              BookmarkFolder() => _FolderTile(folder: node, level: level + 1),
              Bookmark() => _BookmarkTile(bookmark: node),
            },
          )
          .toList(),
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  const _BookmarkTile({required this.bookmark});

  final Bookmark bookmark;

  Widget _buildLeading(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallbackIcon = Icon(Icons.link, color: scheme.primary, size: 20);
    final faviconUrl = faviconUrlForBookmark(bookmark.url);
    if (faviconUrl == null) {
      return SizedBox(width: 36, child: fallbackIcon);
    }
    return SizedBox(
      width: 36,
      child: CachedNetworkImage(
        imageUrl: faviconUrl,
        width: 28,
        height: 28,
        fit: BoxFit.contain,
        placeholder: (_, __) => fallbackIcon,
        errorWidget: (_, __, ___) => fallbackIcon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: _buildLeading(context),
        title: Text(
          bookmark.title,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        subtitle: Text(
          bookmark.url,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.outline,
              ),
        ),
        onTap: () => _openUrl(context, bookmark.url),
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.couldNotOpenUrl(url))),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.couldNotOpenLink)),
        );
      }
    }
  }
}
