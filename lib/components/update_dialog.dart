import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../services/update_service.dart';

class UpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
  });

  @override
  Widget build(BuildContext context) {
    final isForceUpdate = updateInfo.force;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope(
        canPop: !isForceUpdate, // Prevent closing if force update
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.system_update,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  isForceUpdate ? 'به‌روزرسانی حیاتی' : 'به‌روزرسانی در دسترس',
                  style: const TextStyle(
                    fontFamily: 'Farhang',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Message
                Text(
                  updateInfo.message ??
                      (isForceUpdate
                          ? 'نسخه جدیدی از اپلیکیشن در دسترس است. برای ادامه استفاده، لطفاً اپلیکیشن را به‌روزرسانی کنید.'
                          : 'نسخه جدیدی از اپلیکیشن در دسترس است. آیا می‌خواهید اپلیکیشن را به‌روزرسانی کنید؟'),
                  style: const TextStyle(
                    fontFamily: 'Farhang',
                    fontSize: 14,
                    color: AppColors.darkGray,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Version info
                if (updateInfo.version.isNotEmpty)
                  Text(
                    'نسخه جدید: ${updateInfo.version}',
                    style: const TextStyle(
                      fontFamily: 'Farhang',
                      fontSize: 12,
                      color: AppColors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    // Cancel button (only if not force update)
                    if (!isForceUpdate)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(
                              color: AppColors.grey,
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'بعداً',
                            style: TextStyle(
                              fontFamily: 'Farhang',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey,
                            ),
                          ),
                        ),
                      ),
                    if (!isForceUpdate) const SizedBox(width: 12),

                    // Update button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _openUpdateUrl(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'به‌روزرسانی',
                          style: TextStyle(
                            fontFamily: 'Farhang',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openUpdateUrl(BuildContext context) async {
    final url = updateInfo.updateUrl;
    if (url == null || url.isEmpty) {
      // Show error if no URL provided
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'لینک به‌روزرسانی یافت نشد',
              style: TextStyle(fontFamily: 'Farhang'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // Open in browser
        );
        // If force update, close the app or show message
        if (updateInfo.force && context.mounted) {
          // For force updates, we can't close the app programmatically
          // The user will need to update from the browser
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'نمی‌توان لینک را باز کرد: $url',
                style: const TextStyle(fontFamily: 'Farhang'),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error opening update URL: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در باز کردن لینک: $e',
              style: const TextStyle(fontFamily: 'Farhang'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

