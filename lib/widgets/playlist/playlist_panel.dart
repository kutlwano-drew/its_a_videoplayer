import 'dart:typed_data';


import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/thumbnail_service.dart';
import '../../core/utils/file_utils.dart';
import '../../features/playlist/controllers/playlist_controller.dart';
import '../../features/playlist/models/playlist_item.dart';
import 'playlist_empty_state.dart';

class PlaylistPanel extends StatefulWidget {
  const PlaylistPanel({
    super.key,
    required this.controller,
    required this.onClose,
    required this.onPlay,
    required this.onOpen,
    required this.onSave,
    required this.onLoad,
    required this.fullScreen,
    required this.onToggleFullScreen,
  });

  final PlaylistController controller;
  final VoidCallback onClose;
  final ValueChanged<int> onPlay;
  final VoidCallback onOpen;
  final VoidCallback onSave;
  final VoidCallback onLoad;
  final bool fullScreen;
  final VoidCallback onToggleFullScreen;

  @override
  State<PlaylistPanel> createState() => _PlaylistPanelState();
}

class _PlaylistPanelState extends State<PlaylistPanel> {
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  bool _searchVisible = false;
  int _viewMode = 0;

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final query = _search.text.trim().toLowerCase();

        final entries = <({PlaylistItem item, int index})>[];

        for (var index = 0; index < widget.controller.items.length; index++) {
          final item = widget.controller.items[index];

          if (query.isEmpty || item.title.toLowerCase().contains(query)) {
            entries.add((item: item, index: index));
          }
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: widget.fullScreen
                ? null
                : const Border(left: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            children: [
              _header(),
              _controls(),
              if (_searchVisible) _searchBar(),
              if (widget.controller.items.isNotEmpty)
                _statusBar(query, entries.length),
              const Divider(height: 1, color: AppColors.border),
              Expanded(
                child: widget.controller.items.isEmpty
                    ? PlaylistEmptyState(onAdd: widget.onOpen)
                    : entries.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No matching videos',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    : _list(entries),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      child: Row(
        children: [
          const Icon(
            Icons.queue_play_next_rounded,
            size: 19,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Playlist',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: widget.fullScreen ? 'Exit full playlist' : 'Full playlist',
            onPressed: widget.onToggleFullScreen,
            icon: Icon(
              widget.fullScreen
                  ? Icons.picture_in_picture_alt_rounded
                  : Icons.open_in_full_rounded,
            ),
            color: AppColors.textSecondary,
            splashRadius: 19,
          ),
          if (!widget.fullScreen)
            IconButton(
              tooltip: 'Close playlist',
              onPressed: widget.onClose,
              icon: const Icon(Icons.close_rounded),
              color: AppColors.textSecondary,
              splashRadius: 19,
            ),
        ],
      ),
    );
  }

  Widget _controls() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width < 300) {
          return _compactControls();
        }

        if (width < 480) {
          return _mediumControls();
        }

        return _wideControls();
      },
    );
  }

  Widget _wideControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: Row(
        children: [
          Expanded(
            child: _controlButton(
              icon: _searchVisible ? Icons.close_rounded : Icons.search_rounded,
              label: _searchVisible ? 'Hide search' : 'Search',
              onPressed: _toggleSearch,
            ),
          ),
          Expanded(
            child: _controlButton(
              icon: Icons.folder_open_rounded,
              label: 'Load',
              onPressed: widget.onLoad,
            ),
          ),
          Expanded(
            child: _controlButton(
              icon: Icons.save_rounded,
              label: 'Save',
              onPressed: widget.controller.items.isEmpty ? null : widget.onSave,
            ),
          ),
          Expanded(
            child: _controlButton(
              icon: Icons.add_rounded,
              label: 'Add',
              onPressed: widget.onOpen,
            ),
          ),
          Expanded(
            child: _controlButton(
              icon: Icons.view_list_rounded,
              label: 'View',
              onPressed: _showViewMenu,
            ),
          ),
          Expanded(
            child: _controlButton(
              icon: Icons.delete_outline_rounded,
              label: 'Clear',
              onPressed: widget.controller.items.isEmpty
                  ? null
                  : widget.controller.clear,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mediumControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: Wrap(
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 2,
        runSpacing: 2,
        children: [
          _iconControl(
            icon: _searchVisible ? Icons.close_rounded : Icons.search_rounded,
            tooltip: _searchVisible ? 'Hide search' : 'Search playlist',
            onPressed: _toggleSearch,
          ),
          _iconControl(
            icon: Icons.folder_open_rounded,
            tooltip: 'Load playlist',
            onPressed: widget.onLoad,
          ),
          _iconControl(
            icon: Icons.save_rounded,
            tooltip: 'Save playlist',
            onPressed: widget.controller.items.isEmpty ? null : widget.onSave,
          ),
          _iconControl(
            icon: Icons.add_rounded,
            tooltip: 'Add videos',
            onPressed: widget.onOpen,
          ),
          _iconControl(
            icon: Icons.view_list_rounded,
            tooltip: 'Playlist view',
            onPressed: _showViewMenu,
          ),
          _iconControl(
            icon: Icons.delete_outline_rounded,
            tooltip: 'Clear playlist',
            onPressed: widget.controller.items.isEmpty
                ? null
                : widget.controller.clear,
          ),
        ],
      ),
    );
  }

  Widget _compactControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: Row(
        children: [
          Expanded(
            child: _iconControl(
              icon: _searchVisible ? Icons.close_rounded : Icons.search_rounded,
              tooltip: _searchVisible ? 'Hide search' : 'Search playlist',
              onPressed: _toggleSearch,
            ),
          ),
          Expanded(
            child: _iconControl(
              icon: Icons.add_rounded,
              tooltip: 'Add videos',
              onPressed: widget.onOpen,
            ),
          ),
          Expanded(
            child: _iconControl(
              icon: Icons.folder_open_rounded,
              tooltip: 'Load playlist',
              onPressed: widget.onLoad,
            ),
          ),
          Expanded(
            child: _iconControl(
              icon: Icons.more_horiz_rounded,
              tooltip: 'Playlist actions',
              onPressed: _showMoreMenu,
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: label,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconControl({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      color: AppColors.textSecondary,
      disabledColor: AppColors.textMuted,
      splashRadius: 19,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: TextField(
        controller: _search,
        focusNode: _searchFocus,
        autofocus: false,
        onChanged: (_) {
          setState(() {});
        },
        onSubmitted: (_) {
          _searchFocus.requestFocus();
        },
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search playlist…',
          hintStyle: const TextStyle(color: AppColors.textMuted),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
            size: 19,
          ),
          suffixIcon: _search.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    _search.clear();
                    setState(() {});
                    _searchFocus.requestFocus();
                  },
                  icon: const Icon(Icons.clear_rounded, size: 17),
                  color: AppColors.textSecondary,
                ),
          filled: true,
          fillColor: Colors.black.withOpacity(0.28),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.textSecondary),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  Widget _statusBar(String query, int visibleCount) {
    final current = widget.controller.currentIndex;
    final total = widget.controller.items.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 5, 14, 6),
      child: Row(
        children: [
          Text(
            current >= 0 ? '${current + 1}/$total' : '0/$total',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (query.isNotEmpty)
            Text(
              '$visibleCount results',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
        ],
      ),
    );
  }

  Widget _list(List<({PlaylistItem item, int index})> entries) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 6),
      buildDefaultDragHandles: false,
      itemCount: entries.length,
      onReorder: (oldIndex, newIndex) {
        if (_search.text.trim().isNotEmpty) {
          return;
        }

        widget.controller.reorder(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final entry = entries[index];
        final item = entry.item;
        final selected = entry.index == widget.controller.currentIndex;

        return _PlaylistTile(
          key: ValueKey(item.path),
          index: entry.index,
          item: item,
          selected: selected,
          viewMode: _viewMode,
          onPlay: () => widget.onPlay(entry.index),
          onRemove: () => widget.controller.removeAt(entry.index),
        );
      },
    );
  }

  void _toggleSearch() {
    setState(() {
      _searchVisible = !_searchVisible;

      if (!_searchVisible) {
        _search.clear();
        _searchFocus.unfocus();
      }
    });

    if (_searchVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_searchVisible) {
          return;
        }

        _searchFocus.requestFocus();
      });
    }
  }

  void _showViewMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _viewOption(
                value: 0,
                icon: Icons.view_list_rounded,
                label: 'List view',
              ),
              _viewOption(
                value: 1,
                icon: Icons.view_agenda_outlined,
                label: 'Compact view',
              ),
              _viewOption(
                value: 2,
                icon: Icons.video_library_outlined,
                label: 'Large thumbnails',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _viewOption({
    required int value,
    required IconData icon,
    required String label,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: value == _viewMode ? AppColors.success : AppColors.textSecondary,
      ),
      title: Text(label, style: const TextStyle(color: AppColors.textPrimary)),
      trailing: value == _viewMode
          ? const Icon(Icons.check_rounded, color: AppColors.success)
          : null,
      onTap: () {
        setState(() {
          _viewMode = value;
        });

        Navigator.of(context).pop();
      },
    );
  }

  void _showMoreMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.view_list_rounded,
                  color: AppColors.textSecondary,
                ),
                title: const Text(
                  'Playlist view',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showViewMenu();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.folder_open_rounded,
                  color: AppColors.textSecondary,
                ),
                title: const Text(
                  'Load playlist',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onLoad();
                },
              ),
              ListTile(
                enabled: widget.controller.items.isNotEmpty,
                leading: const Icon(
                  Icons.save_rounded,
                  color: AppColors.textSecondary,
                ),
                title: const Text(
                  'Save playlist',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                onTap: widget.controller.items.isEmpty
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        widget.onSave();
                      },
              ),
              ListTile(
                enabled: widget.controller.items.isNotEmpty,
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.textSecondary,
                ),
                title: const Text(
                  'Clear playlist',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                onTap: widget.controller.items.isEmpty
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        widget.controller.clear();
                      },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  const _PlaylistTile({
    super.key,
    required this.index,
    required this.item,
    required this.selected,
    required this.viewMode,
    required this.onPlay,
    required this.onRemove,
  });

  final int index;
  final PlaylistItem item;
  final bool selected;
  final int viewMode;
  final VoidCallback onPlay;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final compact = width < 300;
        final largeThumb = viewMode == 2 && width >= 360;

        final horizontalPadding = width < 260 ? 4.0 : 8.0;
        final innerPadding = width < 260 ? 4.0 : 6.0;

        final dragWidth = width < 260 ? 18.0 : 22.0;

        final thumbnailFraction = largeThumb
            ? 0.36
            : compact
            ? 0.29
            : 0.31;

        return Padding(
          key: key,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 2,
          ),
          child: Material(
            color: selected ? AppColors.surfaceElevated : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onPlay,
              child: Padding(
                padding: EdgeInsets.all(innerPadding),
                child: Row(
                  children: [
                    SizedBox(
                      width: dragWidth,
                      child: ReorderableDragStartListener(
                        index: index,
                        child: const Icon(
                          Icons.drag_indicator_rounded,
                          color: AppColors.textMuted,
                          size: 19,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      flex: 3,
                      child: FractionallySizedBox(
                        widthFactor: thumbnailFraction,
                        alignment: Alignment.centerLeft,
                        child: AspectRatio(
                          aspectRatio: largeThumb ? 16 / 9 : 16 / 10,
                          child: _Thumbnail(path: item.path),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: largeThumb ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: selected
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontSize: largeThumb ? 13 : 12,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          if (item.position > Duration.zero) ...[
                            const SizedBox(height: 4),
                            Text(
                              _formatPosition(item.position),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Open file location',
                      onPressed: () => revealFileInExplorer(item.path),
                      icon: const Icon(Icons.folder_open_rounded, size: 18),
                      color: selected
                          ? AppColors.success
                          : AppColors.textMuted,
                      splashRadius: 17,
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      onPressed: onRemove,
                      icon: const Icon(Icons.close_rounded, size: 17),
                      color: AppColors.textMuted,
                      splashRadius: 17,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatPosition(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');

    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: ThumbnailService.instance.thumbnail(path),
      builder: (context, snapshot) {
        final bytes = snapshot.data;

        return Container(
          width: double.infinity,
          height: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.videoBackground,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: AppColors.border),
          ),
          child: bytes == null
              ? const Icon(
                  Icons.movie_outlined,
                  color: AppColors.textMuted,
                  size: 21,
                )
              : Image.memory(bytes, fit: BoxFit.cover),
        );
      },
    );
  }
}
