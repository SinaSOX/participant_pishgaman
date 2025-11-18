import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:participant_pishgaman/components/button_conponent.dart';
import 'package:participant_pishgaman/components/snak_component.dart';
import 'package:participant_pishgaman/constants/app_colors.dart';
import 'package:participant_pishgaman/main.dart';
import 'package:participant_pishgaman/pages/login/login_entry_page.dart';
import 'package:participant_pishgaman/services/api_service.dart';
import 'package:participant_pishgaman/services/auth_service.dart';
import 'package:pinput/pinput.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math';

class Sing_upEntryPage extends StatefulWidget {
  final String phoneNumber;

  const Sing_upEntryPage({super.key, required this.phoneNumber});

  @override
  _Sing_upEntryPage createState() => _Sing_upEntryPage();
}

class _Sing_upEntryPage extends State<Sing_upEntryPage>
    with CodeAutoFill, TickerProviderStateMixin {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  Timer? _timer;
  int _remainingSeconds = 120; // 2 minutes
  bool _canResend = false;
  bool _isVerifying = false; // Prevent multiple verification calls
  late AnimationController _animationController;
  Timer? _randomPlayTimer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _startTimer();

    // Initialize animation controller
    // Animation duration is approximately 2 seconds (61 frames / 30 fps from the JSON file)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Play animation initially for 1-2 seconds
    _playInitialAnimation();

    // Start random playback after initial animation
    _startRandomPlayback();

    // Initialize SMS autofill
    // SMS Retriever API works without permission on Android 13+
    // For older versions, it will try to use SMS autofill
    _initSmsAutofill();

    // Auto focus pin field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pinFocusNode.requestFocus();
    });
  }

  void _playInitialAnimation() {
    // Play for 1-2 seconds (random between 1 and 2)
    final initialDuration = 1 + _random.nextDouble(); // 1.0 to 2.0 seconds

    _animationController.reset();
    _animationController.forward();

    // Stop the animation after 1-2 seconds and keep it at current position
    Future.delayed(
      Duration(milliseconds: (initialDuration * 1000).toInt()),
      () {
        if (mounted) {
          _animationController.stop();
          // Keep animation at current position instead of resetting
          // This prevents the animation from disappearing
        }
      },
    );
  }

  void _startRandomPlayback() {
    // Wait for initial animation to finish (2 seconds max)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _scheduleNextRandomPlay();
      }
    });
  }

  void _scheduleNextRandomPlay() {
    // Random delay between 3, 4, or 5 seconds
    final delays = [3, 4, 5];
    final delay = delays[_random.nextInt(delays.length)];

    _randomPlayTimer?.cancel();
    _randomPlayTimer = Timer(Duration(seconds: delay), () {
      if (mounted) {
        _playAnimationOnce();
        _scheduleNextRandomPlay();
      }
    });
  }

  void _playAnimationOnce() {
    // Play the full animation once
    _animationController.reset();
    _animationController.forward().then((_) {
      if (mounted) {
        // Keep animation at the end instead of resetting
        // This prevents the animation from disappearing when it finishes
        _animationController.value = 1.0;
      }
    });
  }

  @override
  void codeUpdated() {
    if (code != null && code!.length == 6 && mounted) {
      _pinController.text = code!;
      _verifyCode();
    }
  }

  Future<void> _initSmsAutofill() async {
    try {
      // Start listening for SMS codes
      // SMS Retriever API (Android 13+) works without permission
      // For older Android versions, it may require READ_SMS permission
      listenForCode();

      // Get app signature for SMS Retriever API (Android)
      if (Platform.isAndroid) {
        try {
          final signature = await SmsAutoFill().getAppSignature;
          print('App signature: $signature');
          // Note: For SMS Retriever API to work, your SMS should include:
          // Format: <#> Your code is: 123456 ABC123XYZ
          // Where ABC123XYZ is your app signature (11 characters)
          // The SMS must start with <#> and end with the signature
        } catch (e) {
          print('Could not get app signature: $e');
          // Continue anyway, SMS autofill may still work
        }
      }
    } catch (e) {
      print('Error initializing SMS autofill: $e');
      // Don't show error to user, SMS autofill is optional
      // User can still manually enter the code
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _randomPlayTimer?.cancel();
    _animationController.dispose();
    _pinController.dispose();
    _pinFocusNode.dispose();
    cancel();
    super.dispose();
  }

  void _startTimer() {
    _remainingSeconds = 120;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        _timer?.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _onCodeChanged(String value) {
    // Don't auto-submit if already verifying
    // onCompleted will handle the verification
    // This prevents double submission
  }

  Future<void> _verifyCode() async {
    // Prevent multiple simultaneous verification calls
    if (_isVerifying) {
      return;
    }

    String code = _pinController.text.trim();
    
    if (code.length != 6) {
      SnackComponent(
        context: context,
        type: SnackbarTypeColor.danger,
        text: 'لطفا کد تأیید 6 رقمی را کامل وارد کنید',
      );
      return;
    }

    // Set verifying flag
    _isVerifying = true;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'در حال تأیید کد...',
                style: TextStyle(
                  fontFamily: 'Farhang',
                  fontSize: 14,
                  color: AppColors.darkGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final result = await ApiService.verifyOtp(widget.phoneNumber, code);

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (result['success'] == true) {
        // Save all authentication data using AuthService
        final authService = AuthService();
        await authService.init();
        
        final saved = await authService.saveAuthData(result);
        
        if (saved) {
          print('✅ Auth data saved successfully');
          print('📱 Phone: ${authService.getPhone()}');
          print('👤 Role: ${authService.getRole()}');
          print('🔑 Token: ${authService.getToken()?.substring(0, 20)}...');
        } else {
          print('❌ Failed to save auth data');
        }

        // Navigate to home page
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => MyHomePage(title: 'شرکت کننده پیشگامان'),
            ),
          );
        }
      } else {
        // Show error message
        if (mounted) {
          SnackComponent(
            context: context,
            type: SnackbarTypeColor.danger,
            text: result['message'] ?? 'کد تأیید نامعتبر است',
          );
        }
        // Reset verifying flag on error so user can try again
        _isVerifying = false;
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
        SnackComponent(
          context: context,
          type: SnackbarTypeColor.danger,
          text: 'خطا در ارتباط با سرور. لطفا دوباره تلاش کنید.',
        );
      }
      // Reset verifying flag on error
      _isVerifying = false;
    }
  }

  Future<void> _resendCode() async {
    if (!_canResend) {
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'در حال ارسال مجدد کد...',
                style: TextStyle(
                  fontFamily: 'Farhang',
                  fontSize: 14,
                  color: AppColors.darkGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final result = await ApiService.sendOtp(widget.phoneNumber);

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (result['success'] == true) {
        _startTimer();
        _pinController.clear();

        if (mounted) {
          SnackComponent(
            context: context,
            type: SnackbarTypeColor.success,
            text: result['message'] ?? 'کد تأیید مجدداً ارسال شد',
          );
        }
      } else {
        if (mounted) {
          SnackComponent(
            context: context,
            type: SnackbarTypeColor.danger,
            text: result['message'] ?? 'خطا در ارسال مجدد کد تأیید',
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
        SnackComponent(
          context: context,
          type: SnackbarTypeColor.danger,
          text: 'خطا در ارتباط با سرور. لطفا دوباره تلاش کنید.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    Colors.white,
                    Colors.white,
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
            ),

            // Decorative circles
            Positioned(
              top: -100,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              top: 150,
              left: -80,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.lightTurquoise.withOpacity(0.15),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 40),

                            // Back button
                            Align(
                              alignment: Alignment.topRight,
                              child: IconButton(
                                icon: Icon(
                                  Icons.arrow_back,
                                  color: AppColors.darkGray,
                                  size: 28,
                                ),
                                onPressed: () =>
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) => LoginEntryPage(),
                                      ),
                                    ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Lottie Animation
                            Center(
                              child: SizedBox(
                                width: 200,
                                height: 200,
                                child: Lottie.asset(
                                  'assets/animations/otp_page.json',
                                  controller: _animationController,
                                  fit: BoxFit.contain,
                                  repeat: false,
                                  animate: false,
                                ),
                              ),
                            ),

                            const SizedBox(height: 50),

                            // Title
                            const Text(
                              'کد تأیید را وارد کنید',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 32,
                                color: AppColors.darkGray,
                                fontFamily: 'Farhang',
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 16),

                            // Subtitle
                            Text(
                              'کد 6 رقمی ارسال شده به شماره ${widget.phoneNumber} را وارد کنید',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.grey,
                                fontFamily: 'Farhang',
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 50),

                            // OTP Input Field (LTR direction for code input)
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Pinput(
                                length: 6,
                                controller: _pinController,
                                focusNode: _pinFocusNode,
                                defaultPinTheme: PinTheme(
                                  width: 50,
                                  height: 60,
                                  textStyle: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkGray,
                                    fontFamily: 'Farhang',
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.grey.withOpacity(0.3),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                focusedPinTheme: PinTheme(
                                  width: 50,
                                  height: 60,
                                  textStyle: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkGray,
                                    fontFamily: 'Farhang',
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(
                                          0.2,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                ),
                                submittedPinTheme: PinTheme(
                                  width: 50,
                                  height: 60,
                                  textStyle: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkGray,
                                    fontFamily: 'Farhang',
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(
                                          0.2,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                ),
                                errorPinTheme: PinTheme(
                                  width: 50,
                                  height: 60,
                                  textStyle: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkGray,
                                    fontFamily: 'Farhang',
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.red,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                pinputAutovalidateMode:
                                    PinputAutovalidateMode.onSubmit,
                                showCursor: true,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onCompleted: (pin) {
                                  _verifyCode();
                                },
                                onChanged: (value) {
                                  _onCodeChanged(value);
                                },
                              ),
                            ),

                            const SizedBox(height: 40),

                            // Timer and Resend Code
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (!_canResend) ...[
                                  Icon(
                                    Icons.access_time,
                                    size: 18,
                                    color: AppColors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ارسال مجدد کد تا ${_formatTime(_remainingSeconds)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.grey,
                                      fontFamily: 'Farhang',
                                    ),
                                  ),
                                ] else ...[
                                  TextButton(
                                    onPressed: _resendCode,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.refresh,
                                          size: 18,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'ارسال مجدد کد',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Farhang',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            SizedBox(
                              height:
                                  MediaQuery.of(context).viewInsets.bottom + 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Verify Button at bottom
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      bottom: 24,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ButtonComponent(
                        width: size.width - 48,
                        color: AppColors.primary,
                        borderRadius: 25,
                        onPressed: _verifyCode,
                        child: const Text(
                          "تأیید و ورود",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Farhang',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
