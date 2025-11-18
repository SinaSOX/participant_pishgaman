import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:participant_pishgaman/services/auth_service.dart';

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  // OneSignal App ID
  static const String oneSignalAppId = 'bb390f33-ca3d-4b9a-aea3-4ed1255dee31';

  bool _isInitialized = false;

  bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Initialize OneSignal push notification service
  Future<void> init() async {
    if (!_isSupportedPlatform) {
      debugPrint('ℹ️ OneSignal unsupported on this platform. Skipping init.');
      return;
    }

    if (_isInitialized) {
      print('✅ OneSignal already initialized');
      return;
    }

    try {
      // Set App ID
      OneSignal.initialize(oneSignalAppId);

      // Request permission for iOS
      OneSignal.Notifications.requestPermission(true);

      // Set up notification handlers
      _setupNotificationHandlers();

      // Set external user ID if user is logged in
      await _setExternalUserId();

      _isInitialized = true;
      print('✅ OneSignal initialized successfully');
    } catch (e) {
      print('❌ Error initializing OneSignal: $e');
    }
  }

  /// Set up notification handlers
  void _setupNotificationHandlers() {
    // Handle notification received while app is in foreground
    OneSignal.Notifications.addClickListener((event) {
      print('📬 Notification clicked: ${event.notification.notificationId}');
      print('📬 Notification data: ${event.notification.additionalData}');
    });

    // Handle notification received
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      print('📬 Notification received in foreground: ${event.notification.notificationId}');
      // You can customize notification display here
      // event.notification.display() to show the notification
    });
  }

  /// Set external user ID based on logged-in user
  Future<void> _setExternalUserId() async {
    if (!_isSupportedPlatform) return;

    try {
      final authService = AuthService();
      final userId = authService.getUserId();
      
      if (userId != null && userId.isNotEmpty) {
        await OneSignal.login(userId);
        print('✅ OneSignal external user ID set: $userId');
      } else {
        print('⚠️ No user ID found, skipping OneSignal user login');
      }
    } catch (e) {
      print('❌ Error setting OneSignal external user ID: $e');
    }
  }

  /// Update external user ID when user logs in
  Future<void> updateUserLogin(String userId) async {
    if (!_isSupportedPlatform) return;

    try {
      if (!_isInitialized) {
        await init();
      }
      
      if (userId.isNotEmpty) {
        await OneSignal.login(userId);
        print('✅ OneSignal external user ID updated: $userId');
      }
    } catch (e) {
      print('❌ Error updating OneSignal external user ID: $e');
    }
  }

  /// Logout user from OneSignal
  Future<void> logout() async {
    if (!_isSupportedPlatform) return;

    try {
      await OneSignal.logout();
      print('✅ OneSignal user logged out');
    } catch (e) {
      print('❌ Error logging out from OneSignal: $e');
    }
  }

  /// Get OneSignal player ID (device ID)
  Future<String?> getPlayerId() async {
    if (!_isSupportedPlatform) return null;

    try {
      final subscription = OneSignal.User.pushSubscription;
      return subscription.id;
    } catch (e) {
      print('❌ Error getting OneSignal player ID: $e');
      return null;
    }
  }

  /// Send tags to OneSignal
  Future<void> sendTags(Map<String, String> tags) async {
    if (!_isSupportedPlatform) return;

    try {
      await OneSignal.User.addTags(tags);
      print('✅ OneSignal tags sent: $tags');
    } catch (e) {
      print('❌ Error sending OneSignal tags: $e');
    }
  }
}

