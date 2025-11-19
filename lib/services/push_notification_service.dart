import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
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
      print('🚀 Starting OneSignal initialization...');
      
      // Set App ID
      OneSignal.initialize(oneSignalAppId);
      print('✅ OneSignal App ID set: $oneSignalAppId');

      // Request notification permission based on platform
      if (Platform.isAndroid) {
        // For Android 13+ (API 33+), request POST_NOTIFICATIONS permission
        if (await _requestAndroidNotificationPermission()) {
          print('✅ Android notification permission granted');
        } else {
          print('⚠️ Android notification permission denied');
        }
      } else if (Platform.isIOS) {
        // For iOS, use OneSignal's built-in permission request
        final permissionGranted = await OneSignal.Notifications.requestPermission(true);
        print('📱 iOS notification permission: ${permissionGranted ? "granted" : "denied"}');
      }

      // Set up notification handlers
      _setupNotificationHandlers();

      // Ensure subscription is opted in
      await _ensureSubscriptionOptedIn();

      // Set external user ID if user is logged in
      await _setExternalUserId();

      // Log subscription status
      await _logSubscriptionStatus();

      _isInitialized = true;
      print('✅ OneSignal initialized successfully');
    } catch (e, stackTrace) {
      print('❌ Error initializing OneSignal: $e');
      print('❌ Stack trace: $stackTrace');
    }
  }

  /// Request notification permission for Android 13+
  Future<bool> _requestAndroidNotificationPermission() async {
    try {
      // Check if we're on Android 13+ (API 33+)
      if (Platform.isAndroid) {
        final status = await Permission.notification.status;
        print('📱 Current notification permission status: $status');
        
        if (status.isDenied) {
          print('📱 Requesting notification permission...');
          final result = await Permission.notification.request();
          print('📱 Permission request result: $result');
          return result.isGranted;
        } else if (status.isGranted) {
          print('📱 Notification permission already granted');
          return true;
        } else if (status.isPermanentlyDenied) {
          print('⚠️ Notification permission permanently denied');
          return false;
        }
      }
      return true; // For older Android versions, permission is granted by default
    } catch (e) {
      print('❌ Error requesting Android notification permission: $e');
      return false;
    }
  }

  /// Ensure subscription is opted in
  Future<void> _ensureSubscriptionOptedIn() async {
    try {
      final subscription = OneSignal.User.pushSubscription;
      final isOptedIn = subscription.optedIn ?? false;
      print('📱 Current subscription opt-in status: $isOptedIn');
      
      if (!isOptedIn) {
        print('📱 Opting in to push subscription...');
        await subscription.optIn();
        print('✅ Successfully opted in to push subscription');
      } else {
        print('✅ Already opted in to push subscription');
      }
    } catch (e) {
      print('❌ Error ensuring subscription opt-in: $e');
    }
  }

  /// Log subscription status for debugging
  Future<void> _logSubscriptionStatus() async {
    try {
      final subscription = OneSignal.User.pushSubscription;
      final playerId = subscription.id;
      final isOptedIn = subscription.optedIn;
      final token = subscription.token;
      
      print('📊 OneSignal Subscription Status:');
      print('   Player ID: $playerId');
      print('   Opted In: $isOptedIn');
      print('   Token: ${token != null ? "${token.substring(0, 20)}..." : "null"}');
    } catch (e) {
      print('❌ Error logging subscription status: $e');
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

