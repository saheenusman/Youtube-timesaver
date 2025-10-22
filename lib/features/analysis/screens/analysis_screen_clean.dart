import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:utube/core/constants/app_colors.dart';
import 'package:utube/core/constants/mock_data.dart';
import 'package:utube/core/utils/youtube_utils.dart';
import 'package:utube/features/analysis/widgets/agent_card.dart';
import 'package:utube/services/api_service.dart' show mockAnalysisData;
import 'package:utube/features/analysis/widgets/highlight_card.dart';
import 'dart:async';
import 'package:utube/services/api_service.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  static const String route = '/analysis';

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

enum AnalysisState { loading, loaded, error }

class _AnalysisScreenState extends State<AnalysisScreen> {
  AnalysisState _state = AnalysisState.loading;
  Map<String, dynamic>? _data;
  String? url;
  Timer? _progressTimer;
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

    // Extract URL from route arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      url = args?['url'] as String?;
      _analyzeVideo();
    });
  }

  void _analyzeVideo() async {
    if (url == null || url!.isEmpty) {
      setState(() {
        _state = AnalysisState.error;
      });
      return;
    }

    setState(() {
      _state = AnalysisState.loading;
    });

    // Start progress simulation
    _startProgressSimulation();

    try {
      final apiService = ApiService();
      final result = await apiService.analyzeVideo(url!);

      if (mounted) {
        setState(() {
          _data = result;
          _state = AnalysisState.loaded;
        });
        _stopProgressSimulation();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _data = mockAnalysisData;
          _state = AnalysisState.loaded;
        });
        _stopProgressSimulation();
      }
    }
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

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AI Analysis',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Information Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 120,
                          height: 68,
                          color: AppColors.surfaceElevated,
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
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        color: AppColors.surfaceElevated,
                                        child: const Icon(
                                          Icons.video_library,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _state == AnalysisState.loading
                                ? Shimmer.fromColors(
                                    baseColor: Colors.grey.shade800,
                                    highlightColor: Colors.grey.shade700,
                                    child: Container(
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  )
                                : Text(
                                    _data?['title'] ?? MockData.videoTitle,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.white,
                                    ),
                                  ),
                            const SizedBox(height: 8),
                            Text(
                              _data?['duration'] ?? MockData.videoDuration,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.85,
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
                        ((_data?['highlights'] as List?)?[i]?['description']
                            as String?) ??
                        MockData.highlights[i]['description'] ??
                        '',
                    onTap: () {
                      final timestamp =
                          ((_data?['highlights'] as List?)?[i]?['timestamp']
                              as String?) ??
                          MockData.highlights[i]['timestamp'] ??
                          '';

                      // Show dialog with options
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppColors.surface,
                          title: const Text(
                            'Highlight Options',
                            style: TextStyle(color: AppColors.white),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Jump to YouTube button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    if (url != null && url!.isNotEmpty) {
                                      YouTubeUtils.openTimestamp(
                                        url!,
                                        timestamp,
                                      );
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.play_circle_fill,
                                    color: Colors.red,
                                  ),
                                  label: Text('Jump to $timestamp'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Cancel button
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.white,
                                    side: const BorderSide(
                                      color: AppColors.whiteTransparent,
                                    ),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ),
                            ],
                          ),
                        ),
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
}
