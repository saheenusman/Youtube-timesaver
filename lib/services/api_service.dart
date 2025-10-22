import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:utube/core/constants/mock_data.dart';
import 'package:utube/core/services/device_id_service.dart';

/// API service to communicate with the backend.
///
/// Integration notes (Django backend):
/// - Base URL points to local Django server.
/// - Uses HTTP POST request to Django endpoint `/api/v1/analyze/`.
/// - Automatically detects platform: localhost for web, IP address for mobile
class ApiService {
  // Smart URL selection based on platform
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api'; // Web uses localhost
    } else {
      // Try multiple possible IPs for different network setups
      // You can manually update this when switching networks
      // return 'http://192.168.43.81:8000/api';
       return 'http://192.168.1.52:8000/api';
      // return 'http://10.91.68.36:8000/api'; // Current WiFi IP // Current: Secondary phone network
      // Alternative IPs for different networks:
      // return 'http://192.168.1.xxx:8000/api';  // Primary phone network
      // return 'http://10.0.0.xxx:8000/api';     // Other common network
    }
  }

  /// Get headers with device authentication
  static Future<Map<String, String>> _getAuthHeaders() async {
    final deviceId = await DeviceIdService.getDeviceId();
    return {'Content-Type': 'application/json', 'X-Device-ID': deviceId};
  }

  /// Analyzes a YouTube video by calling the Django backend (legacy single-call)
  Future<Map<String, dynamic>> analyzeVideo(String url) async {
    print('🔍 Starting analysis for URL: $url');
    print('🌐 Using backend URL: $baseUrl/analyze/');

    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/analyze/'),
        headers: headers,
        body: jsonEncode({'url': url}),
      );

      print('📡 Server response status: ${response.statusCode}');
      print('📄 Server response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ Successfully received analysis data');

        // Log rate limiting info if available
        final remaining = response.headers['x-ratelimit-remaining'];
        if (remaining != null) {
          print('🚦 Rate limit: $remaining requests remaining');
        }

        return responseData;
      } else if (response.statusCode == 429) {
        // Rate limit exceeded
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        final retryAfter = errorData['retry_after'] ?? 60;
        print('🚫 Rate limit exceeded. Retry after: ${retryAfter}s');
        throw Exception(
          'Rate limit exceeded. Please wait $retryAfter seconds before trying again.',
        );
      } else {
        // If the server returns an error, throw with detailed info
        print('❌ Server error: ${response.statusCode} - ${response.body}');
        throw Exception(
          'Server returned ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      print('💥 Network/API error: $e');
      // Re-throw the error so the UI can handle it properly
      rethrow;
    }
  }

  /// Gets analysis history from the backend
  Future<Map<String, dynamic>> getAnalysisHistory() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/history/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load analysis history');
    }
  }

  /// Searches analyses by query
  Future<Map<String, dynamic>> searchAnalyses(String query) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/search/?q=${Uri.encodeComponent(query)}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Search failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to search analyses');
    }
  }

  /// Gets user statistics
  Future<Map<String, dynamic>> getStats() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/stats/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load statistics');
    }
  }

  /// Deletes an analysis by ID
  Future<void> deleteAnalysis(int analysisId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/analysis/$analysisId/'),
        headers: headers,
      );

      if (response.statusCode != 204) {
        throw Exception('Delete failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete analysis');
    }
  }

  // Bookmark API methods

  /// Toggle bookmark status for an analysis
  Future<Map<String, dynamic>> toggleBookmark(int analysisId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/bookmark/'),
        headers: headers,
        body: json.encode({'analysis_id': analysisId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Toggle bookmark failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to toggle bookmark');
    }
  }

  /// Get all bookmarks for the authenticated device
  Future<Map<String, dynamic>> getBookmarks({
    String? query,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      if (query != null && query.isNotEmpty) {
        queryParams['query'] = query;
      }

      final uri = Uri.parse(
        '$baseUrl/bookmarks/',
      ).replace(queryParameters: queryParams);
      final headers = await _getAuthHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Get bookmarks failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get bookmarks');
    }
  }

  /// Remove a specific bookmark
  Future<void> removeBookmark(int bookmarkId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/bookmark/$bookmarkId/'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Remove bookmark failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to remove bookmark');
    }
  }

  /// Check if an analysis is bookmarked
  Future<Map<String, dynamic>> checkBookmarkStatus(int analysisId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/bookmark/status/$analysisId/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Check bookmark status failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to check bookmark status');
    }
  }
}

// Mock analysis payload assembled from MockData constants
const Map<String, dynamic> mockAnalysisData = {
  'id': 999, // Mock ID for testing
  'title': MockData.videoTitle,
  'duration': MockData.videoDuration,
  'thumbnailUrl': MockData.thumbnailUrl,
  'highlights': MockData.highlights,
  'agents': [
    {'name': 'teacher', 'status': 'Interpreting content & storytelling...'},
    {'name': 'analyst', 'status': 'Evaluating evidence & quality...'},
    {
      'name': 'explorer',
      'status': 'Discovering opportunities & connections...',
    },
  ],
};
