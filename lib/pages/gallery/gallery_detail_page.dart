import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/app_colors.dart';
import '../../models/gallery_post.dart';

class GalleryDetailPage extends StatefulWidget {
  final GalleryPost post;

  const GalleryDetailPage({super.key, required this.post});

  @override
  State<GalleryDetailPage> createState() => _GalleryDetailPageState();
}

class _GalleryDetailPageState extends State<GalleryDetailPage> {
  bool _isDownloading = false;
  bool _isSharing = false;

  // Create HTTP client with relaxed SSL validation for image downloads
  // This is needed for servers with outdated SSL/TLS configurations
  static http.Client _createImageHttpClient() {
    final httpClient = HttpClient();
    // Allow bad certificates for image downloads (only for specific problematic domains)
    httpClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
          // Only allow for known problematic domains
          final hostLower = host.toLowerCase();
          if (hostLower.contains('sinaseifouri.ir')) {
            print(
              '⚠️ Allowing SSL connection to $host (outdated SSL configuration)',
            );
            return true;
          }
          return false;
        };
    return IOClient(httpClient);
  }

  Future<void> _downloadImage() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      // Request storage permission
      if (Platform.isAndroid) {
        // For Android 13+ (API 33+), use photos permission
        // For Android 10-12, use storage permission
        PermissionStatus status;

        try {
          // Try photos permission first (for Android 13+)
          status = await Permission.photos.request();
          if (!status.isGranted) {
            // Fallback to storage permission (for Android < 13)
            status = await Permission.storage.request();
          }
        } catch (e) {
          print('⚠️ Permission error: $e');
          // If photos permission is not available, use storage
          try {
            status = await Permission.storage.request();
          } catch (e2) {
            print('❌ Storage permission error: $e2');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'خطا در درخواست دسترسی. لطفاً از تنظیمات دسترسی دهید.',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
            setState(() {
              _isDownloading = false;
            });
            return;
          }
        }

        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('برای دانلود تصویر، دسترسی به حافظه لازم است'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() {
            _isDownloading = false;
          });
          return;
        }
      } else if (Platform.isIOS) {
        // Request photos permission for iOS
        try {
          final status = await Permission.photos.request();
          if (!status.isGranted) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('برای دانلود تصویر، دسترسی به گالری لازم است'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            setState(() {
              _isDownloading = false;
            });
            return;
          }
        } catch (e) {
          print('❌ iOS Permission error: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'خطا در درخواست دسترسی. لطفاً از تنظیمات دسترسی دهید.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() {
            _isDownloading = false;
          });
          return;
        }
      }

      // Download image using custom HTTP client that handles SSL issues
      final imageClient = _createImageHttpClient();
      http.Response response;
      try {
        response = await imageClient.get(Uri.parse(widget.post.imageUrl));
      } finally {
        imageClient.close();
      }
      if (response.statusCode == 200) {
        // Get directory for saving
        Directory? directory;
        try {
          if (Platform.isAndroid) {
            // Try to get external storage directory
            try {
              directory = await getExternalStorageDirectory();
              // Navigate to Downloads folder if possible
              if (directory != null) {
                final downloadsPath =
                    '${directory.path.split('/Android')[0]}/Download';
                final downloadsDir = Directory(downloadsPath);
                if (await downloadsDir.exists()) {
                  directory = downloadsDir;
                }
              }
            } catch (e) {
              print('⚠️ External storage error: $e');
              // Fallback to application documents directory
              directory = await getApplicationDocumentsDirectory();
            }
          } else {
            directory = await getApplicationDocumentsDirectory();
          }
        } catch (e) {
          print('❌ Directory error: $e');
          throw Exception('خطا در دسترسی به پوشه ذخیره‌سازی');
        }

        if (directory != null) {
          // Create images folder if it doesn't exist
          final imagesDir = Directory('${directory.path}/PishgamanImages');
          if (!await imagesDir.exists()) {
            await imagesDir.create(recursive: true);
          }

          // Save image
          final fileName =
              '${widget.post.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final file = File('${imagesDir.path}/$fileName');
          await file.writeAsBytes(response.bodyBytes);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('تصویر با موفقیت دانلود شد'),
                backgroundColor: AppColors.primary,
                action: SnackBarAction(
                  label: 'بستن',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          }
        } else {
          throw Exception('نمی‌توان پوشه ذخیره‌سازی را پیدا کرد');
        }
      } else {
        throw Exception('خطا در دانلود تصویر: کد وضعیت ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در دانلود: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      print('❌ Download error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  Future<void> _shareImage() async {
    setState(() {
      _isSharing = true;
    });

    try {
      // Download image temporarily for sharing using custom HTTP client
      final imageClient = _createImageHttpClient();
      http.Response response;
      try {
        response = await imageClient.get(Uri.parse(widget.post.imageUrl));
      } finally {
        imageClient.close();
      }
      if (response.statusCode == 200) {
        // Get temporary directory
        Directory tempDir;
        try {
          tempDir = await getTemporaryDirectory();
        } catch (e) {
          print('❌ Temp directory error: $e');
          throw Exception('خطا در دسترسی به پوشه موقت');
        }

        final fileName =
            'share_${widget.post.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        // Verify file exists before sharing
        if (!await file.exists()) {
          throw Exception('فایل برای اشتراک آماده نشد');
        }

        // Share the image
        try {
          await Share.shareXFiles(
            [XFile(file.path)],
            text: widget.post.description ?? widget.post.title,
            subject: widget.post.title,
          );
        } catch (e) {
          print('❌ Share plugin error: $e');
          // Fallback to text sharing if file sharing fails
          await Share.share(
            widget.post.description ?? widget.post.title,
            subject: widget.post.title,
          );
        }
      } else {
        throw Exception(
          'خطا در آماده‌سازی تصویر برای اشتراک: کد وضعیت ${response.statusCode}',
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'خطا در اشتراک';
        if (e.toString().contains('MissingPluginException')) {
          errorMessage =
              'پلاگین اشتراک‌گذاری یافت نشد. لطفاً برنامه را دوباره نصب کنید.';
        } else {
          errorMessage = 'خطا در اشتراک: ${e.toString()}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      print('❌ Share error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Full screen image
              Expanded(
                child: Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: CachedNetworkImage(
                      imageUrl: widget.post.imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: 64,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Description section
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      widget.post.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGray,
                        fontFamily: 'Farhang',
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Description
                    if (widget.post.description != null &&
                        widget.post.description!.isNotEmpty)
                      Text(
                        widget.post.description!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.darkGray,
                          fontFamily: 'Farhang',
                          height: 1.6,
                        ),
                      ),
                    const SizedBox(height: 24),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isDownloading ? null : _downloadImage,
                            icon: _isDownloading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.download),
                            label: const Text(
                              'دانلود',
                              style: TextStyle(
                                fontFamily: 'Farhang',
                                fontSize: 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isSharing ? null : _shareImage,
                            icon: _isSharing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : const Icon(FontAwesomeIcons.shareNodes),
                            label: const Text(
                              'اشتراک',
                              style: TextStyle(
                                fontFamily: 'Farhang',
                                fontSize: 16,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
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
}
