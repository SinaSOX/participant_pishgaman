import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/profile.dart';
import '../../components/snak_component.dart';
import 'create_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Profile? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getProfile();

      if (response['success'] == true) {
        final data = response['data'];
        if (data is Profile) {
          setState(() {
            _profile = data;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'فرمت داده پروفایل نامعتبر است';
            _isLoading = false;
          });
        }
      } else {
        final statusCode = response['statusCode'];
        setState(() {
          _errorMessage = response['message'] ?? 'خطا در دریافت پروفایل';
          _isLoading = false;
        });

        // If 404, navigate to create profile page
        if (statusCode == 404 && mounted) {
          _navigateToCreateProfile();
          return;
        }

        if (mounted) {
          SnackComponent(
            context: context,
            type: SnackbarTypeColor.danger,
            text: _errorMessage!,
          );
        }
      }
    } catch (e) {
      print('❌ Error loading profile: $e');
      setState(() {
        _errorMessage = 'خطا در ارتباط با سرور: ${e.toString()}';
        _isLoading = false;
      });
      if (mounted) {
        SnackComponent(
          context: context,
          type: SnackbarTypeColor.danger,
          text: _errorMessage!,
        );
      }
    }
  }

  Future<void> _navigateToCreateProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateProfilePage()),
    );

    // If profile was created successfully, reload the profile
    if (result == true && mounted) {
      _loadProfile();
    }
  }

  // Helper method to launch URL
  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          SnackComponent(
            context: context,
            type: SnackbarTypeColor.danger,
            text: 'نمی‌توان این لینک را باز کرد',
          );
        }
      }
    } catch (e) {
      print('❌ Error launching URL: $e');
      if (mounted) {
        SnackComponent(
          context: context,
          type: SnackbarTypeColor.danger,
          text: 'خطا در باز کردن لینک',
        );
      }
    }
  }

  // Helper method to launch email
  Future<void> _launchEmail(String email) async {
    try {
      final uri = Uri.parse('mailto:$email');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          SnackComponent(
            context: context,
            type: SnackbarTypeColor.danger,
            text: 'نمی‌توان ایمیل را باز کرد',
          );
        }
      }
    } catch (e) {
      print('❌ Error launching email: $e');
      if (mounted) {
        SnackComponent(
          context: context,
          type: SnackbarTypeColor.danger,
          text: 'خطا در باز کردن ایمیل',
        );
      }
    }
  }

  // Helper method to get user initial
  String _getUserInitial() {
    final authService = AuthService();
    final fullName = authService.getFullName();
    if (fullName != null && fullName.isNotEmpty) {
      // Get first character, handling Persian/Arabic text
      final trimmed = fullName.trim();
      if (trimmed.isNotEmpty) {
        return trimmed[0].toUpperCase();
      }
    }
    return '?';
  }

  // Helper method to launch phone
  Future<void> _launchPhone(String phone) async {
    try {
      // Remove any non-digit characters except +
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
      final uri = Uri.parse('tel:$cleanPhone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          SnackComponent(
            context: context,
            type: SnackbarTypeColor.danger,
            text: 'نمی‌توان شماره تماس را باز کرد',
          );
        }
      }
    } catch (e) {
      print('❌ Error launching phone: $e');
      if (mounted) {
        SnackComponent(
          context: context,
          type: SnackbarTypeColor.danger,
          text: 'خطا در باز کردن شماره تماس',
        );
      }
    }
  }

  // Helper method to get social media URL from username/value
  String? _getSocialMediaUrl(String platform, String value) {
    final lowerPlatform = platform.toLowerCase();
    final cleanValue = value.toString().trim();

    // If it's already a URL, return it
    if (cleanValue.startsWith('http://') || cleanValue.startsWith('https://')) {
      return cleanValue;
    }

    // Remove @ if present
    final username = cleanValue.startsWith('@')
        ? cleanValue.substring(1)
        : cleanValue;

    switch (lowerPlatform) {
      case 'instagram':
      case 'insta':
        return 'https://instagram.com/$username';
      case 'telegram':
      case 'tg':
        return username.startsWith('@')
            ? 'https://t.me/$username'
            : 'https://t.me/$username';
      case 'linkedin':
        return 'https://linkedin.com/in/$username';
      case 'twitter':
      case 'x':
        return 'https://twitter.com/$username';
      case 'github':
        return 'https://github.com/$username';
      case 'whatsapp':
        // WhatsApp uses phone number format
        final phone = cleanValue.replaceAll(RegExp(r'[^\d+]'), '');
        return 'https://wa.me/$phone';
      case 'eitaa':
      case 'ایتا':
        return 'https://eitaa.com/$username';
      case 'soroush':
      case 'سروش':
        return 'https://splus.ir/$username';
      case 'bale':
      case 'بله':
        return 'https://ble.ir/$username';
      case 'rubika':
      case 'روبیکا':
        return 'https://rubika.ir/$username';
      case 'gap':
      case 'گپ':
        return 'https://gap.im/$username';
      case 'igap':
      case 'آی‌گپ':
        return 'https://igap.net/$username';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'پروفایل',
            style: TextStyle(
              fontFamily: 'Farhang',
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadProfile,
              tooltip: 'بروزرسانی',
            ),
            if (_profile != null)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _navigateToCreateProfile(),
                tooltip: 'ویرایش پروفایل',
              ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null && _profile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'تلاش مجدد',
                style: TextStyle(fontFamily: 'Farhang', fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }

    if (_profile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'پروفایلی یافت نشد',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontFamily: 'Farhang',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProfile,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(),
            const SizedBox(height: 16),
            // Profile Content
            _buildProfileContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Profile Image
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _getUserInitial(),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Farhang',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // User Name
              Text(
                AuthService().getFullName() ?? 'کاربر',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Farhang',
                ),
              ),
              const SizedBox(height: 12),
              // Public/Private Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _profile!.isPublic ? Icons.public : Icons.lock,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _profile!.isPublic ? 'عمومی' : 'خصوصی',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Farhang',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to count information boxes
  int _countInformationBoxes() {
    int count = 0;
    if (_profile!.aboutMe != null && _profile!.aboutMe!.isNotEmpty) count++;
    if (_profile!.skills != null && _profile!.skills!.isNotEmpty) count++;
    if (_profile!.educationalCredentials != null &&
        _profile!.educationalCredentials!.isNotEmpty) count++;
    if (_profile!.workExperience != null &&
        _profile!.workExperience!.isNotEmpty) count++;
    if (_profile!.completedProjects != null &&
        _profile!.completedProjects!.isNotEmpty) count++;
    if (_profile!.certifications != null &&
        _profile!.certifications!.isNotEmpty) count++;
    if (_profile!.socialNetworks != null &&
        _profile!.socialNetworks!.isNotEmpty) count++;
    if (_profile!.contactInfo != null &&
        _profile!.contactInfo!.isNotEmpty) count++;
    return count;
  }

  Widget _buildProfileContent() {
    final informationBoxCount = _countInformationBoxes();
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About Me
          if (_profile!.aboutMe != null && _profile!.aboutMe!.isNotEmpty)
            _buildSection(
              title: 'درباره من',
              icon: Icons.info_outline,
              child: _buildAboutMe(),
            ),

          // Skills
          if (_profile!.skills != null && _profile!.skills!.isNotEmpty)
            _buildSection(
              title: 'مهارت‌ها',
              icon: Icons.star_outline,
              child: _buildSkills(),
            ),

          // Educational Credentials
          if (_profile!.educationalCredentials != null &&
              _profile!.educationalCredentials!.isNotEmpty)
            _buildSection(
              title: 'مدارک تحصیلی',
              icon: Icons.school_outlined,
              child: _buildEducationalCredentials(),
            ),

          // Work Experience
          if (_profile!.workExperience != null &&
              _profile!.workExperience!.isNotEmpty)
            _buildSection(
              title: 'سوابق کاری',
              icon: Icons.work_outline,
              child: _buildWorkExperience(),
            ),

          // Completed Projects
          if (_profile!.completedProjects != null &&
              _profile!.completedProjects!.isNotEmpty)
            _buildSection(
              title: 'پروژه‌های انجام شده',
              icon: Icons.folder_outlined,
              child: _buildCompletedProjects(),
            ),

          // Certifications
          if (_profile!.certifications != null &&
              _profile!.certifications!.isNotEmpty)
            _buildSection(
              title: 'گواهینامه‌ها',
              icon: Icons.verified_outlined,
              child: _buildCertifications(),
            ),

          // Social Networks
          if (_profile!.socialNetworks != null &&
              _profile!.socialNetworks!.isNotEmpty)
            _buildSection(
              title: 'شبکه‌های اجتماعی',
              icon: Icons.share_outlined,
              child: _buildSocialNetworks(),
            ),

          // Contact Info
          if (_profile!.contactInfo != null &&
              _profile!.contactInfo!.isNotEmpty)
            _buildSection(
              title: 'اطلاعات تماس',
              icon: Icons.contact_phone_outlined,
              child: _buildContactInfo(),
            ),

          // Show message if less than 2 information boxes
          if (informationBoxCount < 2)
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'برای تکمیل پروفایل خود، اطلاعات بیشتری اضافه کنید. برای این کار روی دکمه قلم در بالا سمت چپ صفحه کلیک کنید.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontFamily: 'Farhang',
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontFamily: 'Farhang',
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.primary),
          Padding(padding: const EdgeInsets.all(16.0), child: child),
        ],
      ),
    );
  }

  Widget _buildAboutMe() {
    return Text(
      _profile!.aboutMe!,
      style: const TextStyle(
        fontSize: 15,
        color: AppColors.primary,
        fontFamily: 'Farhang',
        height: 1.6,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildSkills() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _profile!.skills!.map((skill) {
        String skillText = '';
        if (skill is String) {
          skillText = skill;
        } else if (skill is Map) {
          skillText = skill['name']?.toString() ?? skill.toString();
        } else {
          skillText = skill.toString();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            skillText,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.primary,
              fontFamily: 'Farhang',
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEducationalCredentials() {
    return Column(
      children: _profile!.educationalCredentials!.asMap().entries.map((entry) {
        final index = entry.key;
        final credential = entry.value;

        String title = '';
        String? description;

        if (credential is Map) {
          title =
              credential['title']?.toString() ??
              credential['degree']?.toString() ??
              credential['name']?.toString() ??
              'مدرک تحصیلی';
          description =
              credential['description']?.toString() ??
              credential['university']?.toString() ??
              credential['year']?.toString();
        } else if (credential is String) {
          title = credential;
        } else {
          title = credential.toString();
        }

        return Container(
          margin: EdgeInsets.only(
            bottom: index < _profile!.educationalCredentials!.length - 1
                ? 12
                : 0,
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.school, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGray,
                        fontFamily: 'Farhang',
                      ),
                    ),
                  ),
                ],
              ),
              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary.withOpacity(0.8),
                    fontFamily: 'Farhang',
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWorkExperience() {
    return Column(
      children: _profile!.workExperience!.asMap().entries.map((entry) {
        final index = entry.key;
        final experience = entry.value;

        String title = '';
        String? company;
        String? description;
        String? period;

        if (experience is Map) {
          title =
              experience['title']?.toString() ??
              experience['position']?.toString() ??
              experience['job_title']?.toString() ??
              'سابقه کاری';
          company =
              experience['company']?.toString() ??
              experience['organization']?.toString();
          description = experience['description']?.toString();
          period =
              experience['period']?.toString() ??
              experience['duration']?.toString() ??
              (experience['start_date'] != null &&
                      experience['end_date'] != null
                  ? '${experience['start_date']} - ${experience['end_date']}'
                  : null);
        } else if (experience is String) {
          title = experience;
        } else {
          title = experience.toString();
        }

        return Container(
          margin: EdgeInsets.only(
            bottom: index < _profile!.workExperience!.length - 1 ? 12 : 0,
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.business, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGray,
                        fontFamily: 'Farhang',
                      ),
                    ),
                  ),
                ],
              ),
              if (company != null && company.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  company,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontFamily: 'Farhang',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              if (period != null && period.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  period,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary.withOpacity(0.7),
                    fontFamily: 'Farhang',
                  ),
                ),
              ],
              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary.withOpacity(0.8),
                    fontFamily: 'Farhang',
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompletedProjects() {
    return Column(
      children: _profile!.completedProjects!.asMap().entries.map((entry) {
        final index = entry.key;
        final project = entry.value;

        String title = '';
        String? description;

        if (project is Map) {
          title =
              project['title']?.toString() ??
              project['name']?.toString() ??
              'پروژه';
          description = project['description']?.toString();
        } else if (project is String) {
          title = project;
        } else {
          title = project.toString();
        }

        return Container(
          margin: EdgeInsets.only(
            bottom: index < _profile!.completedProjects!.length - 1 ? 12 : 0,
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.folder, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGray,
                        fontFamily: 'Farhang',
                      ),
                    ),
                  ),
                ],
              ),
              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary.withOpacity(0.8),
                    fontFamily: 'Farhang',
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCertifications() {
    return Column(
      children: _profile!.certifications!.asMap().entries.map((entry) {
        final index = entry.key;
        final certification = entry.value;

        String title = '';
        String? issuer;
        String? date;

        if (certification is Map) {
          title =
              certification['title']?.toString() ??
              certification['name']?.toString() ??
              'گواهینامه';
          issuer =
              certification['issuer']?.toString() ??
              certification['organization']?.toString();
          date =
              certification['date']?.toString() ??
              certification['issued_date']?.toString();
        } else if (certification is String) {
          title = certification;
        } else {
          title = certification.toString();
        }

        return Container(
          margin: EdgeInsets.only(
            bottom: index < _profile!.certifications!.length - 1 ? 12 : 0,
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.verified, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGray,
                        fontFamily: 'Farhang',
                      ),
                    ),
                  ),
                ],
              ),
              if (issuer != null && issuer.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  issuer,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary.withOpacity(0.8),
                    fontFamily: 'Farhang',
                  ),
                ),
              ],
              if (date != null && date.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary.withOpacity(0.7),
                    fontFamily: 'Farhang',
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSocialNetworks() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _profile!.socialNetworks!.entries.map((entry) {
        final platform = entry.key;
        final value = entry.value;

        IconData icon;
        Color color;

        switch (platform.toLowerCase()) {
          case 'instagram':
          case 'insta':
            icon = FontAwesomeIcons.instagram;
            color = const Color(0xFFE4405F);
            break;
          case 'telegram':
          case 'tg':
            icon = FontAwesomeIcons.telegram;
            color = const Color(0xFF0088CC);
            break;
          case 'linkedin':
            icon = FontAwesomeIcons.linkedin;
            color = const Color(0xFF0077B5);
            break;
          case 'twitter':
          case 'x':
            icon = FontAwesomeIcons.twitter;
            color = const Color(0xFF1DA1F2);
            break;
          case 'github':
            icon = FontAwesomeIcons.github;
            color = const Color(0xFF181717);
            break;
          case 'whatsapp':
            icon = FontAwesomeIcons.whatsapp;
            color = const Color(0xFF25D366);
            break;
          case 'eitaa':
          case 'ایتا':
            icon = Icons.chat_bubble_outline;
            color = const Color(0xFF00A859);
            break;
          case 'soroush':
          case 'سروش':
            icon = Icons.chat_bubble_outline;
            color = const Color(0xFF6C5CE7);
            break;
          case 'bale':
          case 'بله':
            icon = Icons.chat_bubble_outline;
            color = const Color(0xFF00BCD4);
            break;
          case 'rubika':
          case 'روبیکا':
            icon = Icons.chat_bubble_outline;
            color = const Color(0xFFFF6B6B);
            break;
          case 'gap':
          case 'گپ':
            icon = Icons.chat_bubble_outline;
            color = const Color(0xFF4ECDC4);
            break;
          case 'igap':
          case 'آی‌گپ':
            icon = Icons.chat_bubble_outline;
            color = const Color(0xFF95A5A6);
            break;
          default:
            icon = Icons.link;
            color = AppColors.primary;
        }

        final url = _getSocialMediaUrl(platform, value.toString());

        return GestureDetector(
          onTap: () {
            if (url != null) {
              _launchUrl(url);
            } else {
              if (mounted) {
                SnackComponent(
                  context: context,
                  type: SnackbarTypeColor.danger,
                  text: 'لینک معتبری برای $platform یافت نشد',
                );
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  platform,
                  style: TextStyle(
                    fontSize: 14,
                    color: color,
                    fontFamily: 'Farhang',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContactInfo() {
    return Column(
      children: _profile!.contactInfo!.entries.map((entry) {
        final key = entry.key;
        final value = entry.value;

        IconData icon;
        switch (key.toLowerCase()) {
          case 'email':
          case 'ایمیل':
            icon = Icons.email_outlined;
            break;
          case 'phone':
          case 'mobile':
          case 'تلفن':
          case 'موبایل':
            icon = Icons.phone_outlined;
            break;
          case 'address':
          case 'آدرس':
            icon = Icons.location_on_outlined;
            break;
          case 'website':
          case 'وب‌سایت':
            icon = Icons.language;
            break;
          default:
            icon = Icons.info_outline;
        }

        final valueStr = value.toString().trim();
        
        // Check if value is a URL
        bool isUrl = valueStr.startsWith('http://') || 
                     valueStr.startsWith('https://') ||
                     valueStr.startsWith('www.') ||
                     (valueStr.contains('.') && 
                      (valueStr.contains('.com') || 
                       valueStr.contains('.ir') || 
                       valueStr.contains('.net') || 
                       valueStr.contains('.org')));
        
        // Check if value is an email
        bool isEmail = valueStr.contains('@') && valueStr.contains('.');
        
        // Check if value is a phone number
        bool isPhone = RegExp(r'^[\d\s\+\-\(\)]+$').hasMatch(valueStr) && 
                       valueStr.replaceAll(RegExp(r'[^\d]'), '').length >= 7;

        final isClickable = 
            key.toLowerCase() == 'email' ||
            key.toLowerCase() == 'ایمیل' ||
            key.toLowerCase() == 'phone' ||
            key.toLowerCase() == 'mobile' ||
            key.toLowerCase() == 'تلفن' ||
            key.toLowerCase() == 'موبایل' ||
            key.toLowerCase() == 'website' ||
            key.toLowerCase() == 'وب‌سایت' ||
            isUrl ||
            (key.toLowerCase() == 'address' && isUrl) ||
            (key.toLowerCase() == 'آدرس' && isUrl);

        return GestureDetector(
          onTap: isClickable
              ? () {
                  if (key.toLowerCase() == 'email' ||
                      key.toLowerCase() == 'ایمیل' ||
                      isEmail) {
                    _launchEmail(valueStr);
                  } else if (key.toLowerCase() == 'phone' ||
                      key.toLowerCase() == 'mobile' ||
                      key.toLowerCase() == 'تلفن' ||
                      key.toLowerCase() == 'موبایل' ||
                      isPhone) {
                    _launchPhone(valueStr);
                  } else if (key.toLowerCase() == 'website' ||
                      key.toLowerCase() == 'وب‌سایت' ||
                      isUrl ||
                      (key.toLowerCase() == 'address' && isUrl) ||
                      (key.toLowerCase() == 'آدرس' && isUrl)) {
                    String url = valueStr.trim();
                    // Preserve the original protocol (http:// or https://)
                    // Only add protocol if none is provided
                    if (!url.startsWith('http://') &&
                        !url.startsWith('https://')) {
                      // Default to http:// instead of https:// to avoid automatic redirects
                      url = 'http://$url';
                    }
                    _launchUrl(url);
                  }
                }
              : null,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        key,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary.withOpacity(0.7),
                          fontFamily: 'Farhang',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value.toString(),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontFamily: 'Farhang',
                          decoration: isClickable
                              ? TextDecoration.underline
                              : TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isClickable)
                  Icon(
                    Icons.open_in_new,
                    size: 16,
                    color: AppColors.primary.withOpacity(0.6),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
