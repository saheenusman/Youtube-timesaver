import 'package:flutter/material.dart';
import 'package:utube/core/constants/app_colors.dart';
import 'package:utube/core/utils/youtube_utils.dart';
import 'package:utube/services/api_service.dart';
import 'package:utube/features/history/widgets/history_card.dart';
import 'package:utube/features/history/widgets/stats_card.dart';
import 'dart:async';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _analyses = [];
  List<Map<String, dynamic>> _filteredAnalyses = [];
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _stats;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadStats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await ApiService().getAnalysisHistory();

      setState(() {
        _analyses = List<Map<String, dynamic>>.from(response['analyses'] ?? []);
        _filteredAnalyses = _analyses; // Initialize filtered list
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load analysis history';
        _isLoading = false;
      });
    }
  }

  void _filterAnalyses(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _filteredAnalyses = _analyses;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _filteredAnalyses = _analyses.where((analysis) {
        final title = (analysis['title'] ?? '').toLowerCase();
        final highlights = analysis['highlights'] as List?;
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
      _filterAnalyses(query);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _debounceTimer?.cancel();
    setState(() {
      _filteredAnalyses = _analyses;
      _isSearching = false;
    });
  }

  Future<void> _loadStats() async {
    try {
      final stats = await ApiService().getStats();
      setState(() {
        _stats = stats;
      });
    } catch (e) {
      // Stats are optional, don't show error
    }
  }

  Future<void> _deleteAnalysis(int analysisId) async {
    try {
      await ApiService().deleteAnalysis(analysisId);

      // Remove from local lists
      setState(() {
        _analyses.removeWhere((analysis) => analysis['id'] == analysisId);
        _filteredAnalyses.removeWhere(
          (analysis) => analysis['id'] == analysisId,
        );
      });

      // Refresh stats
      _loadStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Analysis deleted'),
            backgroundColor: AppColors.surface,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete analysis'),
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
          'Analysis History',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: () {
              _loadHistory();
              _loadStats();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadHistory();
          await _loadStats();
        },
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

    if (_analyses.isEmpty) {
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
              hintText: 'Search in history...',
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

        // Stats card at the top
        if (_stats != null) StatsCard(stats: _stats!),

        // History list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredAnalyses.length,
            itemBuilder: (context, index) {
              final analysis = _filteredAnalyses[index];
              return HistoryCard(
                analysis: analysis,
                onDelete: () => _deleteAnalysis(analysis['id']),
                onTap: () => _viewAnalysis(analysis),
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
            'Loading your analysis history...',
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
            onPressed: _loadHistory,
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
            Icons.video_library_outlined,
            color: AppColors.textSecondary,
            size: 64,
          ),
          SizedBox(height: 24),
          Text(
            'No analysis history yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start analyzing YouTube videos to see them here',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _viewAnalysis(Map<String, dynamic> analysis) {
    // Navigate to analysis details or show modal
    // For now, we can show the highlights in a modal
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
            Text(
              analysis['title'] ?? 'Unknown Title',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: (analysis['highlights'] as List?)?.length ?? 0,
                itemBuilder: (context, index) {
                  final highlight = analysis['highlights'][index];
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
                                final videoUrl = analysis['video_url'];
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
