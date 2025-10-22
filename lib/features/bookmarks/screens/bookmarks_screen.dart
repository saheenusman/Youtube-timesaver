import 'package:flutter/material.dart';
import 'package:utube/core/constants/app_colors.dart';
import 'package:utube/core/utils/youtube_utils.dart';
import 'package:utube/services/api_service.dart';
import 'dart:async';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<Map<String, dynamic>> _bookmarks = [];
  List<Map<String, dynamic>> _filteredBookmarks = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBookmarks() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await ApiService().getBookmarks();

      setState(() {
        _bookmarks = List<Map<String, dynamic>>.from(
          response['bookmarks'] ?? [],
        );
        _filteredBookmarks = _bookmarks; // Initialize filtered list
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load bookmarks';
        _isLoading = false;
      });
    }
  }

  void _filterBookmarks(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _filteredBookmarks = _bookmarks;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _filteredBookmarks = _bookmarks.where((bookmark) {
        final title = (bookmark['title'] ?? '').toLowerCase();
        final highlights = bookmark['highlights'] as List?;
        final highlightText =
            highlights?.map((h) => h['title'] ?? '').join(' ').toLowerCase() ??
            '';
        final searchQuery = query.toLowerCase();

        return title.contains(searchQuery) ||
            highlightText.contains(searchQuery);
      }).toList();
      _isSearching = false;
    });
  }

  void _onSearchChanged(String query) {
    // Cancel the previous timer
    _debounceTimer?.cancel();

    // Set a timer to search after 300ms of no typing (real-time feel)
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _filterBookmarks(query);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _debounceTimer?.cancel();
    setState(() {
      _filteredBookmarks = _bookmarks;
      _isSearching = false;
    });
  }

  Future<void> _removeBookmark(int bookmarkId) async {
    try {
      await ApiService().removeBookmark(bookmarkId);

      // Remove from local lists
      setState(() {
        _bookmarks.removeWhere(
          (bookmark) => bookmark['bookmark_id'] == bookmarkId,
        );
        _filteredBookmarks.removeWhere(
          (bookmark) => bookmark['bookmark_id'] == bookmarkId,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bookmark removed'),
            backgroundColor: AppColors.surface,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove bookmark'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Bookmarks',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _loadBookmarks,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadBookmarks,
        backgroundColor: AppColors.surface,
        color: AppColors.primary,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_bookmarks.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Search bar
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search bookmarks...',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textSecondary,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: _clearSearch,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),

        // Bookmarks list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredBookmarks.length,
            itemBuilder: (context, index) {
              final bookmark = _filteredBookmarks[index];
              return BookmarkCard(
                bookmark: bookmark,
                onRemove: () => _removeBookmark(bookmark['bookmark_id']),
                onTap: () => _viewBookmark(bookmark),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
          SizedBox(height: 16),
          Text(
            'Loading your bookmarks...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.textSecondary,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadBookmarks,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border_outlined,
            color: AppColors.textSecondary,
            size: 64,
          ),
          SizedBox(height: 24),
          Text(
            'No bookmarks yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start bookmarking your favorite video analyses to see them here',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _viewBookmark(Map<String, dynamic> bookmark) {
    // Navigate to bookmark details or show modal - same as history
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    bookmark['title'] ?? 'Unknown Title',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: (bookmark['highlights'] as List?)?.length ?? 0,
                itemBuilder: (context, index) {
                  final highlight = bookmark['highlights'][index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                final videoUrl = bookmark['video_url'];
                                final timestamp = highlight['timestamp'];
                                if (videoUrl != null && timestamp != null) {
                                  YouTubeUtils.openTimestamp(
                                    videoUrl,
                                    timestamp,
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  highlight['timestamp'] ?? '00:00',
                                  style: const TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                highlight['title'] ?? '',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          highlight['description'] ?? '',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom BookmarkCard widget that extends HistoryCard functionality
class BookmarkCard extends StatelessWidget {
  final Map<String, dynamic> bookmark;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const BookmarkCard({
    super.key,
    required this.bookmark,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Parse bookmark creation time
    final bookmarkedAt = DateTime.tryParse(bookmark['bookmarked_at'] ?? '');
    final timeAgo = bookmarkedAt != null
        ? _formatTimeAgo(bookmarkedAt)
        : 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.background.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Video thumbnail
                Container(
                  width: 60,
                  height: 45,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child:
                        bookmark['thumbnailUrl'] != null &&
                            bookmark['thumbnailUrl'].toString().isNotEmpty
                        ? Stack(
                            children: [
                              Image.network(
                                bookmark['thumbnailUrl'],
                                width: 60,
                                height: 45,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: AppColors.surfaceElevated,
                                    child: const Icon(
                                      Icons.play_circle_outline,
                                      color: AppColors.primary,
                                      size: 24,
                                    ),
                                  );
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: AppColors.surfaceElevated,
                                        child: const Center(
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                              ),
                              // Play overlay
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.play_circle_filled,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Container(
                            color: AppColors.surfaceElevated,
                            child: const Icon(
                              Icons.play_circle_outline,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                  ),
                ),

                const SizedBox(width: 12),

                // Video details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bookmark['title'] ?? 'Unknown Title',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              timeAgo,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          if (bookmark['highlights'] != null) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.highlight_alt,
                              color: AppColors.textSecondary,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${(bookmark['highlights'] as List).length} highlights',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  color: AppColors.surfaceElevated,
                  onSelected: (value) {
                    switch (value) {
                      case 'remove':
                        _showRemoveConfirmation(context);
                        break;
                      case 'share':
                        // Implement share functionality
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(
                            Icons.share,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Share',
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(
                            Icons.bookmark_remove,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Remove Bookmark',
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRemoveConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Remove Bookmark',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to remove this bookmark?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onRemove();
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
