import 'dart:convert';
import 'package:participant_pishgaman/constants/app_constants.dart';
import 'package:participant_pishgaman/services/storage_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final StorageService _storageService = StorageService();

  // Initialize service
  Future<void> init() async {
    await _storageService.ensureInitialized();
  }

  // Convert Persian digits to English digits
  String _convertPersianToEnglishDigits(String input) {
    const Map<String, String> persianToEnglish = {
      '۰': '0',
      '۱': '1',
      '۲': '2',
      '۳': '3',
      '۴': '4',
      '۵': '5',
      '۶': '6',
      '۷': '7',
      '۸': '8',
      '۹': '9',
    };

    String result = input;
    persianToEnglish.forEach((persian, english) {
      result = result.replaceAll(persian, english);
    });
    return result;
  }

  // Save authentication data
  Future<bool> saveAuthData(Map<String, dynamic> responseData) async {
    try {
      await _storageService.ensureInitialized();

      // Extract data from response
      final data = responseData['data'] is Map<String, dynamic>
          ? responseData['data'] as Map<String, dynamic>
          : responseData;

      // Extract user data
      Map<String, dynamic> user = {};
      if (data['user'] is Map<String, dynamic>) {
        user = data['user'] as Map<String, dynamic>;
      } else if (data['user'] != null) {
        // If user is not a Map, try to convert it
        try {
          user = Map<String, dynamic>.from(data['user'] as Map);
        } catch (e) {
          print('⚠️ Could not parse user data: $e');
        }
      }

      // Save token
      if (data['token'] != null) {
        await _storageService.setString(
          AppConstants.authTokenKey,
          data['token'].toString(),
        );
        print('✅ Token saved');
      }

      // Save phone number
      if (user['phone'] != null) {
        await _storageService.setString(
          AppConstants.authPhoneKey,
          user['phone'].toString(),
        );
        print('✅ Phone saved: ${user['phone']}');
      }

      // Save user ID (check user object first, then data)
      String? userId;
      if (user.isNotEmpty && user.containsKey('id') && user['id'] != null) {
        userId = user['id'].toString();
        print('📋 Found user ID in user object: $userId');
      } else if (user.isNotEmpty &&
          user.containsKey('user_id') &&
          user['user_id'] != null) {
        userId = user['user_id'].toString();
        print('📋 Found user ID in user object (user_id): $userId');
      } else if (data.containsKey('id') && data['id'] != null) {
        userId = data['id'].toString();
        print('📋 Found user ID in data object: $userId');
      } else if (data.containsKey('user_id') && data['user_id'] != null) {
        userId = data['user_id'].toString();
        print('📋 Found user ID in data object (user_id): $userId');
      }

      if (userId != null) {
        await _storageService.setString(AppConstants.authUserIdKey, userId);
        print('✅ User ID saved: $userId');
      } else {
        print('⚠️ User ID not found in response data');
        print('📋 User object: $user');
        print('📋 Data object keys: ${data.keys.toList()}');
      }

      // Save role (check data first, then user)
      String? role;
      if (data['role'] != null) {
        role = data['role'].toString();
      } else if (user['role'] != null) {
        role = user['role'].toString();
      }

      if (role != null) {
        await _storageService.setString(AppConstants.authRoleKey, role);
        print('✅ Role saved: $role');
      }

      // Save expires_at
      if (data['expires_at'] != null) {
        await _storageService.setString(
          AppConstants.authExpiresAtKey,
          data['expires_at'].toString(),
        );
        print('✅ Expires at saved: ${data['expires_at']}');
      }

      // Save all user fields individually
      if (user.isNotEmpty) {
        // Save full_name
        if (user['full_name'] != null) {
          await _storageService.setString(
            AppConstants.userFullNameKey,
            user['full_name'].toString(),
          );
        }

        // Save email
        if (user['email'] != null) {
          await _storageService.setString(
            AppConstants.userEmailKey,
            user['email'].toString(),
          );
        }

        // Save province
        if (user['province'] != null) {
          await _storageService.setString(
            AppConstants.userProvinceKey,
            user['province'].toString(),
          );
        }

        // Save city
        if (user['city'] != null) {
          await _storageService.setString(
            AppConstants.userCityKey,
            user['city'].toString(),
          );
        }

        // Save national_id (convert Persian digits to English)
        if (user['national_id'] != null) {
          final nationalId = _convertPersianToEnglishDigits(
            user['national_id'].toString(),
          );
          await _storageService.setString(
            AppConstants.userNationalIdKey,
            nationalId,
          );
          print('✅ National ID saved: $nationalId');
        }

        // Save address
        if (user['address'] != null) {
          await _storageService.setString(
            AppConstants.userAddressKey,
            user['address'].toString(),
          );
        }

        // Save postal_code
        if (user['postal_code'] != null) {
          await _storageService.setString(
            AppConstants.userPostalCodeKey,
            user['postal_code'].toString(),
          );
        }

        // Save hoze
        if (user['hoze'] != null) {
          await _storageService.setString(
            AppConstants.userHozeKey,
            user['hoze'].toString(),
          );
          print('✅ Hoze saved: ${user['hoze']}');
        }

        // Save gender
        if (user['gender'] != null) {
          await _storageService.setString(
            AppConstants.userGenderKey,
            user['gender'].toString(),
          );
        }

        // Save educational_level
        if (user['educational_level'] != null) {
          await _storageService.setString(
            AppConstants.userEducationalLevelKey,
            user['educational_level'].toString(),
          );
        }

        // Save status
        if (user['status'] != null) {
          await _storageService.setString(
            AppConstants.userStatusKey,
            user['status'].toString(),
          );
        }

        // Save is_active
        if (user['is_active'] != null) {
          await _storageService.setString(
            AppConstants.userIsActiveKey,
            user['is_active'].toString(),
          );
        }

        // Save last_login_at
        if (user['last_login_at'] != null) {
          await _storageService.setString(
            AppConstants.userLastLoginAtKey,
            user['last_login_at'].toString(),
          );
        }

        // Save created_at
        if (user['created_at'] != null) {
          await _storageService.setString(
            AppConstants.userCreatedAtKey,
            user['created_at'].toString(),
          );
        }

        // Save complete user data as JSON (for backward compatibility)
        await _storageService.setString(
          AppConstants.userDataKey,
          jsonEncode(user),
        );
        print('✅ All user data saved');
      }

      // Save complete response data as JSON (for complete backup)
      await _storageService.setString(
        AppConstants.authCompleteResponseKey,
        jsonEncode(responseData),
      );
      print('✅ Complete response data saved');

      // Mark as logged in
      await _storageService.setBool(AppConstants.isLoggedInKey, true);
      print('✅ User marked as logged in');

      return true;
    } catch (e) {
      print('❌ Error saving auth data: $e');
      print('❌ Response data: $responseData');
      return false;
    }
  }

  // Get stored token
  String? getToken() {
    return _storageService.getString(AppConstants.authTokenKey);
  }

  // Get stored phone
  String? getPhone() {
    return _storageService.getString(AppConstants.authPhoneKey);
  }

  // Get stored role
  String? getRole() {
    return _storageService.getString(AppConstants.authRoleKey);
  }

  // Get stored user ID
  String? getUserId() {
    return _storageService.getString(AppConstants.authUserIdKey);
  }

  // Get stored expires_at
  String? getExpiresAt() {
    return _storageService.getString(AppConstants.authExpiresAtKey);
  }

  // Get stored user data
  Map<String, dynamic>? getUserData() {
    final userDataString = _storageService.getString(AppConstants.userDataKey);
    if (userDataString != null) {
      try {
        return jsonDecode(userDataString) as Map<String, dynamic>;
      } catch (e) {
        print('❌ Error parsing user data: $e');
        return null;
      }
    }
    return null;
  }

  // Get complete stored response data
  Map<String, dynamic>? getCompleteResponseData() {
    final responseString = _storageService.getString(
      AppConstants.authCompleteResponseKey,
    );
    if (responseString != null) {
      try {
        return jsonDecode(responseString) as Map<String, dynamic>;
      } catch (e) {
        print('❌ Error parsing complete response data: $e');
        return null;
      }
    }
    return null;
  }

  // Get stored user fields
  String? getFullName() =>
      _storageService.getString(AppConstants.userFullNameKey);
  String? getEmail() => _storageService.getString(AppConstants.userEmailKey);
  String? getProvince() =>
      _storageService.getString(AppConstants.userProvinceKey);
  String? getCity() => _storageService.getString(AppConstants.userCityKey);
  String? getNationalId() =>
      _storageService.getString(AppConstants.userNationalIdKey);
  String? getAddress() =>
      _storageService.getString(AppConstants.userAddressKey);
  String? getPostalCode() =>
      _storageService.getString(AppConstants.userPostalCodeKey);
  String? getHoze() => _storageService.getString(AppConstants.userHozeKey);
  String? getGender() => _storageService.getString(AppConstants.userGenderKey);
  String? getEducationalLevel() =>
      _storageService.getString(AppConstants.userEducationalLevelKey);
  String? getStatus() => _storageService.getString(AppConstants.userStatusKey);
  String? getIsActive() =>
      _storageService.getString(AppConstants.userIsActiveKey);
  String? getLastLoginAt() =>
      _storageService.getString(AppConstants.userLastLoginAtKey);
  String? getCreatedAt() =>
      _storageService.getString(AppConstants.userCreatedAtKey);

  // Check if user is logged in
  bool isLoggedIn() {
    return _storageService.getBool(AppConstants.isLoggedInKey) ?? false;
  }

  // Logout - Clear all auth data
  Future<bool> logout() async {
    try {
      await _storageService.ensureInitialized();

      print('🗑️ Starting logout - clearing all auth data...');

      // Remove all auth-related keys
      await _storageService.remove(AppConstants.authTokenKey);
      await _storageService.remove(AppConstants.authPhoneKey);
      await _storageService.remove(AppConstants.authRoleKey);
      await _storageService.remove(AppConstants.authUserIdKey);
      await _storageService.remove(AppConstants.authExpiresAtKey);
      await _storageService.remove(AppConstants.userDataKey);
      await _storageService.remove(AppConstants.authCompleteResponseKey);
      print('✅ Auth keys removed');

      // Remove all user data keys
      await _storageService.remove(AppConstants.userFullNameKey);
      await _storageService.remove(AppConstants.userEmailKey);
      await _storageService.remove(AppConstants.userProvinceKey);
      await _storageService.remove(AppConstants.userCityKey);
      await _storageService.remove(AppConstants.userNationalIdKey);
      await _storageService.remove(AppConstants.userAddressKey);
      await _storageService.remove(AppConstants.userPostalCodeKey);
      await _storageService.remove(AppConstants.userHozeKey);
      await _storageService.remove(AppConstants.userGenderKey);
      await _storageService.remove(AppConstants.userEducationalLevelKey);
      await _storageService.remove(AppConstants.userStatusKey);
      await _storageService.remove(AppConstants.userIsActiveKey);
      await _storageService.remove(AppConstants.userLastLoginAtKey);
      await _storageService.remove(AppConstants.userCreatedAtKey);
      print('✅ User data keys removed');

      await _storageService.setBool(AppConstants.isLoggedInKey, false);
      print('✅ Logout completed - all data cleared');

      return true;
    } catch (e) {
      print('❌ Error during logout: $e');
      return false;
    }
  }

  // Get all auth info
  Map<String, dynamic>? getAuthInfo() {
    if (!isLoggedIn()) {
      return null;
    }

    return {
      'token': getToken(),
      'phone': getPhone(),
      'role': getRole(),
      'user_id': getUserId(),
      'expires_at': getExpiresAt(),
      'user': getUserData(),
      // Individual user fields
      'full_name': getFullName(),
      'email': getEmail(),
      'province': getProvince(),
      'city': getCity(),
      'national_id': getNationalId(),
      'address': getAddress(),
      'postal_code': getPostalCode(),
      'hoze': getHoze(),
      'gender': getGender(),
      'educational_level': getEducationalLevel(),
      'status': getStatus(),
      'is_active': getIsActive(),
      'last_login_at': getLastLoginAt(),
      'created_at': getCreatedAt(),
    };
  }
}
