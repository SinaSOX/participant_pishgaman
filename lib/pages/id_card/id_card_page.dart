import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

class IdCardPage extends StatefulWidget {
  const IdCardPage({super.key});

  @override
  State<IdCardPage> createState() => _IdCardPageState();
}

class _IdCardPageState extends State<IdCardPage> {
  final AuthService _authService = AuthService();
  final ScreenshotController _screenshotController = ScreenshotController();
  String? _fullName;
  String? _province;
  String? _nationalId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // First try to get from AuthService (data saved after login)
      _fullName = _authService.getFullName();
      _province = _authService.getProvince();
      _nationalId = _authService.getNationalId();

      // If data is missing, try to get from API
      if (_fullName == null || _fullName!.isEmpty ||
          _province == null || _province!.isEmpty) {
        final response = await ApiService.getProfile();
        if (response['success'] == true && response['data'] != null) {
          final userData = response['data'];
          if (userData is Map) {
            // Try to get from user object in profile
            final user = userData['user'];
            if (user is Map) {
              _fullName = user['full_name']?.toString() ?? _fullName;
              _province = user['province']?.toString() ?? _province;
              _nationalId = user['national_id']?.toString() ?? _nationalId;
            }
            // Also check direct fields
            _fullName = userData['full_name']?.toString() ?? _fullName;
            _province = userData['province']?.toString() ?? _province;
            _nationalId = userData['national_id']?.toString() ?? _nationalId;
          }
        }
      }
    } catch (e) {
      print('⚠️ Error loading user data: $e');
      // Continue with whatever data we have from AuthService
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName = _fullName ?? 'نام و نام خانوادگی';
    final province = _province ?? 'استان';
    final nationalId = _nationalId ?? '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'کارت شناسایی',
            style: TextStyle(
              fontFamily: 'Farhang',
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          elevation: 0,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                AppColors.primary.withOpacity(0.05),
              ],
            ),
          ),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Center(
                      child: Screenshot(
                        controller: _screenshotController,
                        child: _buildIdCard(
                          fullName: fullName,
                          province: province,
                          nationalId: nationalId,
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildIdCard({
    required String fullName,
    required String province,
    required String nationalId,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
            AppColors.secondaryColor,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              // Decorative background pattern
              Positioned.fill(
                child: CustomPaint(
                  painter: _IdCardPatternPainter(),
                ),
              ),
              // Main content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    // Header with icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Title
                    const Text(
                      'کارت شناسایی',
                      style: TextStyle(
                        fontFamily: 'Farhang',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Name and last name section
                    _buildInfoRow(
                      label: 'نام و نام خانوادگی',
                      value: fullName,
                    ),
                    const SizedBox(height: 18),
                    // Province section
                    _buildInfoRow(
                      label: 'استان',
                      value: province,
                    ),
                    const SizedBox(height: 28),
                    // QR Code section
                    if (nationalId.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: nationalId,
                          version: QrVersions.auto,
                          size: 140,
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          errorCorrectionLevel: QrErrorCorrectLevel.H,
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.qr_code_scanner,
                              size: 60,
                              color: Colors.white70,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'کد ملی ثبت نشده است',
                              style: TextStyle(
                                fontFamily: 'Farhang',
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    // Footer decoration
                    Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Screenshot hint text
                    Text(
                      'برای ذخیره، اسکرین‌شات بگیرید',
                      style: TextStyle(
                        fontFamily: 'Farhang',
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.8),
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Farhang',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Farhang',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for decorative pattern
class _IdCardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Draw circles pattern
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 3; j++) {
        final x = (size.width / 4) * (i + 1);
        final y = (size.height / 4) * (j + 1);
        canvas.drawCircle(
          Offset(x, y),
          30,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

