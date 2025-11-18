import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  final String version;
  final bool force;
  final String? updateUrl;
  final String? message;

  UpdateInfo({
    required this.version,
    required this.force,
    this.updateUrl,
    this.message,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    // Try multiple possible field names for update URL
    String? updateUrl;
    if (json['updateLink'] != null) {
      updateUrl = json['updateLink'].toString();
    } else if (json['update_url'] != null) {
      updateUrl = json['update_url'].toString();
    } else if (json['url'] != null) {
      updateUrl = json['url'].toString();
    } else if (json['download_url'] != null) {
      updateUrl = json['download_url'].toString();
    } else if (json['link'] != null) {
      updateUrl = json['link'].toString();
    } else if (json['updateUrl'] != null) {
      updateUrl = json['updateUrl'].toString();
    }
    
    // Clean up URL (remove null string)
    if (updateUrl != null && (updateUrl == 'null' || updateUrl.isEmpty)) {
      updateUrl = null;
    }
    
    return UpdateInfo(
      version: json['version']?.toString() ?? '',
      force: json['force'] == true || 
             json['force_update'] == true || 
             json['forceUpdate'] == true,
      updateUrl: updateUrl,
      message: json['message']?.toString() ?? json['description']?.toString(),
    );
  }
}

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  static const String updateCheckUrl = 'http://g.sinaseifouri.ir/update.json';
  static const Duration requestTimeout = Duration(seconds: 30);

  // Create HTTP client specifically for HTTP connections (no SSL)
  static http.Client _createHttpClient() {
    final httpClient = HttpClient();
    // Configure for HTTP connections with longer timeouts
    httpClient.connectionTimeout = const Duration(seconds: 30);
    httpClient.idleTimeout = const Duration(seconds: 30);
    // Auto-follow redirects
    httpClient.autoUncompress = true;
    // Allow more connections per host
    httpClient.maxConnectionsPerHost = 5;
    // Set user agent
    httpClient.userAgent = 'PishgamanApp/1.0';
    return IOClient(httpClient);
  }

  /// Check for app updates
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      print('🔍 Checking for updates from: $updateCheckUrl');
      
      final client = _createHttpClient();
      try {
        final headers = <String, String>{
          'Accept': 'application/json',
          'Connection': 'keep-alive',
          'User-Agent': 'PishgamanApp/1.0',
        };

        final response = await client
            .get(Uri.parse(updateCheckUrl), headers: headers)
            .timeout(
              requestTimeout,
              onTimeout: () {
                throw Exception('Timeout: درخواست بیش از حد طول کشید');
              },
            );

        print('📥 Update check response status: ${response.statusCode}');
        print('📥 Update check response body: ${response.body}');

        if (response.statusCode != 200) {
          print('⚠️ Update check failed with status: ${response.statusCode}');
          return null;
        }

        if (response.body.isEmpty) {
          print('⚠️ Update check returned empty response');
          return null;
        }

        // Parse JSON response
        Map<String, dynamic> responseData;
        try {
          responseData = jsonDecode(response.body) as Map<String, dynamic>;
          print('📋 JSON keys: ${responseData.keys.toList()}');
          print('📋 Full JSON: $responseData');
        } catch (e) {
          print('❌ JSON Parse Error: $e');
          return null;
        }

        final updateInfo = UpdateInfo.fromJson(responseData);
        print('✅ Update info parsed: version=${updateInfo.version}, force=${updateInfo.force}, url=${updateInfo.updateUrl}');
        
        if (updateInfo.updateUrl == null || updateInfo.updateUrl!.isEmpty) {
          print('⚠️ WARNING: Update URL is missing! Available keys in JSON: ${responseData.keys.toList()}');
        }

        // Get current app version
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;
        print('📱 Current app version: $currentVersion');
        print('📱 Server version: ${updateInfo.version}');

        // Compare versions
        final isNewer = _isNewerVersion(updateInfo.version, currentVersion);
        print('🔍 Version comparison: isNewer=$isNewer');
        
        if (isNewer) {
          print('🆕 New version available! Returning update info...');
          return updateInfo;
        } else {
          print('✅ App is up to date (current: $currentVersion, server: ${updateInfo.version})');
          return null;
        }
      } finally {
        client.close();
      }
    } catch (e) {
      print('❌ Error checking for updates: $e');
      return null;
    }
  }

  /// Compare version strings (e.g., "1.0.0" vs "1.0.1")
  bool _isNewerVersion(String serverVersion, String currentVersion) {
    try {
      print('🔍 Comparing versions: server="$serverVersion" vs current="$currentVersion"');
      
      // Remove any build number (e.g., "1.0.0+1" -> "1.0.0")
      final serverVersionClean = serverVersion.split('+').first.trim();
      final currentVersionClean = currentVersion.split('+').first.trim();
      
      print('🔍 Cleaned versions: server="$serverVersionClean" vs current="$currentVersionClean"');
      
      final serverParts = serverVersionClean.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final currentParts = currentVersionClean.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      print('🔍 Server parts: $serverParts');
      print('🔍 Current parts: $currentParts');

      // Ensure both lists have the same length
      while (serverParts.length < currentParts.length) {
        serverParts.add(0);
      }
      while (currentParts.length < serverParts.length) {
        currentParts.add(0);
      }

      print('🔍 Normalized parts - Server: $serverParts, Current: $currentParts');

      // Compare version parts
      for (int i = 0; i < serverParts.length; i++) {
        print('🔍 Comparing part $i: ${serverParts[i]} vs ${currentParts[i]}');
        if (serverParts[i] > currentParts[i]) {
          print('✅ Server version is newer (part $i: ${serverParts[i]} > ${currentParts[i]})');
          return true;
        } else if (serverParts[i] < currentParts[i]) {
          print('❌ Current version is newer (part $i: ${serverParts[i]} < ${currentParts[i]})');
          return false;
        }
      }

      print('✅ Versions are equal');
      return false; // Versions are equal
    } catch (e) {
      print('❌ Error comparing versions: $e');
      // If comparison fails, assume update is needed if versions are different
      final result = serverVersion != currentVersion;
      print('⚠️ Fallback comparison result: $result');
      return result;
    }
  }
}

