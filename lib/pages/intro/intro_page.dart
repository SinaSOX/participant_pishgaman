import 'package:flutter/material.dart';
import 'package:lava_lamp_effect/lava_lamp_effect.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../services/onboarding_service.dart';
import '../login/login_entry_page.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final OnboardingService _onboardingService = OnboardingService();

  final List<IntroScreen> _introScreens = [
    IntroScreen(
      title: AppStrings.introTitle1,
      subtitle: AppStrings.introSubtitle1,
      imagePath: 'assets/images/intro1.png',
      backgroundColor: const Color(0xFF2C2C2C),
    ),
    IntroScreen(
      title: AppStrings.introTitle2,
      subtitle: AppStrings.introSubtitle2,
      imagePath: 'assets/images/intro2.png',
      backgroundColor: const Color(0xFF2C2C2C),
    ),
    IntroScreen(
      title: AppStrings.introTitle3,
      subtitle: AppStrings.introSubtitle3,
      imagePath: 'assets/images/intro3.jpg',
      backgroundColor: const Color(0xFF2C2C2C),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              reverse: false,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _introScreens.length,
              itemBuilder: (context, index) {
                return _buildIntroScreen(_introScreens[index]);
              },
            ),
            // Skip button
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: TextButton(
                onPressed: () {
                  _navigateToNextPage();
                },
                child: Text(
                  AppStrings.skip,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Farhang',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroScreen(IntroScreen screen) {
    return Container(
      color: screen.backgroundColor,
      child: Stack(
        children: [
          // Background image - positioned to cover top 2/3 of screen starting from very top
          Positioned(
            top: 30,
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).size.height * 0.35,
            child: Stack(
              children: [
                Image.asset(
                  screen.imagePath,
                  width: MediaQuery.of(context).size.width,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback if image doesn't exist
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            screen.backgroundColor,
                            screen.backgroundColor.withOpacity(0.8),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // Lava lamp effect - only on image area
                // Turquoise lava blobs with 80% opacity
                Opacity(
                  opacity: 0.8,
                  child: LavaLampEffect(
                    size: Size(
                      MediaQuery.of(context).size.width,
                      MediaQuery.of(context).size.height * 0.65,
                    ),
                    color: AppColors.primary,
                    lavaCount: 3,
                    speed: 1,
                    repeatDuration: const Duration(seconds: 6),
                  ),
                ),
                // White lava blobs with 80% opacity
                Opacity(
                  opacity: 0.8,
                  child: LavaLampEffect(
                    size: Size(
                      MediaQuery.of(context).size.width,
                      MediaQuery.of(context).size.height * 0.65,
                    ),
                    color: Colors.white,
                    lavaCount: 2,
                    speed: 1,
                    repeatDuration: const Duration(seconds: 8),
                  ),
                ),
                // Dark overlay with 58% opacity
                Container(color: const Color(0x00000000).withOpacity(0.58)),
              ],
            ),
          ),
          // Turquoise overlay card - positioned to cover bottom 1/3 of screen
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.35,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    Text(
                      screen.title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Farhang',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    // Subtitle
                    Text(
                      screen.subtitle,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontFamily: 'Farhang',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    // Page indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _introScreens.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 12 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? Colors.white
                                : Colors.white54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Start button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentPage < _introScreens.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _navigateToNextPage();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _currentPage < _introScreens.length - 1
                              ? AppStrings.next
                              : AppStrings.startButton,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Farhang',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToNextPage() async {
    // Mark intro as completed
    await _onboardingService.setIntroCompleted();

    // Navigate to login page
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginEntryPage()),
      );
    }
  }
}

class IntroScreen {
  final String title;
  final String subtitle;
  final String imagePath;
  final Color backgroundColor;

  IntroScreen({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.backgroundColor,
  });
}
