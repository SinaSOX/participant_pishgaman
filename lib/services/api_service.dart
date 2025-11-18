import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../models/gallery_post.dart';
import '../models/profile.dart';
import '../services/auth_service.dart';

class ApiService {
  // Base URL from the documentation
  static const String baseUrl = 'https://pishgaman.s79.ir/api';

  // Request timeout duration (90 seconds = 1.5 minutes)
  static const Duration requestTimeout = Duration(seconds: 90);

  // Create HTTP client with proper SSL configuration
  static http.Client _createHttpClient() {
    final httpClient = HttpClient();
    // Use default certificate validation
    // If you have SSL issues, you may need to configure this differently
    return IOClient(httpClient);
  }

  // Send OTP code
  static Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    final client = _createHttpClient();
    try {
      print('📤 Sending OTP request to: $baseUrl/auth/send-otp');
      print('📱 Phone number: $phoneNumber');

      final response = await client
          .post(
            Uri.parse('$baseUrl/auth/send-otp'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
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
      print('❌ Exception in sendOtp: $e');
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
    final client = _createHttpClient();
    try {
      print('📤 Verifying OTP request to: $baseUrl/auth/verify-otp');
      print('📱 Phone number: $phoneNumber');
      print('🔐 OTP code: $otpCode');

      final response = await client
          .post(
            Uri.parse('$baseUrl/auth/verify-otp'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
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
      print('❌ Exception in verifyOtp: $e');
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
    final client = _createHttpClient();
    try {
      // Build URL with query parameters
      final uri = Uri.parse('$baseUrl/gallery/list').replace(
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );

      print('📤 Fetching gallery posts from: $uri');

      final headers = {'Accept': 'application/json'};

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
      print('❌ Exception in getGalleryPosts: $e');
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
    final client = _createHttpClient();
    try {
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

      print('📤 Fetching profile from: $baseUrl/profiles/$userId');

      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await client
          .get(Uri.parse('$baseUrl/profiles/$userId'), headers: headers)
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
    final client = _createHttpClient();
    try {
      print('📤 Fetching profile from: $baseUrl/profiles/$userId');

      final headers = {'Accept': 'application/json'};

      final response = await client
          .get(Uri.parse('$baseUrl/profiles/$userId'), headers: headers)
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
    final client = _createHttpClient();
    try {
      final authService = AuthService();
      final token = authService.getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'لطفا ابتدا وارد حساب کاربری خود شوید.',
        };
      }

      print('📤 Updating profile for user: $userId');
      print('📤 Profile data: $profileData');

      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await client
          .put(
            Uri.parse('$baseUrl/profiles/$userId'),
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
}
