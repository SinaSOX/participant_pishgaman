import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../components/snak_component.dart';
import '../intro/intro_page.dart';
import '../support/ai_support_page.dart';
import '../feedback/feedback_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  void _openFeedback() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const FeedbackPage()));
  }

  void _openAiSupport() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AiSupportPage()));
  }

  Future<void> _handleLogout() async {
    // نمایش دیالوگ تایید
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'خروج از حساب کاربری',
              style: TextStyle(
                fontFamily: 'Farhang',
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'آیا مطمئن هستید که می‌خواهید از حساب کاربری خود خارج شوید؟',
              style: TextStyle(fontFamily: 'Farhang'),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'انصراف',
                  style: TextStyle(
                    fontFamily: 'Farhang',
                    color: AppColors.grey,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'خروج',
                  style: TextStyle(fontFamily: 'Farhang'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (shouldLogout != true) return;

    try {
      final authService = AuthService();
      final success = await authService.logout();

      if (success && mounted) {
        // هدایت به صفحات اینترو
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const IntroPage()),
          (route) => false,
        );

        SnackComponent(
          context: context,
          type: SnackbarTypeColor.success,
          text: 'با موفقیت از حساب کاربری خارج شدید',
        );
      } else {
        if (mounted) {
          SnackComponent(
            context: context,
            type: SnackbarTypeColor.danger,
            text: 'خطا در خروج از حساب کاربری',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SnackComponent(
          context: context,
          type: SnackbarTypeColor.danger,
          text: 'خطا در خروج: ${e.toString()}',
        );
      }
    }
  }

  void _showAboutUs() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'درباره ما',
              style: TextStyle(
                fontFamily: 'Farhang',
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'پیشگامان رهایی',
                    style: TextStyle(
                      fontFamily: 'Farhang',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'اپلیکیشن پیشگامان رهایی، پلتفرمی جامع برای یادگیری و آموزش است. ما با ارائه محتوای آموزشی با کیفیت و تجربه کاربری عالی، به شما کمک می‌کنیم تا به بهترین شکل ممکن یاد بگیرید.',
                    style: TextStyle(fontFamily: 'Farhang', height: 1.8),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ویژگی‌های اصلی:',
                    style: TextStyle(
                      fontFamily: 'Farhang',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildFeatureItem('• دوره‌های آموزشی جامع'),
                  _buildFeatureItem('• گالری محتوا'),
                  _buildFeatureItem('• پروفایل کاربری'),
                  _buildFeatureItem('• مسیر یادگیری شخصی‌سازی شده'),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'نسخه: 1.0.0',
                    style: TextStyle(
                      fontFamily: 'Farhang',
                      color: AppColors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'بستن',
                  style: TextStyle(fontFamily: 'Farhang'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showHelpGuide() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'راهنما',
              style: TextStyle(
                fontFamily: 'Farhang',
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHelpSection(
                    'شروع کار',
                    'برای شروع، وارد حساب کاربری خود شوید. پس از ورود، می‌توانید به تمام بخش‌های اپلیکیشن دسترسی داشته باشید.',
                  ),
                  const SizedBox(height: 16),
                  _buildHelpSection(
                    'پروفایل',
                    'در بخش پروفایل می‌توانید اطلاعات شخصی خود را مشاهده و ویرایش کنید.',
                  ),
                  const SizedBox(height: 16),
                  _buildHelpSection(
                    'گالری',
                    'در بخش گالری می‌توانید به تمام محتواهای آموزشی دسترسی داشته باشید.',
                  ),
                  const SizedBox(height: 16),
                  _buildHelpSection(
                    'مسیر دوره',
                    'در این بخش می‌توانید مسیر یادگیری خود را مشاهده و دنبال کنید.',
                  ),
                  const SizedBox(height: 16),
                  _buildHelpSection(
                    'تنظیمات',
                    'در بخش تنظیمات می‌توانید تنظیمات اپلیکیشن را تغییر دهید و از حساب کاربری خود خارج شوید.',
                  ),
                ],
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'بستن',
                  style: TextStyle(fontFamily: 'Farhang'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFAQ() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'سوالات متداول',
              style: TextStyle(
                fontFamily: 'Farhang',
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFAQItem(
                    'چگونه وارد حساب کاربری شوم؟',
                    'برای ورود به حساب کاربری، شماره تلفن همراه خود را وارد کنید و کد تایید ارسال شده را وارد نمایید.',
                  ),
                  const SizedBox(height: 16),
                  _buildFAQItem(
                    'چگونه رمز عبور خود را تغییر دهم؟',
                    'در حال حاضر امکان تغییر رمز عبور از طریق اپلیکیشن وجود ندارد. لطفاً با پشتیبانی تماس بگیرید.',
                  ),
                  const SizedBox(height: 16),
                  _buildFAQItem(
                    'چگونه می‌توانم محتواهای آموزشی را مشاهده کنم؟',
                    'برای مشاهده محتواهای آموزشی، به بخش گالری مراجعه کنید و محتوای مورد نظر خود را انتخاب کنید.',
                  ),
                  const SizedBox(height: 16),
                  _buildFAQItem(
                    'آیا می‌توانم دوره‌ها را دانلود کنم؟',
                    'بله، برخی از دوره‌ها قابلیت دانلود دارند. این قابلیت در آینده به تمام دوره‌ها اضافه خواهد شد.',
                  ),
                  const SizedBox(height: 16),
                  _buildFAQItem(
                    'چگونه با پشتیبانی تماس بگیرم؟',
                    'برای تماس با پشتیبانی، می‌توانید از طریق ایمیل یا شماره تلفن پشتیبانی با ما در ارتباط باشید.',
                  ),
                ],
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'بستن',
                  style: TextStyle(fontFamily: 'Farhang'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontFamily: 'Farhang', height: 1.6),
      ),
    );
  }

  Widget _buildHelpSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Farhang',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(fontFamily: 'Farhang', height: 1.8),
        ),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(
            fontFamily: 'Farhang',
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          answer,
          style: const TextStyle(
            fontFamily: 'Farhang',
            height: 1.8,
            color: AppColors.grey,
          ),
        ),
        const Divider(height: 24),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
    bool isDanger = false,
  }) {
    final itemColor = isDanger ? Colors.red : (iconColor ?? AppColors.primary);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: itemColor.withOpacity(0.12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: itemColor.withOpacity(0.12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: itemColor,
                size: 32,
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Farhang',
                    color: itemColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'تنظیمات',
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
              colors: [Colors.white, Colors.grey.shade50],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // بخش اطلاعات و راهنما
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'اطلاعات و راهنما',
                    style: TextStyle(
                      fontFamily: 'Farhang',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey,
                    ),
                  ),
                ),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0,
                  children: [
                    _buildSettingsItem(
                      icon: FontAwesomeIcons.comments,
                      title: 'پشتیبانی',
                      onTap: _openAiSupport,
                      iconColor: AppColors.primary,
                    ),
                    _buildSettingsItem(
                      icon: FontAwesomeIcons.penToSquare,
                      title: 'پیشنهاد و انتقاد',
                      onTap: _openFeedback,
                      iconColor: AppColors.primary,
                    ),
                    _buildSettingsItem(
                      icon: FontAwesomeIcons.circleInfo,
                      title: 'درباره ما',
                      onTap: _showAboutUs,
                      iconColor: AppColors.primary,
                    ),
                    _buildSettingsItem(
                      icon: FontAwesomeIcons.book,
                      title: 'راهنما',
                      onTap: _showHelpGuide,
                      iconColor: AppColors.primary,
                    ),
                    _buildSettingsItem(
                      icon: FontAwesomeIcons.circleQuestion,
                      title: 'سوالات متداول',
                      onTap: _showFAQ,
                      iconColor: AppColors.primary,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // بخش حساب کاربری
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'حساب کاربری',
                    style: TextStyle(
                      fontFamily: 'Farhang',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey,
                    ),
                  ),
                ),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0,
                  children: [
                    _buildSettingsItem(
                      icon: FontAwesomeIcons.rightFromBracket,
                      title: 'خروج از حساب',
                      onTap: _handleLogout,
                      iconColor: Colors.red,
                      textColor: Colors.red,
                      isDanger: true,
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // اطلاعات نسخه
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'نسخه 1.0.0',
                          style: TextStyle(
                            fontFamily: 'Farhang',
                            fontSize: 12,
                            color: AppColors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'پیشگامان رهایی',
                          style: TextStyle(
                            fontFamily: 'Farhang',
                            fontSize: 12,
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
