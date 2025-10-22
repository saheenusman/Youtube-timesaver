import 'package:flutter/material.dart';
import 'package:utube/core/constants/app_colors.dart';
import 'package:utube/services/api_service.dart';

class HistoryCard extends StatefulWidget {
  final Map<String, dynamic> analysis;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const HistoryCard({
    super.key,
    required this.analysis,
    required this.onDelete,
    required this.onTap,
  });

  @override
  State<HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<HistoryCard> {
  bool _isBookmarked = false;
  bool _isBookmarkLoading = false;

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
  }

  Future<void> _checkBookmarkStatus() async {
    if (widget.analysis['id'] == null) return;

    try {
      final status = await ApiService().checkBookmarkStatus(
        widget.analysis['id'],
      );
      if (mounted) {
        setState(() {
          _isBookmarked = status['bookmarked'] ?? false;
        });
      }
    } catch (e) {
      // Silently fail - bookmark status is not critical
    }
  }

  Future<void> _toggleBookmark() async {
    if (widget.analysis['id'] == null) return;

    setState(() {
      _isBookmarkLoading = true;
    });

    try {
      final result = await ApiService().toggleBookmark(widget.analysis['id']);
      if (mounted) {
        setState(() {
          _isBookmarked = result['bookmarked'] ?? !_isBookmarked;
          _isBookmarkLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isBookmarked ? 'Added to bookmarks' : 'Removed from bookmarks',
            ),
            backgroundColor: AppColors.surface,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBookmarkLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update bookmark'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final createdAt = DateTime.tryParse(widget.analysis['created_at'] ?? '');
    final timeAgo = createdAt != null ? _formatTimeAgo(createdAt) : 'Unknown';

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
          onTap: widget.onTap,
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
                        widget.analysis['thumbnailUrl'] != null &&
                            widget.analysis['thumbnailUrl']
                                .toString()
                                .isNotEmpty
                        ? Stack(
                            children: [
                              Image.network(
                                widget.analysis['thumbnailUrl'],
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
                        widget.analysis['title'] ?? 'Unknown Title',
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
                          Icon(
                            Icons.access_time,
                            color: AppColors.textSecondary,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeAgo,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),

                          if (widget.analysis['highlights'] != null) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.highlight_alt,
                              color: AppColors.textSecondary,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${(widget.analysis['highlights'] as List).length} highlights',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),

                      if (widget.analysis['summary'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.analysis['summary'],
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
                      case 'bookmark':
                        _toggleBookmark();
                        break;
                      case 'delete':
                        _showDeleteConfirmation(context);
                        break;
                      case 'share':
                        // Implement share functionality
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'bookmark',
                      child: Row(
                        children: [
                          _isBookmarkLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                )
                              : Icon(
                                  _isBookmarked
                                      ? Icons.bookmark_remove
                                      : Icons.bookmark_add,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                          const SizedBox(width: 8),
                          Text(
                            _isBookmarked ? 'Remove Bookmark' : 'Add Bookmark',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Delete',
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

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Analysis',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to delete this analysis? This action cannot be undone.',
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
              widget.onDelete();
            },
            child: const Text(
              'Delete',
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
