import 'package:url_launcher/url_launcher.dart';

class YouTubeUtils {
  /// Converts MM:SS timestamp to seconds
  static int timestampToSeconds(String timestamp) {
    final parts = timestamp.split(':');
    if (parts.length == 2) {
      final minutes = int.tryParse(parts[0]) ?? 0;
      final seconds = int.tryParse(parts[1]) ?? 0;
      return (minutes * 60) + seconds;
    }
    return 0;
  }

  /// Extracts YouTube video ID from URL
  static String? extractVideoId(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  /// Creates YouTube URL with timestamp
  static String createTimestampUrl(String originalUrl, String timestamp) {
    final videoId = extractVideoId(originalUrl);
    if (videoId == null) return originalUrl;

    final seconds = timestampToSeconds(timestamp);
    return 'https://www.youtube.com/watch?v=$videoId&t=${seconds}s';
  }

  /// Opens YouTube URL with timestamp
  static Future<void> openTimestamp(
    String originalUrl,
    String timestamp,
  ) async {
    final timestampUrl = createTimestampUrl(originalUrl, timestamp);
    final uri = Uri.parse(timestampUrl);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode:
              LaunchMode.externalApplication, // Opens in YouTube app on mobile
        );
      } else {
        // Fallback to browser if YouTube app not available
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      print('Could not launch YouTube URL: $e');
    }
  }

  /// Opens YouTube URL in browser specifically (for web compatibility)
  static Future<void> openTimestampInBrowser(
    String originalUrl,
    String timestamp,
  ) async {
    final timestampUrl = createTimestampUrl(originalUrl, timestamp);
    final uri = Uri.parse(timestampUrl);

    try {
      await launchUrl(
        uri,
        mode: LaunchMode.platformDefault, // Opens in browser
      );
    } catch (e) {
      print('Could not launch YouTube URL in browser: $e');
    }
  }
}
