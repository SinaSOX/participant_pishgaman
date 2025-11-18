import 'storage_service.dart';
import '../constants/app_constants.dart';

class OnboardingService {
  static final OnboardingService _instance = OnboardingService._internal();
  factory OnboardingService() => _instance;
  OnboardingService._internal();

  final StorageService _storageService = StorageService();

  // Initialize service
  Future<void> init() async {
    try {
      await _storageService.init();
    } catch (e) {
      // Re-throw with more context
      throw Exception('Failed to initialize OnboardingService: $e');
    }
  }

  // Intro completion
  Future<bool> setIntroCompleted() async {
    return await _storageService.setBool(AppConstants.introCompletedKey, true);
  }

  bool isIntroCompleted() {
    return _storageService.getBool(AppConstants.introCompletedKey) ?? false;
  }
}
