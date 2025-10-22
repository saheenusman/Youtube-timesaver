import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Service to manage device-specific authentication
/// Generates and stores a unique device ID for personalized experience
class DeviceIdService {
  static const String _deviceIdKey = 'device_id';
  static String? _cachedDeviceId;

  /// Get or generate a unique device ID
  static Future<String> getDeviceId() async {
    // Return cached ID if available
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      // Try to get existing device ID
      String? deviceId = prefs.getString(_deviceIdKey);

      if (deviceId == null) {
        // Generate new device ID
        deviceId = const Uuid().v4();
        await prefs.setString(_deviceIdKey, deviceId);
        print('📱 Generated new device ID: ${deviceId.substring(0, 8)}...');
      } else {
        print('📱 Using existing device ID: ${deviceId.substring(0, 8)}...');
      }

      // Cache for future use
      _cachedDeviceId = deviceId;
      return deviceId;
    } catch (e) {
      print('❌ Error managing device ID: $e');
      // Fallback to temporary ID if storage fails
      _cachedDeviceId = const Uuid().v4();
      return _cachedDeviceId!;
    }
  }

  /// Reset device ID (useful for testing or user reset)
  static Future<void> resetDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_deviceIdKey);
      _cachedDeviceId = null;
      print('🔄 Device ID reset');
    } catch (e) {
      print('❌ Error resetting device ID: $e');
    }
  }

  /// Get device ID for debugging (shortened version)
  static Future<String> getDeviceIdShort() async {
    final deviceId = await getDeviceId();
    return '${deviceId.substring(0, 8)}...';
  }
}
