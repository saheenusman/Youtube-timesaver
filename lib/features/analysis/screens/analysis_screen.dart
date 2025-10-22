import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:utube/core/constants/app_colors.dart';
import 'package:utube/core/constants/mock_data.dart';
import 'package:utube/core/utils/youtube_utils.dart';
import 'package:utube/features/analysis/widgets/agent_card.dart';
import 'package:utube/features/analysis/widgets/highlight_card.dart';
import 'dart:async';
import 'package:utube/services/api_service.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key, this.url});

  final String? url; // Accept URL as a parameter
  static const String route = '/analysis';

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

enum AnalysisState { loading, loaded, error, idle }

class _AnalysisScreenState extends State<AnalysisScreen> {
  AnalysisState _state = AnalysisState.idle;
  Map<String, dynamic>? _data;
  String? url;
  Timer? _progressTimer;
  bool _isBookmarked = false;
  bool _isBookmarkLoading = false;
  final Map<String, double> _agentProgress = {
    'teacher': 0.0,
    'analyst': 0.0,
    'explorer': 0.0,
  };

  // Helper function to map agent names to Icons (used for both AgentCard and HighlightCard)
  IconData _getAgentIcon(String agentName) {
    final lowerName = agentName.toLowerCase();
    if (lowerName.contains('teacher')) return Icons.school;
    if (lowerName.contains('analyst')) return Icons.analytics;
    if (lowerName.contains('explorer')) return Icons.explore;
    return Icons.psychology; // Default fallback
  }

  // Helper function to map agent names to Colors (used for both AgentCard and HighlightCard)
  Color _getAgentColor(String agentName) {
    final lowerName = agentName.toLowerCase();
    if (lowerName.contains('teacher')) return AppColors.agentTeacher;
    if (lowerName.contains('analyst')) return AppColors.agentAnalyst;
    if (lowerName.contains('explorer')) return AppColors.agentExplorer;
    return AppColors.primary; // Default fallback
  }

  @override
  void initState() {
    super.initState();

    // Use widget URL parameter or extract from route arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      String? urlToAnalyze = widget.url;
      Map<String, dynamic>? cachedData;

      // If no URL provided as parameter, try to get from route arguments (backwards compatibility)
      if (urlToAnalyze == null || urlToAnalyze.isEmpty) {
        final arguments = ModalRoute.of(context)?.settings.arguments;
        if (arguments is String) {
          urlToAnalyze = arguments;
        } else if (arguments is Map<String, dynamic>) {
          urlToAnalyze = arguments['url'] as String?;
          cachedData = arguments['data'] as Map<String, dynamic>?;
        }
      }

      if (urlToAnalyze != null && urlToAnalyze.isNotEmpty) {
        url = urlToAnalyze;

        // If we have cached data, use it directly
        if (cachedData != null) {
          print('📦 Using cached analysis data');
          setState(() {
            _data = cachedData;
            _state = AnalysisState.loaded;
          });
          _checkBookmarkStatus(); // Check bookmark status for cached data
        } else {
          _analyzeVideo();
        }
      } else {
        // Stay in idle state when no URL is provided
        setState(() {
          _state = AnalysisState.idle;
        });
      }
    });
  }

  void _analyzeVideo() async {
    if (url == null || url!.isEmpty) {
      setState(() {
        _state = AnalysisState.error;
      });
      return;
    }

    print('🎬 Starting video analysis for: $url');
    setState(() {
      _state = AnalysisState.loading;
    });

    // Start progress simulation
    _startProgressSimulation();

    try {
      final apiService = ApiService();
      final result = await apiService.analyzeVideo(url!);

      if (mounted) {
        print('✅ Analysis completed successfully');
        setState(() {
          _data = result;
          _state = AnalysisState.loaded;
        });
        _stopProgressSimulation();
        _checkBookmarkStatus(); // Check bookmark status after successful analysis
      }
    } catch (e) {
      print('❌ Analysis failed: $e');
      if (mounted) {
        // Show error state instead of automatically falling back to mock data
        setState(() {
          _state = AnalysisState.error;
        });
        _stopProgressSimulation();

        // Show error dialog with option to use mock data
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Analysis Failed',
            style: TextStyle(color: AppColors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Failed to analyze the video. This could be due to:',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Network connectivity issues\n• Invalid YouTube URL\n• Backend server not responding\n• Video may be private or restricted',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Error: $error',
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/'); // Go back to home
              },
              child: const Text(
                'Back to Home',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _analyzeVideo(); // Retry
              },
              child: const Text(
                'Retry',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Load mock data for demo purposes
                setState(() {
                  _data = mockAnalysisData;
                  _state = AnalysisState.loaded;
                });
                _stopProgressSimulation();
                _checkBookmarkStatus(); // Check bookmark status after loading mock data
              },
              child: const Text(
                'Use Demo Data',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  void _startProgressSimulation() {
    const updateInterval = Duration(milliseconds: 100);
    _progressTimer = Timer.periodic(updateInterval, (timer) {
      setState(() {
        // Simulate realistic progress for each agent
        _agentProgress['teacher'] = (_agentProgress['teacher']! + 0.015).clamp(
          0.0,
          1.0,
        );
        _agentProgress['analyst'] = (_agentProgress['analyst']! + 0.012).clamp(
          0.0,
          1.0,
        );
        _agentProgress['explorer'] = (_agentProgress['explorer']! + 0.018)
            .clamp(0.0, 1.0);
      });

      // Stop when all agents complete
      if (_agentProgress.values.every((progress) => progress >= 1.0)) {
        timer.cancel();
      }
    });
  }

  void _stopProgressSimulation() {
    _progressTimer?.cancel();
    setState(() {
      _agentProgress.updateAll((key, value) => 1.0);
    });
  }

  Future<void> _checkBookmarkStatus() async {
    if (_data?['id'] == null) {
      print('⚠️ Cannot check bookmark status: analysis ID not available');
      return;
    }

    try {
      final status = await ApiService().checkBookmarkStatus(_data!['id']);
      if (mounted) {
        setState(() {
          _isBookmarked = status['bookmarked'] ?? false;
        });
      }
    } catch (e) {
      print('❌ Failed to check bookmark status: $e');
      // Silently fail - bookmark status is not critical
    }
  }

  Future<void> _toggleBookmark() async {
    if (_data?['id'] == null) {
      print('⚠️ Cannot toggle bookmark: analysis ID not available');
      return;
    }

    setState(() {
      _isBookmarkLoading = true;
    });

    try {
      final result = await ApiService().toggleBookmark(_data!['id']);
      setState(() {
        _isBookmarked = result['bookmarked'] ?? !_isBookmarked;
        _isBookmarkLoading = false;
      });

      if (mounted) {
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
      print('❌ Failed to toggle bookmark: $e');
      setState(() {
        _isBookmarkLoading = false;
      });

      if (mounted) {
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
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  void _showExpandedHighlight({
    required BuildContext context,
    required String timestamp,
    required String agentName,
    required IconData agentIcon,
    required Color agentColor,
    required String title,
    required String description,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with agent info
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: agentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(agentIcon, color: agentColor, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  agentName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: agentColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Clickable timestamp
                                GestureDetector(
                                  onTap: () {
                                    if (url != null && url!.isNotEmpty) {
                                      YouTubeUtils.openTimestamp(
                                        url!,
                                        timestamp,
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: AppColors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.play_arrow,
                                            color: AppColors.primary,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          timestamp,
                                          style: const TextStyle(
                                            color: AppColors.white,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'monospace',
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Title
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Description
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final agentKeys = MockData.agentStatuses.keys.toList();
    final agentValues = MockData.agentStatuses.values.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading:
            false, // Remove back button since we're in tabs
        title: const Text(
          'AI Analysis',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          // Bookmark button (only show when analysis is loaded)
          if (_state == AnalysisState.loaded && _data != null)
            IconButton(
              icon: _isBookmarkLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : Icon(
                      _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: _isBookmarked
                          ? AppColors.primary
                          : AppColors.white,
                    ),
              onPressed: _isBookmarkLoading ? null : _toggleBookmark,
              tooltip: _isBookmarked ? 'Remove bookmark' : 'Add bookmark',
            ),
          // Add a home button to go back to URL input
          IconButton(
            icon: const Icon(Icons.home_outlined, color: AppColors.white),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            tooltip: 'Back to Home',
          ),
        ],
      ),
      body: _state == AnalysisState.error
          ? _buildErrorState()
          : _state == AnalysisState.idle
          ? _buildIdleState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Video Information Section
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Hero(
                          tag: 'video_thumbnail',
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _state == AnalysisState.loading
                                  ? Shimmer.fromColors(
                                      baseColor: Colors.grey.shade800,
                                      highlightColor: Colors.grey.shade700,
                                      child: Container(color: Colors.white),
                                    )
                                  : Image.network(
                                      _data?['thumbnailUrl'] ??
                                          MockData.thumbnailUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (
                                            context,
                                            error,
                                            stackTrace,
                                          ) => Container(
                                            color: AppColors.surfaceElevated,
                                            child: const Icon(
                                              Icons.video_library,
                                              color: AppColors.textSecondary,
                                              size: 48,
                                            ),
                                          ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _state == AnalysisState.loading
                            ? Shimmer.fromColors(
                                baseColor: Colors.grey.shade800,
                                highlightColor: Colors.grey.shade700,
                                child: Container(
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              )
                            : Text(
                                _data?['title'] ?? MockData.videoTitle,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _data?['duration'] ?? MockData.videoDuration,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // AI Agents Section
                  const Text(
                    'AI Agents',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Agents Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.0,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: agentKeys.length,
                    itemBuilder: (context, index) {
                      final agentName = agentKeys[index];
                      return AgentCard(
                        agentName: agentName.toUpperCase(),
                        icon: _getAgentIcon(agentName),
                        isLoading: _state == AnalysisState.loading,
                        status: agentValues[index],
                        progress: _agentProgress[agentName] ?? 0.0,
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Key Highlights Section
                  const Text(
                    'Key Highlights',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Highlights List
                  if (_state == AnalysisState.loading)
                    // Loading state with shimmer placeholders
                    ...List.generate(
                      3,
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey.shade800,
                          highlightColor: Colors.grey.shade700,
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    // Display real HighlightCards
                    ...List.generate(
                      ((_data?['highlights'] as List?)?.length ??
                          MockData.highlights.length),
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: HighlightCard(
                          timestamp:
                              ((_data?['highlights'] as List?)?[i]?['timestamp']
                                  as String?) ??
                              MockData.highlights[i]['timestamp'] ??
                              '',
                          agentName:
                              ((_data?['highlights'] as List?)?[i]?['agent']
                                  as String?) ??
                              MockData.highlights[i]['agentName'] ??
                              'Agent',
                          agentIcon: _getAgentIcon(
                            ((_data?['highlights'] as List?)?[i]?['agent']
                                    as String?) ??
                                MockData.highlights[i]['agentName'] ??
                                'Agent',
                          ),
                          agentColor: _getAgentColor(
                            ((_data?['highlights'] as List?)?[i]?['agent']
                                    as String?) ??
                                MockData.highlights[i]['agentName'] ??
                                'Agent',
                          ),
                          title:
                              ((_data?['highlights'] as List?)?[i]?['title']
                                  as String?) ??
                              MockData.highlights[i]['title'] ??
                              '',
                          description:
                              ((_data?['highlights']
                                      as List?)?[i]?['description']
                                  as String?) ??
                              MockData.highlights[i]['description'] ??
                              '',
                          onTap: () {
                            final timestamp =
                                ((_data?['highlights']
                                        as List?)?[i]?['timestamp']
                                    as String?) ??
                                MockData.highlights[i]['timestamp'] ??
                                '';
                            final agentName =
                                ((_data?['highlights'] as List?)?[i]?['agent']
                                    as String?) ??
                                MockData.highlights[i]['agentName'] ??
                                'Agent';
                            final title =
                                ((_data?['highlights'] as List?)?[i]?['title']
                                    as String?) ??
                                MockData.highlights[i]['title'] ??
                                '';
                            final description =
                                ((_data?['highlights']
                                        as List?)?[i]?['description']
                                    as String?) ??
                                MockData.highlights[i]['description'] ??
                                '';

                            // Show expanded highlight view
                            _showExpandedHighlight(
                              context: context,
                              timestamp: timestamp,
                              agentName: agentName,
                              agentIcon: _getAgentIcon(agentName),
                              agentColor: _getAgentColor(agentName),
                              title: title,
                              description: description,
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Analysis Failed',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to analyze the video. Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.white,
                    side: const BorderSide(color: AppColors.textSecondary),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Back to Home'),
                ),
                ElevatedButton(
                  onPressed: _analyzeVideo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Retry Analysis'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdleState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.video_library_outlined,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ready to Analyze',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Go to Home to paste a YouTube URL and start analyzing videos with AI agents.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.home),
              label: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
