import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/bookmark_node.dart';
import '../providers/bookmark_provider.dart';
import '../utils/favicon_utils.dart';
import 'info_screen.dart';
import 'settings_screen.dart';

class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/images/app_icon.png', width: size, height: size);
  }
}

class BookmarkListScreen extends StatelessWidget {
  const BookmarkListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BookmarkProvider>(
      builder: (context, provider, _) {
        if (provider.error != null) {
          return Scaffold(
            appBar: _buildAppBar(context, provider),
            body: _ErrorView(
              message: provider.error!,
              onRetry: () {
                provider.clearError();
                provider.syncBookmarks();
              },
            ),
          );
        }

        if (!provider.hasCredentials) {
          return Scaffold(
            appBar: _buildAppBar(context, provider),
            body: const _EmptyState(onOpenSettings: null),
          );
        }

        if (provider.isLoading && !provider.hasBookmarks) {
          return Scaffold(
            appBar: _buildAppBar(context, provider),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!provider.hasBookmarks) {
          return Scaffold(
            appBar: _buildAppBar(context, provider),
            body: _EmptyState(
              hasCredentials: true,
              onSync: () => provider.syncBookmarks(),
              onOpenSettings: null,
            ),
          );
        }

        final folders = provider.displayedRootFolders;
        return _TabbedBookmarkView(
          folders: folders,
          provider: provider,
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, BookmarkProvider provider) {
    return AppBar(
      title: _ProfileDropdown(),
      centerTitle: false,
      actions: [
        if (provider.hasCredentials)
          IconButton(
            icon: provider.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            onPressed:
                provider.isLoading ? null : () => provider.syncBookmarks(),
          ),
        _OverflowMenu(),
      ],
    );
  }
}

// =============================================================================
// Tabbed bookmark view (shown when bookmarks exist)
// =============================================================================

class _TabbedBookmarkView extends StatelessWidget {
  const _TabbedBookmarkView({
    required this.folders,
    required this.provider,
  });

  final List<BookmarkFolder> folders;
  final BookmarkProvider provider;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: folders.length,
      child: Scaffold(
        appBar: AppBar(
          title: _ProfileDropdown(),
          centerTitle: false,
          actions: [
            IconButton(
              icon: provider.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              onPressed:
                  provider.isLoading ? null : () => provider.syncBookmarks(),
            ),
            _OverflowMenu(),
          ],
          bottom: TabBar(
            isScrollable: folders.length > 3,
            tabs: folders
                .map((f) => Tab(
                      icon: const Icon(Icons.folder_outlined, size: 20),
                      text: f.title,
                    ))
                .toList(),
          ),
        ),
        body: TabBarView(
          children: folders.map((folder) {
            return RefreshIndicator(
              onRefresh: () => provider.syncBookmarks().then((_) async {}),
              child: _FolderContentList(folder: folder),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// =============================================================================
// Profile dropdown in AppBar
// =============================================================================

class _ProfileDropdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookmarkProvider>();
    final scheme = Theme.of(context).colorScheme;
    final activeProfile = provider.activeProfile;

    const appIcon = _AppIcon(size: 24);

    if (provider.profiles.length <= 1) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          appIcon,
          const SizedBox(width: 8),
          Text(AppLocalizations.of(context)!.appTitle),
        ],
      );
    }

    return PopupMenuButton<String>(
      onSelected: (id) {
        if (id != provider.activeProfileId) {
          provider.switchProfile(id);
        }
      },
      offset: const Offset(0, 48),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          appIcon,
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              activeProfile?.name ?? AppLocalizations.of(context)!.appTitle,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_drop_down, color: scheme.outline, size: 20),
        ],
      ),
      itemBuilder: (context) => provider.profiles
          .map((p) => PopupMenuItem<String>(
                value: p.id,
                child: Row(
                  children: [
                    Icon(
                      p.id == provider.activeProfileId
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 20,
                      color: p.id == provider.activeProfileId
                          ? scheme.primary
                          : scheme.outline,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        p.name,
                        style: TextStyle(
                          fontWeight: p.id == provider.activeProfileId
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

// =============================================================================
// Overflow menu (⋮) for Settings + Info
// =============================================================================

class _OverflowMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      offset: const Offset(0, 48),
      onSelected: (value) {
        switch (value) {
          case 'settings':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          case 'info':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InfoScreen()),
            );
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'settings',
          child: ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(l.settings),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'info',
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l.info),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Folder content list (children of a root folder)
// =============================================================================

class _FolderContentList extends StatelessWidget {
  const _FolderContentList({required this.folder});

  final BookmarkFolder folder;

  @override
  Widget build(BuildContext context) {
    if (folder.children.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noBookmarksYet,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      itemCount: folder.children.length,
      itemBuilder: (context, index) {
        final node = folder.children[index];
        return switch (node) {
          BookmarkFolder() => _FolderTile(
              folder: node,
              level: 0,
              initiallyExpanded: index == 0,
            ),
          Bookmark() => _BookmarkTile(bookmark: node),
        };
      },
    );
  }
}

// =============================================================================
// Empty state
// =============================================================================

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    this.hasCredentials = false,
    this.onSync,
    this.onOpenSettings,
  });

  final bool hasCredentials;
  final VoidCallback? onSync;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const _AppIcon(size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              l.noBookmarksYet,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              hasCredentials ? l.tapSyncToFetch : l.configureInSettings,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (hasCredentials && onSync != null)
              FilledButton.icon(
                onPressed: onSync,
                icon: const Icon(Icons.sync, size: 18),
                label: Text(l.sync),
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Error view
// =============================================================================

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: scheme.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l.error,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.error,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l.retry),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Folder tile (expandable)
// =============================================================================

class _FolderTile extends StatelessWidget {
  const _FolderTile({
    required this.folder,
    this.level = 0,
    this.initiallyExpanded = false,
  });

  final BookmarkFolder folder;
  final int level;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.only(
        left: level > 0 ? 12.0 : 4,
        right: 4,
        top: 2,
        bottom: 2,
      ),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: Icon(
          initiallyExpanded || level == 0
              ? Icons.folder_open
              : Icons.folder,
          color: scheme.primary,
          size: 22,
        ),
        shape: const RoundedRectangleBorder(),
        collapsedShape: const RoundedRectangleBorder(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding:
            const EdgeInsets.only(left: 8, right: 8, bottom: 8),
        title: Text(
          folder.title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        children: folder.children
            .asMap()
            .entries
            .map(
              (entry) => switch (entry.value) {
                BookmarkFolder() => _FolderTile(
                    folder: entry.value as BookmarkFolder,
                    level: level + 1,
                  ),
                Bookmark() =>
                  _BookmarkTile(bookmark: entry.value as Bookmark),
              },
            )
            .toList(),
      ),
    );
  }
}

// =============================================================================
// Bookmark tile
// =============================================================================

class _BookmarkTile extends StatelessWidget {
  const _BookmarkTile({required this.bookmark});

  final Bookmark bookmark;

  Widget _buildLeading(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallbackIcon = Icon(Icons.link, color: scheme.primary, size: 20);
    final faviconUrl = faviconUrlForBookmark(bookmark.url);
    if (faviconUrl == null) {
      return SizedBox(width: 32, child: fallbackIcon);
    }
    return SizedBox(
      width: 32,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CachedNetworkImage(
          imageUrl: faviconUrl,
          width: 24,
          height: 24,
          fit: BoxFit.contain,
          placeholder: (_, __) => fallbackIcon,
          errorWidget: (_, __, ___) => fallbackIcon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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
            SnackBar(
                content: Text(
                    AppLocalizations.of(context)!.couldNotOpenUrl(url))),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.couldNotOpenLink)),
        );
      }
    }
  }
}
