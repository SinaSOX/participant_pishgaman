import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../models/profile.dart';
import '../profile/public_profile_page.dart';

class NetworkingPage extends StatefulWidget {
  const NetworkingPage({super.key});

  @override
  State<NetworkingPage> createState() => _NetworkingPageState();
}

class _NetworkingPageState extends State<NetworkingPage> {
  List<Map<String, dynamic>> _profiles = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getRandomProfiles(count: 10);

      if (response['success'] == true) {
        final data = response['data'] as List<Map<String, dynamic>>?;
        if (data != null && data.isNotEmpty) {
          setState(() {
            _profiles = data;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'پروفایلی یافت نشد';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'خطا در دریافت پروفایل‌ها';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading profiles: $e');
      setState(() {
        _errorMessage = 'خطا در ارتباط با سرور: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Helper method to get user initial
  String _getUserInitial(String? fullName) {
    if (fullName != null && fullName.isNotEmpty) {
      final trimmed = fullName.trim();
      if (trimmed.isNotEmpty) {
        return trimmed[0].toUpperCase();
      }
    }
    return '?';
  }

  // Helper method to get user name from profile data
  String _getUserName(Map<String, dynamic> profileData) {
    if (profileData['user'] != null) {
      final user = profileData['user'] as Map<String, dynamic>?;
      return user?['full_name']?.toString() ?? 'کاربر';
    }
    return 'کاربر';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'دورهمی و شبکه سازی',
            style: TextStyle(
              fontFamily: 'Farhang',
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          elevation: 0,
        ),
        extendBodyBehindAppBar: false,
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/carpet.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
            // Description text at top
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'با سایر شرکت‌کنندگان دوره ارتباط برقرار کنید و شبکه حرفه‌ای خود را گسترش دهید',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.primary,
                      fontFamily: 'Farhang',
                      fontWeight: FontWeight.w600,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            // Avatars around the carpet
            if (!_isLoading && _profiles.isNotEmpty)
              _buildAvatarsAroundCarpet(),
            // Loading indicator
            if (_isLoading)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              ),
            // Error message
            if (_errorMessage != null && !_isLoading)
              Center(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.darkGray,
                          fontFamily: 'Farhang',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProfiles,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'تلاش مجدد',
                          style: TextStyle(fontFamily: 'Farhang'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarsAroundCarpet() {
    if (_profiles.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = MediaQuery.of(context).size;
        final safeArea = MediaQuery.of(context).padding;
        final appBarHeight = AppBar().preferredSize.height;
        
        // Calculate available height
        final availableHeight = screenSize.height - safeArea.top - safeArea.bottom - appBarHeight - 120; // 120 for description
        final startY = safeArea.top + appBarHeight + 100; // Start after description
        
        // Split profiles into left and right sides
        final leftSideProfiles = <Map<String, dynamic>>[];
        final rightSideProfiles = <Map<String, dynamic>>[];
        
        for (int i = 0; i < _profiles.length; i++) {
          if (i % 2 == 0) {
            leftSideProfiles.add(_profiles[i]);
          } else {
            rightSideProfiles.add(_profiles[i]);
          }
        }
        
        // Calculate spacing between avatars
        final maxProfilesPerSide = math.max(leftSideProfiles.length, rightSideProfiles.length);
        final spacing = availableHeight / (maxProfilesPerSide + 1);
        
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Left side avatars
            ...leftSideProfiles.asMap().entries.map((entry) {
              final index = entry.key;
              final profileData = entry.value;
              final profile = profileData['profile'] as Profile;
              final userName = _getUserName(profileData);
              
              return Positioned(
                left: 20,
                top: startY + (index + 1) * spacing - 40,
                child: _buildAvatarWidget(profile, userName),
              );
            }),
            // Right side avatars
            ...rightSideProfiles.asMap().entries.map((entry) {
              final index = entry.key;
              final profileData = entry.value;
              final profile = profileData['profile'] as Profile;
              final userName = _getUserName(profileData);
              
              return Positioned(
                right: 20,
                top: startY + (index + 1) * spacing - 40,
                child: _buildAvatarWidget(profile, userName),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildAvatarWidget(Profile profile, String userName) {
    return GestureDetector(
      onTap: () {
        // Navigate to public profile page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PublicProfilePage(
              userId: profile.userId,
              userName: userName,
            ),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildAvatarPlaceholder(userName),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              userName,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontFamily: 'Farhang',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String name) {
    return ClipOval(
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primary.withOpacity(0.7),
            ],
          ),
        ),
        child: Center(
          child: Text(
            _getUserInitial(name),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Farhang',
            ),
          ),
        ),
      ),
    );
  }
}
