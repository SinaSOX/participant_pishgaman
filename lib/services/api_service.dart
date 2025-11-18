import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../models/feedback_entry.dart';
import '../models/gallery_post.dart';
import '../models/profile.dart';
import '../models/survey.dart';
import '../models/domain.dart';
import '../services/auth_service.dart';

class ApiService {
  // Base URL - Main domain (primary)
  static const String baseUrl = 'https://pishgaman.s79.ir/api';
  
  // Backup domain for all API requests (HTTP)
  static const String backupBaseUrl = 'http://g.sinaseifouri.ir/api';
  
  // Helper method to execute request with fallback to backup domain
  static Future<Map<String, dynamic>> _executeWithFallback(
    Future<Map<String, dynamic>> Function(String domainUrl) requestFunction,
  ) async {
    // Try primary domain first
    final primaryResult = await requestFunction(baseUrl);
    
    // If successful, return immediately
    if (primaryResult['success'] == true) {
      return primaryResult;
    }
    
    // Check if it's a connection/network error or server error
    final error = primaryResult['error']?.toString() ?? '';
    final statusCode = primaryResult['statusCode'];
    
    // Determine if we should try backup domain
    final shouldTryBackup = 
        // Connection/network errors
        error.contains('Connection') ||
        error.contains('Timeout') ||
        error.contains('SocketException') ||
        error.contains('ClientException') ||
        // No status code (likely connection error)
        statusCode == null ||
        // Server errors (5xx)
        (statusCode != null && statusCode >= 500) ||
        // Gateway/Service Unavailable errors
        statusCode == 502 || // Bad Gateway
        statusCode == 503 || // Service Unavailable
        statusCode == 504;   // Gateway Timeout
    
    // Try backup if it's a connection error or server error
    if (shouldTryBackup) {
      print('⚠️ Primary domain failed (error: $error, status: $statusCode), trying backup domain...');
      try {
        final backupResult = await requestFunction(backupBaseUrl);
        // If backup succeeds, return it
        if (backupResult['success'] == true) {
          print('✅ Backup domain succeeded');
          return backupResult;
        }
        // If backup also fails, return the backup result (or primary if backup has no status)
        return backupResult;
      } catch (e) {
        print('❌ Backup domain also failed: $e');
        // If backup throws exception, return primary result
        return primaryResult;
      }
    }
    
    // Return primary result if it's a business logic error (4xx except gateway errors)
    return primaryResult;
  }

  // Request timeout duration (120 seconds = 2 minutes)
  static const Duration requestTimeout = Duration(seconds: 120);

  // Create HTTP client with proper SSL configuration
  static http.Client _createHttpClient() {
    final httpClient = HttpClient();
    // Use default certificate validation
    // If you have SSL issues, you may need to configure this differently
    // Configure for better HTTP/HTTPS support
    httpClient.connectionTimeout = const Duration(seconds: 60);
    httpClient.idleTimeout = const Duration(seconds: 60);
    return IOClient(httpClient);
  }
  
  // Create HTTP client specifically for HTTP connections (no SSL)
  static http.Client _createHttpClientForHttp() {
    final httpClient = HttpClient();
    // Configure for HTTP connections with longer timeouts
    httpClient.connectionTimeout = const Duration(seconds: 60);
    httpClient.idleTimeout = const Duration(seconds: 60);
    // Auto-follow redirects
    httpClient.autoUncompress = true;
    // Allow more connections per host
    httpClient.maxConnectionsPerHost = 5;
    // Set user agent
    httpClient.userAgent = 'PishgamanApp/1.0';
    return IOClient(httpClient);
  }

  // Create HTTP client that mimics curl behavior exactly
  static http.Client _createCurlLikeHttpClient() {
    final httpClient = HttpClient();
    // Longer timeouts for surveys - give more time for connection
    httpClient.connectionTimeout = const Duration(seconds: 90);
    httpClient.idleTimeout = const Duration(seconds: 90);
    // Auto-uncompress responses
    httpClient.autoUncompress = true;
    // Use minimal settings like curl - one connection at a time
    httpClient.maxConnectionsPerHost = 1;
    // Don't set user agent explicitly - let it be minimal like curl
    return IOClient(httpClient);
  }

  // Send OTP code
  static Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    return _executeWithFallback((domainUrl) => _sendOtpToDomain(domainUrl, phoneNumber));
  }
  
  // Helper method to send OTP to a specific domain
  static Future<Map<String, dynamic>> _sendOtpToDomain(
    String domainUrl,
    String phoneNumber,
  ) async {
    final client = domainUrl.startsWith('http://')
        ? _createHttpClientForHttp()
        : _createHttpClient();
    try {
      print('📤 Sending OTP request to: $domainUrl/auth/send-otp');
      print('📱 Phone number: $phoneNumber');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      if (domainUrl.startsWith('http://')) {
        headers['Connection'] = 'keep-alive';
        headers['User-Agent'] = 'PishgamanApp/1.0';
      }

      final response = await client
          .post(
            Uri.parse('$domainUrl/auth/send-otp'),
            headers: headers,
            body: jsonEncode({'mobile': phoneNumber}),
          )
          .timeout(
            requestTimeout,
            onTimeout: () {
              throw Exception(
                'Timeout: درخواست بیش از حد طول کشید. لطفا اتصال اینترنت خود را بررسی کنید.',
              );
            },
          );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      // Check if response body is empty
      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'پاسخ خالی از سرور دریافت شد',
          'statusCode': response.statusCode,
        };
      }

      // Try to parse JSON
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        print('❌ JSON Parse Error: $e');
        return {
          'success': false,
          'message': 'خطا در پردازش پاسخ سرور',
          'statusCode': response.statusCode,
          'rawResponse': response.body,
        };
      }

      // Check status code
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'کد تأیید ارسال شد',
          'data': responseData['data'] ?? responseData,
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ??
              responseData['error'] ??
              'خطا در ارسال کد تأیید',
          'errors': responseData['errors'],
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Exception in _sendOtpToDomain ($domainUrl): $e');
      return {
        'success': false,
        'message': 'خطا در ارتباط با سرور. لطفا دوباره تلاش کنید.',
        'error': e.toString(),
      };
    } finally {
      client.close();
    }
  }

  // Verify OTP code
  static Future<Map<String, dynamic>> verifyOtp(
    String phoneNumber,
    String otpCode,
  ) async {
    return _executeWithFallback((domainUrl) => _verifyOtpToDomain(domainUrl, phoneNumber, otpCode));
  }
  
  // Helper method to verify OTP to a specific domain
  static Future<Map<String, dynamic>> _verifyOtpToDomain(
    String domainUrl,
    String phoneNumber,
    String otpCode,
  ) async {
    final client = domainUrl.startsWith('http://')
        ? _createHttpClientForHttp()
        : _createHttpClient();
    try {
      print('📤 Verifying OTP request to: $domainUrl/auth/verify-otp');
      print('📱 Phone number: $phoneNumber');
      print('🔐 OTP code: $otpCode');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      if (domainUrl.startsWith('http://')) {
        headers['Connection'] = 'keep-alive';
        headers['User-Agent'] = 'PishgamanApp/1.0';
      }

      final response = await client
          .post(
            Uri.parse('$domainUrl/auth/verify-otp'),
            headers: headers,
            body: jsonEncode({'mobile': phoneNumber, 'code': otpCode}),
          )
          .timeout(
            requestTimeout,
            onTimeout: () {
              throw Exception(
                'Timeout: درخواست بیش از حد طول کشید. لطفا اتصال اینترنت خود را بررسی کنید.',
              );
            },
          );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      // Check if response body is empty
      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'پاسخ خالی از سرور دریافت شد',
          'statusCode': response.statusCode,
        };
      }

      // Try to parse JSON
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        print('❌ JSON Parse Error: $e');
        return {
          'success': false,
          'message': 'خطا در پردازش پاسخ سرور',
          'statusCode': response.statusCode,
          'rawResponse': response.body,
        };
      }

      // Check status code
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Try different possible response structures
        final data = responseData['data'] ?? responseData;
        return {
          'success': true,
          'message': responseData['message'] ?? 'ورود موفقیت‌آمیز بود',
          'data': data,
          'token': data['token'] ?? responseData['token'],
          'user': data['user'] ?? responseData['user'],
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ??
              responseData['error'] ??
              'کد تأیید نامعتبر است',
          'errors': responseData['errors'],
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Exception in _verifyOtpToDomain ($domainUrl): $e');
      return {
        'success': false,
        'message': 'خطا در ارتباط با سرور. لطفا دوباره تلاش کنید.',
        'error': e.toString(),
      };
    } finally {
      client.close();
    }
  }

  // Get gallery posts
  // No authentication required - public endpoint
  static Future<Map<String, dynamic>> getGalleryPosts({
    int page = 1,
    int limit = 20,
  }) async {
    return _executeWithFallback((domainUrl) => _getGalleryPostsFromDomain(domainUrl, page, limit));
  }
  
  // Helper method to get gallery posts from a specific domain
  static Future<Map<String, dynamic>> _getGalleryPostsFromDomain(
    String domainUrl,
    int page,
    int limit,
  ) async {
    // Use HTTP-specific client for HTTP connections
    final client = domainUrl.startsWith('http://')
        ? _createHttpClientForHttp()
        : _createHttpClient();
    try {
      // Build URL with query parameters
      final uri = Uri.parse('$domainUrl/gallery/list').replace(
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );

      print('📤 Fetching gallery posts from: $uri');

      final headers = {
        'Accept': 'application/json',
      };
      
      if (domainUrl.startsWith('http://')) {
        headers['Connection'] = 'keep-alive';
        headers['User-Agent'] = 'PishgamanApp/1.0';
      }

      final response = await client
          .get(uri, headers: headers)
          .timeout(
            requestTimeout,
            onTimeout: () {
              throw Exception(
                'Timeout: درخواست بیش از حد طول کشید. لطفا اتصال اینترنت خود را بررسی کنید.',
              );
            },
          );

      print('📥 Response status: ${response.statusCode}');
      final bodyPreview = response.body.length > 500
          ? '${response.body.substring(0, 500)}...'
          : response.body;
      print('📥 Response body: $bodyPreview');

      // Check for HTTP errors first (before trying to parse)
      if (response.statusCode == 403) {
        return {
          'success': false,
          'message':
              'دسترسی غیرمجاز. لطفا مطمئن شوید که وارد حساب کاربری خود شده‌اید.',
          'statusCode': 403,
        };
      }

      if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'احراز هویت نامعتبر است. لطفا دوباره وارد شوید.',
          'statusCode': 401,
        };
      }

      if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'آدرس درخواستی یافت نشد. لطفا با پشتیبانی تماس بگیرید.',
          'statusCode': 404,
        };
      }

      // Check if response body is empty
      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'پاسخ خالی از سرور دریافت شد',
          'statusCode': response.statusCode,
        };
      }

      // Check if response is HTML (error page from nginx/server)
      if (response.body.trim().startsWith('<html>') ||
          response.body.trim().startsWith('<!DOCTYPE')) {
        String errorMessage = 'خطا در ارتباط با سرور';
        if (response.statusCode == 403) {
          errorMessage =
              'دسترسی غیرمجاز. لطفا مطمئن شوید که وارد حساب کاربری خود شده‌اید.';
        } else if (response.statusCode == 404) {
          errorMessage = 'آدرس درخواستی یافت نشد.';
        } else if (response.statusCode >= 500) {
          errorMessage = 'خطا در سرور. لطفا بعدا تلاش کنید.';
        }
        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode,
        };
      }

      // Try to parse JSON
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        print('❌ JSON Parse Error: $e');
        // If it's an error status code, return appropriate message
        if (response.statusCode >= 400) {
          String errorMsg = 'خطا در ارتباط با سرور';
          if (response.statusCode == 403) {
            errorMsg = 'دسترسی غیرمجاز';
          } else if (response.statusCode == 404) {
            errorMsg = 'آدرس یافت نشد';
          } else if (response.statusCode >= 500) {
            errorMsg = 'خطا در سرور';
          }
          return {
            'success': false,
            'message': '$errorMsg (کد خطا: ${response.statusCode})',
            'statusCode': response.statusCode,
          };
        }
        return {
          'success': false,
          'message': 'خطا در پردازش پاسخ سرور',
          'statusCode': response.statusCode,
          'rawResponse': response.body,
        };
      }

      // Check status code
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Parse gallery posts from response
        // API response structure: { "success": true, "data": { "images": [...], "pagination": {...} } }
        // Also support other structures for compatibility
        List<GalleryPost> posts = [];

        if (responseData is List) {
          // Direct array response
          final listData = responseData as List;
          posts = listData
              .map((item) => GalleryPost.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          final responseMap = responseData;

          if (responseMap['data'] != null) {
            final data = responseMap['data'];
            if (data is List) {
              // { "data": [...] }
              posts = data
                  .map(
                    (item) =>
                        GalleryPost.fromJson(item as Map<String, dynamic>),
                  )
                  .toList();
            } else if (data is Map) {
              // { "data": { "images": [...] } } - Current API structure
              if (data['images'] != null && data['images'] is List) {
                final imagesList = data['images'] as List;
                posts = imagesList
                    .map(
                      (item) =>
                          GalleryPost.fromJson(item as Map<String, dynamic>),
                    )
                    .toList();
              } else if (data['posts'] != null && data['posts'] is List) {
                // { "data": { "posts": [...] } }
                final postsList = data['posts'] as List;
                posts = postsList
                    .map(
                      (item) =>
                          GalleryPost.fromJson(item as Map<String, dynamic>),
                    )
                    .toList();
              } else if (data['data'] != null && data['data'] is List) {
                // { "data": { "data": [...] } }
                final postsList = data['data'] as List;
                posts = postsList
                    .map(
                      (item) =>
                          GalleryPost.fromJson(item as Map<String, dynamic>),
                    )
                    .toList();
              }
            }
          } else if (responseMap['posts'] != null &&
              responseMap['posts'] is List) {
            // { "posts": [...] }
            final postsList = responseMap['posts'] as List;
            posts = postsList
                .map(
                  (item) => GalleryPost.fromJson(item as Map<String, dynamic>),
                )
                .toList();
          } else if (responseMap['images'] != null &&
              responseMap['images'] is List) {
            // { "images": [...] }
            final imagesList = responseMap['images'] as List;
            posts = imagesList
                .map(
                  (item) => GalleryPost.fromJson(item as Map<String, dynamic>),
                )
                .toList();
          }
        }

        String message = 'پست‌های گالری با موفقیت دریافت شد';
        if (responseData.containsKey('message')) {
          message = responseData['message'].toString();
        }

        return {'success': true, 'message': message, 'data': posts};
      } else {
        // Handle different error response formats
        String errorMessage = 'خطا در دریافت پست‌های گالری';
        if (responseData.containsKey('message')) {
          errorMessage = responseData['message'].toString();
        } else if (responseData.containsKey('error')) {
          errorMessage = responseData['error'].toString();
        } else if (responseData.containsKey('errors')) {
          final errors = responseData['errors'];
          if (errors is Map && errors.isNotEmpty) {
            errorMessage = errors.values.first.toString();
          } else if (errors is List && errors.isNotEmpty) {
            errorMessage = errors.first.toString();
          }
        }

        return {
          'success': false,
          'message': errorMessage,
          'errors': responseData['errors'],
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Exception in _getGalleryPostsFromDomain ($domainUrl): $e');
      return {
        'success': false,
        'message': 'خطا در ارتباط با سرور. لطفا دوباره تلاش کنید.',
        'error': e.toString(),
      };
    } finally {
      client.close();
    }
  }

  // Get user profile
  static Future<Map<String, dynamic>> getProfile() async {
    final authService = AuthService();
    final token = authService.getToken();
    final userId = authService.getUserId();

    if (token == null) {
      return {
        'success': false,
        'message': 'لطفا ابتدا وارد حساب کاربری خود شوید.',
      };
    }

    if (userId == null) {
      return {
        'success': false,
        'message': 'شناسه کاربری یافت نشد. لطفا دوباره وارد شوید.',
      };
    }

    return _executeWithFallback((domainUrl) => _getProfileFromDomain(domainUrl, userId, token));
  }
  
  // Helper method to get profile from a specific domain
  static Future<Map<String, dynamic>> _getProfileFromDomain(
    String domainUrl,
    String userId,
    String token,
  ) async {
    final client = domainUrl.startsWith('http://')
        ? _createHttpClientForHttp()
        : _createHttpClient();
    try {
      print('📤 Fetching profile from: $domainUrl/profiles/$userId');

      final headers = <String, String>{
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
      
      if (domainUrl.startsWith('http://')) {
        headers['Connection'] = 'keep-alive';
        headers['User-Agent'] = 'PishgamanApp/1.0';
      }

      final response = await client
          .get(Uri.parse('$domainUrl/profiles/$userId'), headers: headers)
          .timeout(
            requestTimeout,
            onTimeout: () {
              throw Exception(
                'Timeout: درخواست بیش از حد طول کشید. لطفا اتصال اینترنت خود را بررسی کنید.',
              );
            },
          );

      print('📥 Response status: ${response.statusCode}');
      final bodyPreview = response.body.length > 500
          ? '${response.body.substring(0, 500)}...'
          : response.body;
      print('📥 Response body: $bodyPreview');

      // Check for HTTP errors first
      if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'احراز هویت نامعتبر است. لطفا دوباره وارد شوید.',
          'statusCode': 401,
        };
      }

      if (response.statusCode == 403) {
        return {
          'success': false,
          'message':
              'دسترسی غیرمجاز. لطفا مطمئن شوید که وارد حساب کاربری خود شده‌اید.',
          'statusCode': 403,
        };
      }

      if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'پروفایل یافت نشد.',
          'statusCode': 404,
        };
      }

      // Check if response body is empty
      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'پاسخ خالی از سرور دریافت شد',
          'statusCode': response.statusCode,
        };
      }

      // Check if response is HTML (error page from nginx/server)
      if (response.body.trim().startsWith('<html>') ||
          response.body.trim().startsWith('<!DOCTYPE')) {
        String errorMessage = 'خطا در ارتباط با سرور';
        if (response.statusCode == 403) {
          errorMessage =
              'دسترسی غیرمجاز. لطفا مطمئن شوید که وارد حساب کاربری خود شده‌اید.';
        } else if (response.statusCode == 404) {
          errorMessage = 'پروفایل یافت نشد.';
        } else if (response.statusCode >= 500) {
          errorMessage = 'خطا در سرور. لطفا بعدا تلاش کنید.';
        }
        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode,
        };
      }

      // Try to parse JSON
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        print('❌ JSON Parse Error: $e');
        if (response.statusCode >= 400) {
          String errorMsg = 'خطا در ارتباط با سرور';
          if (response.statusCode == 403) {
            errorMsg = 'دسترسی غیرمجاز';
          } else if (response.statusCode == 404) {
            errorMsg = 'پروفایل یافت نشد';
          } else if (response.statusCode >= 500) {
            errorMsg = 'خطا در سرور';
          }
          return {
            'success': false,
            'message': '$errorMsg (کد خطا: ${response.statusCode})',
            'statusCode': response.statusCode,
          };
        }
        return {
          'success': false,
          'message': 'خطا در پردازش پاسخ سرور',
          'statusCode': response.statusCode,
          'rawResponse': response.body,
        };
      }

      // Check status code
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Parse profile from response
        Profile? profile;

        print('🔍 Parsing profile data in getProfile...');
        print('🔍 Response data keys: ${responseData.keys.toList()}');

        if (responseData['data'] != null) {
          final data = responseData['data'];
          print('🔍 Found data field, type: ${data.runtimeType}');
          if (data is Map) {
            print('🔍 Data is Map, parsing...');
            print('🔍 Data content: $data');
            try {
              profile = Profile.fromJson(data as Map<String, dynamic>);
              print('✅ Profile parsed successfully from data field');
            } catch (e, stackTrace) {
              print('❌ Error parsing profile from data: $e');
              print('❌ Stack trace: $stackTrace');
            }
          } else if (data is List && data.isNotEmpty) {
            print('🔍 Data is List, using first item...');
            try {
              profile = Profile.fromJson(data[0] as Map<String, dynamic>);
              print('✅ Profile parsed successfully from list');
            } catch (e, stackTrace) {
              print('❌ Error parsing profile from list: $e');
              print('❌ Stack trace: $stackTrace');
            }
          }
        } else if (responseData.containsKey('id') ||
            responseData.containsKey('user_id')) {
          // Direct profile object
          print('🔍 Direct profile object found, parsing...');
          print('🔍 Response data: $responseData');
          try {
            profile = Profile.fromJson(responseData);
            print('✅ Profile parsed successfully from direct object');
          } catch (e, stackTrace) {
            print('❌ Error parsing profile from direct object: $e');
            print('❌ Stack trace: $stackTrace');
          }
        } else {
          print('⚠️ No profile data found in response');
          print('🔍 Available keys: ${responseData.keys.toList()}');
          print('🔍 Full response: $responseData');
        }

        if (profile == null) {
          print('❌ Profile is null after parsing');
          return {
            'success': false,
            'message':
                'خطا در پردازش داده‌های پروفایل. ساختار پاسخ نامعتبر است.',
            'statusCode': response.statusCode,
            'rawResponse': responseData,
          };
        }

        String message = 'پروفایل با موفقیت دریافت شد';
        if (responseData.containsKey('message')) {
          message = responseData['message'].toString();
        }

        return {'success': true, 'message': message, 'data': profile};
      } else {
        // Handle different error response formats
        String errorMessage = 'خطا در دریافت پروفایل';
        if (responseData.containsKey('message')) {
          errorMessage = responseData['message'].toString();
        } else if (responseData.containsKey('error')) {
          errorMessage = responseData['error'].toString();
        } else if (responseData.containsKey('errors')) {
          final errors = responseData['errors'];
          if (errors is Map && errors.isNotEmpty) {
            errorMessage = errors.values.first.toString();
          } else if (errors is List && errors.isNotEmpty) {
            errorMessage = errors.first.toString();
          }
        }

        return {
          'success': false,
          'message': errorMessage,
          'errors': responseData['errors'],
          'statusCode': response.statusCode,
        };
      }
    } catch (e, stackTrace) {
      print('❌ Exception in getProfile: $e');
      print('❌ Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'خطا در ارتباط با سرور. لطفا دوباره تلاش کنید.',
        'error': e.toString(),
      };
    } finally {
      client.close();
    }
  }

  // Get user profile by ID
  // Public endpoint - no authentication required
  static Future<Map<String, dynamic>> getProfileById(int userId) async {
    return _executeWithFallback((domainUrl) => _getProfileByIdFromDomain(domainUrl, userId));
  }
  
  // Helper method to get profile by ID from a specific domain
  static Future<Map<String, dynamic>> _getProfileByIdFromDomain(
    String domainUrl,
    int userId,
  ) async {
    final client = domainUrl.startsWith('http://')
        ? _createHttpClientForHttp()
        : _createHttpClient();
    try {
      print('📤 Fetching profile from: $domainUrl/profiles/$userId');

      final headers = <String, String>{
        'Accept': 'application/json',
      };
      
      if (domainUrl.startsWith('http://')) {
        headers['Connection'] = 'keep-alive';
        headers['User-Agent'] = 'PishgamanApp/1.0';
      }

      final response = await client
          .get(Uri.parse('$domainUrl/profiles/$userId'), headers: headers)
          .timeout(
            requestTimeout,
            onTimeout: () {
              throw Exception(
                'Timeout: درخواست بیش از حد طول کشید. لطفا اتصال اینترنت خود را بررسی کنید.',
              );
            },
          );

      print('📥 Response status: ${response.statusCode}');
      final bodyPreview = response.body.length > 500
          ? '${response.body.substring(0, 500)}...'
          : response.body;
      print('📥 Response body: $bodyPreview');

      // Check for HTTP errors first
      if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'احراز هویت نامعتبر است. لطفا دوباره وارد شوید.',
          'statusCode': 401,
        };
      }

      if (response.statusCode == 403) {
        return {
          'success': false,
          'message':
              'دسترسی غیرمجاز. لطفا مطمئن شوید که وارد حساب کاربری خود شده‌اید.',
          'statusCode': 403,
        };
      }

      if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'پروفایل کاربر یافت نشد.',
          'statusCode': 404,
        };
      }

      // Check if response body is empty
      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'پاسخ خالی از سرور دریافت شد',
          'statusCode': response.statusCode,
        };
      }

      // Check if response is HTML (error page from nginx/server)
      if (response.body.trim().startsWith('<html>') ||
          response.body.trim().startsWith('<!DOCTYPE')) {
        String errorMessage = 'خطا در ارتباط با سرور';
        if (response.statusCode == 403) {
          errorMessage =
              'دسترسی غیرمجاز. لطفا مطمئن شوید که وارد حساب کاربری خود شده‌اید.';
        } else if (response.statusCode == 404) {
          errorMessage = 'پروفایل کاربر یافت نشد.';
        } else if (response.statusCode >= 500) {
          errorMessage = 'خطا در سرور. لطفا بعدا تلاش کنید.';
        }
        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode,
        };
      }

      // Try to parse JSON
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        print('❌ JSON Parse Error: $e');
        if (response.statusCode >= 400) {
          String errorMsg = 'خطا در ارتباط با سرور';
          if (response.statusCode == 403) {
            errorMsg = 'دسترسی غیرمجاز';
          } else if (response.statusCode == 404) {
            errorMsg = 'پروفایل کاربر یافت نشد';
          } else if (response.statusCode >= 500) {
            errorMsg = 'خطا در سرور';
          }
          return {
            'success': false,
            'message': '$errorMsg (کد خطا: ${response.statusCode})',
            'statusCode': response.statusCode,
          };
        }
        return {
          'success': false,
          'message': 'خطا در پردازش پاسخ سرور',
          'statusCode': response.statusCode,
          'rawResponse': response.body,
        };
      }

      // Check status code
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Parse profile from response
        Profile? profile;

        print('🔍 Parsing profile data in getProfileById...');
        print('🔍 Response data keys: ${responseData.keys.toList()}');

        if (responseData['data'] != null) {
          final data = responseData['data'];
          print('🔍 Found data field, type: ${data.runtimeType}');
          if (data is Map) {
            print('🔍 Data is Map, parsing...');
            print('🔍 Data content: $data');
            try {
              profile = Profile.fromJson(data as Map<String, dynamic>);
              print('✅ Profile parsed successfully from data field');
            } catch (e, stackTrace) {
              print('❌ Error parsing profile from data: $e');
              print('❌ Stack trace: $stackTrace');
            }
          } else if (data is List && data.isNotEmpty) {
            print('🔍 Data is List, using first item...');
            try {
              profile = Profile.fromJson(data[0] as Map<String, dynamic>);
              print('✅ Profile parsed successfully from list');
            } catch (e, stackTrace) {
              print('❌ Error parsing profile from list: $e');
              print('❌ Stack trace: $stackTrace');
            }
          }
        } else if (responseData.containsKey('id') ||
            responseData.containsKey('user_id')) {
          // Direct profile object
          print('🔍 Direct profile object found, parsing...');
          print('🔍 Response data: $responseData');
          try {
            profile = Profile.fromJson(responseData);
            print('✅ Profile parsed successfully from direct object');
          } catch (e, stackTrace) {
            print('❌ Error parsing profile from direct object: $e');
            print('❌ Stack trace: $stackTrace');
          }
        } else {
          print('⚠️ No profile data found in response');
          print('🔍 Available keys: ${responseData.keys.toList()}');
          print('🔍 Full response: $responseData');
        }

        if (profile == null) {
          print('❌ Profile is null after parsing');
          return {
            'success': false,
            'message':
                'خطا در پردازش داده‌های پروفایل. ساختار پاسخ نامعتبر است.',
            'statusCode': response.statusCode,
            'rawResponse': responseData,
          };
        }

        String message = 'پروفایل با موفقیت دریافت شد';
        if (responseData.containsKey('message')) {
          message = responseData['message'].toString();
        }

        return {'success': true, 'message': message, 'data': profile};
      } else {
        // Handle different error response formats
        String errorMessage = 'خطا در دریافت پروفایل';
        if (responseData.containsKey('message')) {
          errorMessage = responseData['message'].toString();
        } else if (responseData.containsKey('error')) {
          errorMessage = responseData['error'].toString();
        } else if (responseData.containsKey('errors')) {
          final errors = responseData['errors'];
          if (errors is Map && errors.isNotEmpty) {
            errorMessage = errors.values.first.toString();
          } else if (errors is List && errors.isNotEmpty) {
            errorMessage = errors.first.toString();
          }
        }

        return {
          'success': false,
          'message': errorMessage,
          'errors': responseData['errors'],
          'statusCode': response.statusCode,
        };
      }
    } catch (e, stackTrace) {
      print('❌ Exception in getProfileById: $e');
      print('❌ Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'خطا در ارتباط با سرور. لطفا دوباره تلاش کنید.',
        'error': e.toString(),
      };
    } finally {
      client.close();
    }
  }

  // Update or create user profile
  static Future<Map<String, dynamic>> updateProfile(
    int userId,
    Map<String, dynamic> profileData,
  ) async {
    final authService = AuthService();
    final token = authService.getToken();

    if (token == null) {
      return {
        'success': false,
        'message': 'لطفا ابتدا وارد حساب کاربری خود شوید.',
      };
    }

    return _executeWithFallback((domainUrl) => _updateProfileToDomain(domainUrl, userId, profileData, token));
  }
  
  // Helper method to update profile to a specific domain
  static Future<Map<String, dynamic>> _updateProfileToDomain(
    String domainUrl,
    int userId,
    Map<String, dynamic> profileData,
    String token,
  ) async {
    final client = domainUrl.startsWith('http://')
        ? _createHttpClientForHttp()
        : _createHttpClient();
    try {
      print('📤 Updating profile for user: $userId');
      print('📤 Profile data: $profileData');

      final headers = <String, String>{
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
      
      if (domainUrl.startsWith('http://')) {
        headers['Connection'] = 'keep-alive';
        headers['User-Agent'] = 'PishgamanApp/1.0';
      }

      final response = await client
          .put(
            Uri.parse('$domainUrl/profiles/$userId'),
            headers: headers,
            body: jsonEncode(profileData),
          )
          .timeout(
            requestTimeout,
            onTimeout: () {
              throw Exception(
                'Timeout: درخواست بیش از حد طول کشید. لطفا اتصال اینترنت خود را بررسی کنید.',
              );
            },
          );

      print('📥 Response status: ${response.statusCode}');
      final bodyPreview = response.body.length > 500
          ? '${response.body.substring(0, 500)}...'
          : response.body;
      print('📥 Response body: $bodyPreview');

      // Check for HTTP errors first
      if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'احراز هویت نامعتبر است. لطفا دوباره وارد شوید.',
          'statusCode': 401,
        };
      }

      if (response.statusCode == 403) {
        return {
          'success': false,
          'message':
              'دسترسی غیرمجاز. لطفا مطمئن شوید که وارد حساب کاربری خود شده‌اید.',
          'statusCode': 403,
        };
      }

      // Check if response body is empty
      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'پاسخ خالی از سرور دریافت شد',
          'statusCode': response.statusCode,
        };
      }

      // Check if response is HTML (error page from nginx/server)
      if (response.body.trim().startsWith('<html>') ||
          response.body.trim().startsWith('<!DOCTYPE')) {
        String errorMessage = 'خطا در ارتباط با سرور';
        if (response.statusCode == 403) {
          errorMessage =
              'دسترسی غیرمجاز. لطفا مطمئن شوید که وارد حساب کاربری خود شده‌اید.';
        } else if (response.statusCode >= 500) {
          errorMessage = 'خطا در سرور. لطفا بعدا تلاش کنید.';
        }
        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode,
        };
      }

      // Try to parse JSON
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        print('❌ JSON Parse Error: $e');
        if (response.statusCode >= 400) {
          String errorMsg = 'خطا در ارتباط با سرور';
          if (response.statusCode == 403) {
            errorMsg = 'دسترسی غیرمجاز';
          } else if (response.statusCode >= 500) {
            errorMsg = 'خطا در سرور';
          }
          return {
            'success': false,
            'message': '$errorMsg (کد خطا: ${response.statusCode})',
            'statusCode': response.statusCode,
          };
        }
        return {
          'success': false,
          'message': 'خطا در پردازش پاسخ سرور',
          'statusCode': response.statusCode,
          'rawResponse': response.body,
        };
      }

      // Check status code
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Parse profile from response
        Profile? profile;

        if (responseData['data'] != null) {
          final data = responseData['data'];
          if (data is Map) {
            try {
              profile = Profile.fromJson(data as Map<String, dynamic>);
            } catch (e) {
              print('❌ Error parsing profile from data: $e');
            }
          } else if (data is List && data.isNotEmpty) {
            try {
              profile = Profile.fromJson(data[0] as Map<String, dynamic>);
            } catch (e) {
              print('❌ Error parsing profile from list: $e');
            }
          }
        } else if (responseData.containsKey('id') ||
            responseData.containsKey('user_id')) {
          try {
            profile = Profile.fromJson(responseData);
          } catch (e) {
            print('❌ Error parsing profile from direct object: $e');
          }
        }

        String message = 'پروفایل با موفقیت به‌روزرسانی شد';
        if (responseData.containsKey('message')) {
          message = responseData['message'].toString();
        }

        return {'success': true, 'message': message, 'data': profile};
      } else {
        // Handle different error response formats
        String errorMessage = 'خطا در به‌روزرسانی پروفایل';
        if (responseData.containsKey('message')) {
          errorMessage = responseData['message'].toString();
        } else if (responseData.containsKey('error')) {
          errorMessage = responseData['error'].toString();
        } else if (responseData.containsKey('errors')) {
          final errors = responseData['errors'];
          if (errors is Map && errors.isNotEmpty) {
            errorMessage = errors.values.first.toString();
          } else if (errors is List && errors.isNotEmpty) {
            errorMessage = errors.first.toString();
          }
        }

        return {
          'success': false,
          'message': errorMessage,
          'errors': responseData['errors'],
          'statusCode': response.statusCode,
        };
      }
    } catch (e, stackTrace) {
      print('❌ Exception in updateProfile: $e');
      print('❌ Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'خطا در ارتباط با سرور. لطفا دوباره تلاش کنید.',
        'error': e.toString(),
      };
    } finally {
      client.close();
    }
  }

  // Create a new feedback entry
  static Future<Map<String, dynamic>> submitFeedback({
    required String userIdentifier,
    required String message,
    String category = 'suggestion',
    String? subject,
    String? contactInfo,
  }) async {
    final payload = <String, dynamic>{
      'user_identifier': userIdentifier,
      'message': message,
      'category': category,
      'subject': (subject == null || subject.trim().isEmpty)
          ? 'بازخورد اپلیکیشن'
          : subject.trim(),
      if (contactInfo != null && contactInfo.trim().isNotEmpty)
        'contact_info': contactInfo.trim(),
    };

    print('📤 Submitting feedback: $payload');

    return _executeWithFallback((domainUrl) => _submitFeedbackToDomain(domainUrl, payload));
  }

  // Helper method to submit feedback to a specific domain
  static Future<Map<String, dynamic>> _submitFeedbackToDomain(
    String domainUrl,
    Map<String, dynamic> payload,
  ) async {
    // Use HTTP-specific client if domain is HTTP
    final client = domainUrl.startsWith('http://')
        ? _createHttpClientForHttp()
        : _createHttpClient();
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      // Add additional headers for HTTP connections
      if (domainUrl.startsWith('http://')) {
        headers['Connection'] = 'keep-alive';
        headers['User-Agent'] = 'PishgamanApp/1.0';
      }
      
      final response = await client
          .post(
            Uri.parse('$domainUrl/feedback/create'),
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(
            requestTimeout,
            onTimeout: () {
              throw Exception(
                'Timeout: درخواست پس از مدت طولانی پاسخ نداد. لطفا دوباره تلاش کنید.',
              );
            },
          );

      print('📥 Feedback submit status: ${response.statusCode}');
      print('📥 Feedback submit body: ${response.body}');

      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'پاسخ خالی از سرور دریافت شد',
          'statusCode': response.statusCode,
        };
      }

      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        print('❌ JSON Parse Error (submitFeedback): $e');
        return {
          'success': false,
          'message': 'خطا در پردازش پاسخ سرور',
          'statusCode': response.statusCode,
          'rawResponse': response.body,
        };
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message':
              responseData['message']?.toString() ??
              'بازخورد شما با موفقیت ثبت شد',
          'data': responseData['data'],
        };
      }

      return {
        'success': false,
        'message':
            responseData['message']?.toString() ??
            responseData['error']?.toString() ??
            'ثبت بازخورد با خطا مواجه شد',
        'errors': responseData['errors'],
        'statusCode': response.statusCode,
      };
    } catch (e) {
      print('❌ Exception in _submitFeedbackToDomain ($domainUrl): $e');
      return {
        'success': false,
        'message': 'خطا در ارتباط با سرور. لطفا دوباره تلاش کنید.',
        'error': e.toString(),
      };
    } finally {
      client.close();
    }
  }

  // Retrieve feedback list for a user
  static Future<Map<String, dynamic>> getFeedbackList(
    String userIdentifier,
  ) async {
    return _executeWithFallback((domainUrl) => _getFeedbackListFromDomain(domainUrl, userIdentifier));
  }

  // Helper method to get feedback list from a specific domain
  static Future<Map<String, dynamic>> _getFeedbackListFromDomain(
    String domainUrl,
    String userIdentifier,
  ) async {
    // Use HTTP-specific client if domain is HTTP
    final client = domainUrl.startsWith('http://')
        ? _createHttpClientForHttp()
        : _createHttpClient();
    try {
      final uri = Uri.parse(
        '$domainUrl/feedback/list',
      ).replace(queryParameters: {'user_identifier': userIdentifier});

      print('📤 Fetching feedback list from: $uri');

      final headers = <String, String>{
        'Accept': 'application/json',
      };
      
      // Add additional headers for HTTP connections
      if (domainUrl.startsWith('http://')) {
        headers['Connection'] = 'keep-alive';
        headers['User-Agent'] = 'PishgamanApp/1.0';
      }

      final response = await client
          .get(uri, headers: headers)
          .timeout(
            requestTimeout,
            onTimeout: () {
              throw Exception(
                'Timeout: درخواست پس از مدت طولانی پاسخ نداد. لطفا دوباره تلاش کنید.',
              );
            },
          );

      print('📥 Feedback list status: ${response.statusCode}');
      final bodyPreview = response.body.length > 500
          ? '${response.body.substring(0, 500)}...'
          : response.body;
      print('📥 Feedback list body: $bodyPreview');

      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'پاسخ خالی از سرور دریافت شد',
          'statusCode': response.statusCode,
        };
      }

      if (response.body.trim().startsWith('<html>') ||
          response.body.trim().startsWith('<!DOCTYPE')) {
        return {
          'success': false,
          'message': 'پاسخ نامعتبر از سمت سرور دریافت شد',
          'statusCode': response.statusCode,
        };
      }

      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        print('❌ JSON Parse Error (getFeedbackList): $e');
        return {
          'success': false,
          'message': 'خطا در پردازش پاسخ سرور',
          'statusCode': response.statusCode,
        };
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = responseData['data'];
        List<FeedbackEntry> entries = [];
        if (data is List) {
          entries = data
              .map(
                (item) => FeedbackEntry.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList();
        }
        return {
          'success': true,
          'message':
              responseData['message']?.toString() ??
              'بازخوردها با موفقیت دریافت شد',
          'data': entries,
          'meta': responseData['meta'],
        };
      }

      return {
        'success': false,
        'message':
            responseData['message']?.toString() ??
            responseData['error']?.toString() ??
            'خطا در دریافت بازخوردها',
        'statusCode': response.statusCode,
        'errors': responseData['errors'],
      };
    } catch (e) {
      print('❌ Exception in _getFeedbackListFromDomain ($domainUrl): $e');
      return {
        'success': false,
        'message': 'خطا در ارتباط با سرور. لطفا دوباره تلاش کنید.',
        'error': e.toString(),
      };
    } finally {
      client.close();
    }
  }

  // Get surveys list
  static Future<Map<String, dynamic>> getSurveys({
    required String userId,
    bool includeQuestions = true,
  }) async {
    return _executeWithFallback((domainUrl) => _getSurveysFromDomain(domainUrl, userId, includeQuestions));
  }
  
  // Helper method to get surveys from a specific domain
  static Future<Map<String, dynamic>> _getSurveysFromDomain(
    String domainUrl,
    String userId,
    bool includeQuestions,
  ) async {
    // Create fresh client for each attempt (like curl does)
    final client = domainUrl.startsWith('http://')
        ? _createCurlLikeHttpClient()
        : _createHttpClient();
    try {
      // Build URL with query parameters
      final uri = Uri.parse('$domainUrl/surveys/list').replace(
        queryParameters: {
          'user_id': userId,
          'include_questions': includeQuestions.toString(),
          'with_questions': includeQuestions.toString(),
        },
      );

      print('📤 Fetching surveys from: $uri');
      print('📤 Headers: accept: application/json (curl-like)');

      // Minimal headers - exactly like curl: only accept header
      final headers = <String, String>{
        'accept': 'application/json',
      };
      
      if (domainUrl.startsWith('http://')) {
        headers['Connection'] = 'keep-alive';
        headers['User-Agent'] = 'PishgamanApp/1.0';
      }

      // Use longer timeout for surveys endpoint
      final extendedTimeout = const Duration(seconds: 150);
      
      final response = await client
          .get(uri, headers: headers)
          .timeout(
            extendedTimeout,
            onTimeout: () {
              throw Exception(
                'Timeout: درخواست بیش از حد طول کشید. لطفا اتصال اینترنت خود را بررسی کنید.',
              );
            },
          );

      print('📥 Response status: ${response.statusCode}');
      final bodyPreview = response.body.length > 500
          ? '${response.body.substring(0, 500)}...'
          : response.body;
      print('📥 Response body: $bodyPreview');

      // Check for HTTP errors first (same pattern as getGalleryPosts)
      if (response.statusCode == 403) {
        return {
          'success': false,
          'message':
              'دسترسی غیرمجاز. لطفا مطمئن شوید که وارد حساب کاربری خود شده‌اید.',
          'statusCode': 403,
        };
      }

      if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'احراز هویت نامعتبر است. لطفا دوباره وارد شوید.',
          'statusCode': 401,
        };
      }

      if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'آدرس درخواستی یافت نشد.',
          'statusCode': 404,
        };
      }

      // Check if response body is empty
      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'پاسخ خالی از سرور دریافت شد',
          'statusCode': response.statusCode,
        };
      }

      // Check if response is HTML
      if (response.body.trim().startsWith('<html>') ||
          response.body.trim().startsWith('<!DOCTYPE')) {
        return {
          'success': false,
          'message': 'خطا در ارتباط با سرور',
          'statusCode': response.statusCode,
        };
      }

      // Try to parse JSON
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        print('❌ JSON Parse Error: $e');
        return {
          'success': false,
          'message': 'خطا در پردازش پاسخ سرور',
          'statusCode': response.statusCode,
          'rawResponse': response.body,
        };
      }

      // Check status code
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Parse surveys from response
        List<Survey> surveys = [];

        if (responseData['data'] != null && responseData['data'] is List) {
          final data = responseData['data'] as List;
          surveys = data
              .map((item) => Survey.fromJson(item as Map<String, dynamic>))
              .toList();
        }

        String message = 'نظرسنجی‌ها با موفقیت دریافت شد';
        if (responseData.containsKey('message')) {
          message = responseData['message'].toString();
        }

        return {'success': true, 'message': message, 'data': surveys};
      } else {
        // Handle different error response formats
        String errorMessage = 'خطا در دریافت نظرسنجی‌ها';
        if (responseData.containsKey('message')) {
          errorMessage = responseData['message'].toString();
        } else if (responseData.containsKey('error')) {
          errorMessage = responseData['error'].toString();
        } else if (responseData.containsKey('errors')) {
          final errors = responseData['errors'];
          if (errors is Map && errors.isNotEmpty) {
            errorMessage = errors.values.first.toString();
          } else if (errors is List && errors.isNotEmpty) {
            errorMessage = errors.first.toString();
          }
        }

        return {
          'success': false,
          'message': errorMessage,
          'errors': responseData['errors'],
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Exception in _getSurveysFromDomain ($domainUrl): $e');
      return {
        'success': false,
        'message': 'خطا در ارتباط با سرور. لطفا دوباره تلاش کنید.',
        'error': e.toString(),
      };
    } finally {
      client.close();
    }
  }

  // Submit survey answers
  static Future<Map<String, dynamic>> submitSurvey({
    required int surveyId,
    required String userId,
    required List<Map<String, dynamic>> answers,
  }) async {
    return _executeWithFallback((domainUrl) => _submitSurveyToDomain(domainUrl, surveyId, userId, answers));
  }
  
  // Helper method to submit survey to a specific domain
  static Future<Map<String, dynamic>> _submitSurveyToDomain(
    String domainUrl,
    int surveyId,
    String userId,
    List<Map<String, dynamic>> answers,
  ) async {
    // Use HTTP-specific client for HTTP connections
    final client = domainUrl.startsWith('http://')
        ? _createHttpClientForHttp()
        : _createHttpClient();
    try {
      final payload = {
        'survey_id': surveyId,
        'user_id': userId,
        'answers': answers,
      };

      print('📤 Submitting survey answers: $payload');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      if (domainUrl.startsWith('http://')) {
        headers['Connection'] = 'keep-alive';
        headers['User-Agent'] = 'PishgamanApp/1.0';
      }

      final response = await client
          .post(
            Uri.parse('$domainUrl/surveys/submit'),
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(
            requestTimeout,
            onTimeout: () {
              throw Exception(
                'Timeout: درخواست بیش از حد طول کشید. لطفا اتصال اینترنت خود را بررسی کنید.',
              );
            },
          );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      // Check if response body is empty
      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'پاسخ خالی از سرور دریافت شد',
          'statusCode': response.statusCode,
        };
      }

      // Check if response is HTML
      if (response.body.trim().startsWith('<html>') ||
          response.body.trim().startsWith('<!DOCTYPE')) {
        return {
          'success': false,
          'message': 'خطا در ارتباط با سرور',
          'statusCode': response.statusCode,
        };
      }

      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        print('❌ JSON Parse Error (submitSurvey): $e');
        return {
          'success': false,
          'message': 'خطا در پردازش پاسخ سرور',
          'statusCode': response.statusCode,
          'rawResponse': response.body,
        };
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message':
              responseData['message']?.toString() ??
              'پاسخ شما با موفقیت ثبت شد',
          'data': responseData['data'],
        };
      }

      return {
        'success': false,
        'message':
            responseData['message']?.toString() ??
            responseData['error']?.toString() ??
            'ثبت پاسخ با خطا مواجه شد',
        'errors': responseData['errors'],
        'statusCode': response.statusCode,
      };
    } catch (e) {
      print('❌ Exception in _submitSurveyToDomain ($domainUrl): $e');
      return {
        'success': false,
        'message': 'خطا در ارتباط با سرور. لطفا دوباره تلاش کنید.',
        'error': e.toString(),
      };
    } finally {
      client.close();
    }
  }

  // Get random profiles
  // Public endpoint - no authentication required
  static Future<Map<String, dynamic>> getRandomProfiles({
    int count = 10,
  }) async {
    return _executeWithFallback((domainUrl) => _getRandomProfilesFromDomain(domainUrl, count));
  }
  
  // Helper method to get random profiles from a specific domain
  static Future<Map<String, dynamic>> _getRandomProfilesFromDomain(
    String domainUrl,
    int count,
  ) async {
    final client = domainUrl.startsWith('http://')
        ? _createHttpClientForHttp()
        : _createHttpClient();
    try {
      final uri = Uri.parse('$domainUrl/profiles/random').replace(
        queryParameters: {'count': count.toString()},
      );

      print('📤 Fetching random profiles from: $uri');

      final headers = <String, String>{
        'Accept': 'application/json',
      };
      
      if (domainUrl.startsWith('http://')) {
        headers['Connection'] = 'keep-alive';
        headers['User-Agent'] = 'PishgamanApp/1.0';
      }

      final response = await client
          .get(uri, headers: headers)
          .timeout(
            requestTimeout,
            onTimeout: () {
              throw Exception(
                'Timeout: درخواست بیش از حد طول کشید. لطفا اتصال اینترنت خود را بررسی کنید.',
              );
            },
          );

      print('📥 Response status: ${response.statusCode}');
      final bodyPreview = response.body.length > 500
          ? '${response.body.substring(0, 500)}...'
          : response.body;
      print('📥 Response body: $bodyPreview');

      if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'پروفایلی یافت نشد.',
          'statusCode': 404,
        };
      }

      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'پاسخ خالی از سرور دریافت شد',
          'statusCode': response.statusCode,
        };
      }

      if (response.body.trim().startsWith('<html>') ||
          response.body.trim().startsWith('<!DOCTYPE')) {
        return {
          'success': false,
          'message': 'خطا در ارتباط با سرور',
          'statusCode': response.statusCode,
        };
      }

      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        print('❌ JSON Parse Error: $e');
        return {
          'success': false,
          'message': 'خطا در پردازش پاسخ سرور',
          'statusCode': response.statusCode,
          'rawResponse': response.body,
        };
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        List<Map<String, dynamic>> profilesWithUser = [];

        if (responseData['data'] != null && responseData['data'] is List) {
          final data = responseData['data'] as List;
          profilesWithUser = data.map((item) {
            final itemMap = item as Map<String, dynamic>;
            return {
              'profile': Profile.fromJson(itemMap),
              'user': itemMap['user'],
            };
          }).toList();
        }

        String message = 'پروفایل‌های تصادفی با موفقیت دریافت شدند';
        if (responseData.containsKey('message')) {
          message = responseData['message'].toString();
        }

        return {
          'success': true,
          'message': message,
          'data': profilesWithUser,
          'count': responseData['count'] ?? profilesWithUser.length,
        };
      } else {
        String errorMessage = 'خطا در دریافت پروفایل‌ها';
        if (responseData.containsKey('message')) {
          errorMessage = responseData['message'].toString();
        } else if (responseData.containsKey('error')) {
          errorMessage = responseData['error'].toString();
        }

        return {
          'success': false,
          'message': errorMessage,
          'errors': responseData['errors'],
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Exception in _getRandomProfilesFromDomain ($domainUrl): $e');
      return {
        'success': false,
        'message': 'خطا در ارتباط با سرور. لطفا دوباره تلاش کنید.',
        'error': e.toString(),
      };
    } finally {
      client.close();
    }
  }

  // Get domains list
  // Public endpoint - no authentication required
  static Future<Map<String, dynamic>> getDomains({
    int page = 1,
    int limit = 20,
    int isActive = 1,
  }) async {
    return _executeWithFallback((domainUrl) => _getDomainsFromDomain(domainUrl, page, limit, isActive));
  }
  
  // Helper method to get domains from a specific domain
  static Future<Map<String, dynamic>> _getDomainsFromDomain(
    String domainUrl,
    int page,
    int limit,
    int isActive,
  ) async {
    final client = domainUrl.startsWith('http://')
        ? _createHttpClientForHttp()
        : _createHttpClient();
    try {
      // Build URL with query parameters
      final uri = Uri.parse('$domainUrl/domains').replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          'is_active': isActive.toString(),
        },
      );

      print('📤 Fetching domains from: $uri');

      final headers = <String, String>{
        'Accept': 'application/json',
      };
      
      if (domainUrl.startsWith('http://')) {
        headers['Connection'] = 'keep-alive';
        headers['User-Agent'] = 'PishgamanApp/1.0';
      }

      final response = await client
          .get(uri, headers: headers)
          .timeout(
            requestTimeout,
            onTimeout: () {
              throw Exception(
                'Timeout: درخواست بیش از حد طول کشید. لطفا اتصال اینترنت خود را بررسی کنید.',
              );
            },
          );

      print('📥 Response status: ${response.statusCode}');
      final bodyPreview = response.body.length > 500
          ? '${response.body.substring(0, 500)}...'
          : response.body;
      print('📥 Response body: $bodyPreview');

      // Check for HTTP errors first
      if (response.statusCode == 403) {
        return {
          'success': false,
          'message':
              'دسترسی غیرمجاز. لطفا مطمئن شوید که وارد حساب کاربری خود شده‌اید.',
          'statusCode': 403,
        };
      }

      if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'احراز هویت نامعتبر است. لطفا دوباره وارد شوید.',
          'statusCode': 401,
        };
      }

      if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'آدرس درخواستی یافت نشد.',
          'statusCode': 404,
        };
      }

      // Check if response body is empty
      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'پاسخ خالی از سرور دریافت شد',
          'statusCode': response.statusCode,
        };
      }

      // Check if response is HTML
      if (response.body.trim().startsWith('<html>') ||
          response.body.trim().startsWith('<!DOCTYPE')) {
        return {
          'success': false,
          'message': 'خطا در ارتباط با سرور',
          'statusCode': response.statusCode,
        };
      }

      // Try to parse JSON
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        print('❌ JSON Parse Error: $e');
        return {
          'success': false,
          'message': 'خطا در پردازش پاسخ سرور',
          'statusCode': response.statusCode,
          'rawResponse': response.body,
        };
      }

      // Check status code
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Parse domains from response
        List<Domain> domains = [];

        if (responseData['data'] != null && responseData['data'] is Map) {
          final data = responseData['data'] as Map<String, dynamic>;
          if (data['domains'] != null && data['domains'] is List) {
            final domainsList = data['domains'] as List;
            domains = domainsList
                .map((item) => Domain.fromJson(item as Map<String, dynamic>))
                .toList();
          }
        } else if (responseData['data'] != null && responseData['data'] is List) {
          // Direct list response
          final domainsList = responseData['data'] as List;
          domains = domainsList
              .map((item) => Domain.fromJson(item as Map<String, dynamic>))
              .toList();
        }

        String message = 'حوزه‌ها با موفقیت دریافت شدند';
        if (responseData.containsKey('message')) {
          message = responseData['message'].toString();
        }

        // Get pagination info if available
        Map<String, dynamic>? pagination;
        if (responseData['data'] != null && responseData['data'] is Map) {
          final data = responseData['data'] as Map<String, dynamic>;
          if (data['pagination'] != null) {
            pagination = data['pagination'] as Map<String, dynamic>;
          }
        }

        return {
          'success': true,
          'message': message,
          'data': domains,
          'pagination': pagination,
        };
      } else {
        // Handle different error response formats
        String errorMessage = 'خطا در دریافت حوزه‌ها';
        if (responseData.containsKey('message')) {
          errorMessage = responseData['message'].toString();
        } else if (responseData.containsKey('error')) {
          errorMessage = responseData['error'].toString();
        } else if (responseData.containsKey('errors')) {
          final errors = responseData['errors'];
          if (errors is Map && errors.isNotEmpty) {
            errorMessage = errors.values.first.toString();
          } else if (errors is List && errors.isNotEmpty) {
            errorMessage = errors.first.toString();
          }
        }

        return {
          'success': false,
          'message': errorMessage,
          'errors': responseData['errors'],
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Exception in _getDomainsFromDomain ($domainUrl): $e');
      return {
        'success': false,
        'message': 'خطا در ارتباط با سرور. لطفا دوباره تلاش کنید.',
        'error': e.toString(),
      };
    } finally {
      client.close();
    }
  }
}
