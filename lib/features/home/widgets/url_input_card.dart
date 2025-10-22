import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:utube/core/constants/app_colors.dart';

class UrlInputCard extends StatefulWidget {
  const UrlInputCard({super.key});

  @override
  State<UrlInputCard> createState() => _UrlInputCardState();
}

class _UrlInputCardState extends State<UrlInputCard> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isValidUrl {
    final text = _controller.text.trim();
    if (text.isEmpty) return false;

    // Check for common YouTube URL patterns
    final lower = text.toLowerCase();
    final hasYouTubeDomain =
        lower.contains('youtube.com') || lower.contains('youtu.be');

    if (!hasYouTubeDomain) return false;

    // Additional validation: check for video ID presence
    if (lower.contains('youtube.com')) {
      // Standard YouTube URL: https://www.youtube.com/watch?v=VIDEO_ID
      return lower.contains('watch?v=') || lower.contains('watch?video_id=');
    } else if (lower.contains('youtu.be')) {
      // Short YouTube URL: https://youtu.be/VIDEO_ID
      final parts = text.split('/');
      return parts.length >= 4 && parts.last.isNotEmpty;
    }

    return false;
  }

  Future<void> _pasteFromClipboard() async {
    HapticFeedback.lightImpact();
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _controller.text = data.text!.trim();
      setState(() {});
    }
  }

  Future<void> _submit() async {
    if (!_isValidUrl || _isLoading) return;
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    try {
      if (!mounted) return;
      // Navigate to the main navigation screen with the URL for analysis
      Navigator.of(context).pushNamed(
        '/main',
        arguments: {
          'url': _controller.text.trim(),
          'initialTab': 0,
        }, // Tab 0 = Analysis
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.whiteTransparent, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              style: const TextStyle(color: AppColors.white),
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText:
                    'Paste a YouTube URL here...\ne.g., https://youtu.be/dQw4w9WgXcQ',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(
                  Icons.play_circle_outline,
                  color: AppColors.primary,
                ),
                suffixIcon: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    tooltip: 'Paste',
                    icon: const Icon(Icons.paste, color: AppColors.white),
                    onPressed: _pasteFromClipboard,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.whiteTransparent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: AppColors.whiteTransparent),
            const SizedBox(height: 16),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isValidUrl && !_isLoading ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isValidUrl && !_isLoading
                      ? AppColors.primary
                      : AppColors.surfaceElevated,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Analyze Video',
                        style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
