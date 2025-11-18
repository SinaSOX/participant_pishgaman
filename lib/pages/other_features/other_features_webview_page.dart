import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';

class OtherFeaturesWebViewPage extends StatefulWidget {
  const OtherFeaturesWebViewPage({super.key});

  @override
  State<OtherFeaturesWebViewPage> createState() =>
      _OtherFeaturesWebViewPageState();
}

class _OtherFeaturesWebViewPageState extends State<OtherFeaturesWebViewPage> {
  final AuthService _authService = AuthService();
  WebViewController? _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.init();
      final identifier =
          _authService.getUserId() ?? _authService.getPhone() ?? 'unknown';

      final uri = Uri(
        scheme: 'https',
        host: 'pishgaman.s79.ir',
        path: '/backup',
        queryParameters: {
          'user': identifier,
        },
      );

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (mounted) {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
              }
            },
            onPageFinished: (_) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            onWebResourceError: (error) {
              if (mounted) {
                setState(() {
                  _errorMessage = error.description;
                  _isLoading = false;
                });
              }
            },
          ),
        )
        ..loadRequest(uri);

      if (mounted) {
        setState(() {
          _controller = controller;
          _isLoading = true;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'خطا در بارگذاری صفحه: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _reload() async {
    if (_controller != null) {
      await _controller!.reload();
    } else {
      await _initializeWebView();
    }
  }

  Future<bool> _handleWillPop() async {
    if (_controller != null && await _controller!.canGoBack()) {
      await _controller!.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (!didPop) {
            final shouldPop = await _handleWillPop();
            if (shouldPop && context.mounted) {
              Navigator.of(context).pop();
            }
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('سایر امکانات'),
            actions: [
              IconButton(
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
                tooltip: 'بارگذاری مجدد',
              ),
            ],
          ),
          body: Stack(
            children: [
              if (_controller != null)
                WebViewWidget(
                  controller: _controller!,
                ),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              if (_errorMessage != null && !_isLoading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontFamily: 'Farhang',
                            fontSize: 16,
                            color: AppColors.darkGray,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _reload,
                          child: const Text('تلاش مجدد'),
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

}

