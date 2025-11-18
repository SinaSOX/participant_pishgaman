import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:participant_pishgaman/components/button_conponent.dart';
import 'package:participant_pishgaman/components/snak_component.dart';
import 'package:participant_pishgaman/pages/sing_up/sing_up.dart';
import 'package:participant_pishgaman/constants/app_colors.dart';
import 'package:participant_pishgaman/services/api_service.dart';

class LoginEntryPage extends StatefulWidget {
  const LoginEntryPage({super.key});

  @override
  _LoginEntryPageState createState() => _LoginEntryPageState();
}

class _LoginEntryPageState extends State<LoginEntryPage>
    with TickerProviderStateMixin {
  final myController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _animationController;
  Timer? _randomPlayTimer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    myController.addListener(() {
      setState(() {});
      // Auto submit when phone number is complete (11 digits)
      if (myController.text.length == 11) {
        // Small delay to ensure the last digit is registered
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && myController.text.length == 11) {
            _submitPhoneNumber();
          }
        });
      }
    });

    // Initialize animation controller
    // Animation duration is 4 seconds (240 frames / 60 fps from the JSON file)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // Play animation initially for 2-3 seconds
    _playInitialAnimation();

    // Start random playback after initial animation
    _startRandomPlayback();
  }

  void _playInitialAnimation() {
    // Play for 2-3 seconds (random between 2 and 3)
    final initialDuration = 2 + _random.nextDouble(); // 2.0 to 3.0 seconds

    _animationController.reset();
    _animationController.forward();

    // Stop the animation after 2-3 seconds
    Future.delayed(
      Duration(milliseconds: (initialDuration * 1000).toInt()),
      () {
        if (mounted) {
          _animationController.stop();
          _animationController.reset();
        }
      },
    );
  }

  void _startRandomPlayback() {
    // Wait for initial animation to finish (3 seconds max)
    Future.delayed(const Duration(seconds: 3), () {
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
        _animationController.reset();
      }
    });
  }

  @override
  void dispose() {
    _randomPlayTimer?.cancel();
    _animationController.dispose();
    _focusNode.dispose();
    myController.dispose();
    super.dispose();
  }

  Widget _buildStepText(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.darkGray,
              fontFamily: 'Farhang',
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitPhoneNumber() async {
    final phoneNumber = myController.text.trim();

    if (phoneNumber.length != 11) {
      SnackComponent(
        context: context,
        type: SnackbarTypeColor.danger,
        text: 'لطفا شماره موبایل را به صورت صحیح وارد کنید (11 رقم)',
      );
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
                'در حال ارسال کد تأیید...',
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
      final result = await ApiService.sendOtp(phoneNumber);

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (result['success'] == true) {
        // Navigate to OTP page with phone number
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => Sing_upEntryPage(phoneNumber: phoneNumber),
            ),
          );
        }
      } else {
        // Show error message
        if (mounted) {
          SnackComponent(
            context: context,
            type: SnackbarTypeColor.danger,
            text: result['message'] ?? 'خطا در ارسال کد تأیید',
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

  void _showLoginProcessBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'روند ورود',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGray,
                        fontFamily: 'Farhang',
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: AppColors.grey),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Process steps
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStepText('1. شماره موبایل خود را وارد کنید'),
                      const SizedBox(height: 12),
                      _buildStepText('2. کد تأیید برای شما ارسال می‌شود'),
                      const SizedBox(height: 12),
                      _buildStepText('3. کد دریافتی را وارد کنید'),
                      const SizedBox(height: 12),
                      _buildStepText(
                        '4. پس از تأیید، وارد حساب کاربری می‌شوید',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
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

                            // Lottie Animation
                            Center(
                              child: SizedBox(
                                width: 200,
                                height: 200,
                                child: Lottie.asset(
                                  'assets/animations/login.json',
                                  controller: _animationController,
                                  fit: BoxFit.contain,
                                  repeat: false,
                                  animate: false,
                                ),
                              ),
                            ),

                            const SizedBox(height: 50),

                            // Welcome Text with Info Icon
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'ورود به حساب کاربری',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 32,
                                    color: AppColors.darkGray,
                                    fontFamily: 'Farhang',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () =>
                                      _showLoginProcessBottomSheet(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.info_outline,
                                      color: AppColors.primary,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            Text(
                              'لطفا شماره موبایل خود را وارد کنید',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.grey,
                                fontFamily: 'Farhang',
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 50),

                            // Phone Number Input Card
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.phone,
                                        color: AppColors.primary,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextField(
                                        controller: myController,
                                        focusNode: _focusNode,
                                        keyboardType: TextInputType.phone,
                                        inputFormatters: [
                                          LengthLimitingTextInputFormatter(11),
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Farhang',
                                          color: AppColors.darkGray,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: '09123456789',
                                          hintStyle: TextStyle(
                                            color: AppColors.grey.withOpacity(
                                              0.5,
                                            ),
                                            fontFamily: 'Farhang',
                                          ),
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 16,
                                              ),
                                        ),
                                      ),
                                    ),
                                    if (myController.text.isNotEmpty)
                                      IconButton(
                                        icon: Icon(
                                          Icons.clear,
                                          color: AppColors.grey,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          myController.clear();
                                          setState(() {});
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Helper text
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: AppColors.grey.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'شماره موبایل باید 11 رقم باشد (مثال: 09123456789)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.grey.withOpacity(0.7),
                                        fontFamily: 'Farhang',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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

                  // Login Button at bottom
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
                        onPressed: _submitPhoneNumber,
                        child: const Text(
                          "ارسال کد تأیید",
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
