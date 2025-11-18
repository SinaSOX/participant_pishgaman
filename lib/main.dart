import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:participant_pishgaman/pages/login/login_entry_page.dart';
import 'package:participant_pishgaman/pages/intro/intro_page.dart';
import 'package:participant_pishgaman/pages/profile/profile_page.dart';
import 'package:participant_pishgaman/pages/course_path/course_path_page.dart';
import 'package:participant_pishgaman/pages/gallery/gallery_page.dart';
import 'package:participant_pishgaman/pages/settings/settings_page.dart';
import 'package:participant_pishgaman/pages/id_card/id_card_page.dart';
import 'package:participant_pishgaman/services/onboarding_service.dart';
import 'package:participant_pishgaman/services/auth_service.dart';
import 'package:participant_pishgaman/constants/app_colors.dart';
import 'package:participant_pishgaman/components/custom_bottom_nav.dart';

void main() async {
  // Set up error handling to prevent debugger disconnection
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  // Handle async errors
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize services with error handling
      try {
        await OnboardingService().init();
        await AuthService().init();
      } catch (e) {
        // Log error but continue app initialization
        debugPrint('Error initializing services: $e');
      }

      runApp(const MyApp());
    },
    (error, stack) {
      debugPrint('Uncaught error: $error');
      debugPrint('Stack trace: $stack');
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // رنگ فیروزه‌ای و سرمه‌ای
    const Color primaryTurquoise = AppColors.primary;
    const Color secondaryNavy = AppColors.secondaryColor;

    // رنگ خاکستری
    const Color gray = AppColors.grey;
    const Color darkGray = AppColors.darkGray;

    return MaterialApp(
      title: 'Participant Pishgaman',
      debugShowCheckedModeBanner: false,
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [
        Locale('fa', 'IR'), // Persian
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Farhang',
        primarySwatch: AppColors.kMaterialPrimaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryTurquoise,
          primary: primaryTurquoise,
          secondary: secondaryNavy,
          surface: Colors.white,
          onSurface: darkGray,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'Farhang',
            color: darkGray,
            fontWeight: FontWeight.bold,
          ),
          displayMedium: TextStyle(
            fontFamily: 'Farhang',
            color: darkGray,
            fontWeight: FontWeight.bold,
          ),
          displaySmall: TextStyle(
            fontFamily: 'Farhang',
            color: darkGray,
            fontWeight: FontWeight.w600,
          ),
          headlineLarge: TextStyle(
            fontFamily: 'Farhang',
            color: darkGray,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'Farhang',
            color: darkGray,
            fontWeight: FontWeight.w600,
          ),
          headlineSmall: TextStyle(
            fontFamily: 'Farhang',
            color: darkGray,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Farhang',
            color: darkGray,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
            fontFamily: 'Farhang',
            color: darkGray,
            fontWeight: FontWeight.w500,
          ),
          titleSmall: TextStyle(
            fontFamily: 'Farhang',
            color: darkGray,
            fontWeight: FontWeight.w500,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Farhang',
            color: darkGray,
            fontWeight: FontWeight.normal,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Farhang',
            color: darkGray,
            fontWeight: FontWeight.normal,
          ),
          bodySmall: TextStyle(
            fontFamily: 'Farhang',
            color: gray,
            fontWeight: FontWeight.normal,
          ),
          labelLarge: TextStyle(
            fontFamily: 'Farhang',
            color: darkGray,
            fontWeight: FontWeight.w500,
          ),
          labelMedium: TextStyle(
            fontFamily: 'Farhang',
            color: gray,
            fontWeight: FontWeight.normal,
          ),
          labelSmall: TextStyle(
            fontFamily: 'Farhang',
            color: gray,
            fontWeight: FontWeight.normal,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: primaryTurquoise,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Farhang',
            color: primaryTurquoise,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryTurquoise,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryTurquoise,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Farhang',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isLoading = true;
  Widget? _initialRoute;

  @override
  void initState() {
    super.initState();
    _checkAuthAndIntro();
  }

  Future<void> _checkAuthAndIntro() async {
    try {
      final authService = AuthService();
      await authService.init();

      // Check if user is logged in (has token, phone, and role)
      final token = authService.getToken();
      final phone = authService.getPhone();
      final role = authService.getRole();

      if (token != null && phone != null && role != null) {
        // User is logged in, skip intro and login
        debugPrint('✅ User is logged in. Skipping intro and login.');
        debugPrint('📱 Phone: $phone');
        debugPrint('👤 Role: $role');
        
        if (mounted) {
          setState(() {
            _initialRoute = MyHomePage(title: 'شرکت کننده پیشگامان');
            _isLoading = false;
          });
        }
        return;
      }

      // User is not logged in, check intro
      final onboardingService = OnboardingService();
      final isIntroCompleted = onboardingService.isIntroCompleted();

      if (mounted) {
        setState(() {
          if (isIntroCompleted) {
            // Intro completed, go to login
            _initialRoute = LoginEntryPage();
          } else {
            // Show intro page
            _initialRoute = const IntroPage();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error checking auth and intro: $e');
      // On error, show intro page
      if (mounted) {
        setState(() {
          _initialRoute = const IntroPage();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show loading screen while checking auth
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _initialRoute ?? const IntroPage();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 2; // خانه به عنوان صفحه پیش‌فرض
  final PageController _sliderController = PageController();
  int _currentSliderIndex = 0;
  Timer? _sliderTimer;

  // لیست تصاویر لورم ایپسوم برای اسلایدر
  final List<String> _sliderImages = [
    'https://picsum.photos/400/200?random=1',
    'https://picsum.photos/400/200?random=2',
    'https://picsum.photos/400/200?random=3',
  ];

  @override
  void initState() {
    super.initState();
    // شروع تایمر برای اسلایدر خودکار
    _startSliderTimer();
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _sliderController.dispose();
    super.dispose();
  }

  void _startSliderTimer() {
    _sliderTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_sliderController.hasClients) {
        if (_currentSliderIndex < _sliderImages.length - 1) {
          _currentSliderIndex++;
        } else {
          _currentSliderIndex = 0;
        }
        _sliderController.animateToPage(
          _currentSliderIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onNavTap(int index) {
    // اگر روی خانه کلیک شد، فقط index را تغییر بده
    if (index == 2) {
      setState(() {
        _currentIndex = index;
      });
      return;
    }

    // برای سایر صفحات، به صفحه مجزا ناوبری کن
    Widget? targetPage;
    switch (index) {
      case 0: // پروفایل
        targetPage = const ProfilePage();
        break;
      case 1: // گالری
        targetPage = const GalleryPage();
        break;
      case 3: // مسیر دوره
        targetPage = const CoursePathPage();
        break;
      case 4: // تنظیمات
        targetPage = const SettingsPage();
        break;
    }

    if (targetPage != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => targetPage!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTurquoise = AppColors.primary;
    const Color darkGray = AppColors.darkGray;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('خانه'),
          backgroundColor: Colors.white,
          foregroundColor: primaryTurquoise,
          leading: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(FontAwesomeIcons.bell, color: AppColors.primary),
              onPressed: () {},
            ),
          ),
        ),
        body: _buildHomePage(context, primaryTurquoise, darkGray),
        bottomNavigationBar: CustomBottomNav(
          currentIndex: _currentIndex,
          onTap: _onNavTap,
        ),
      ),
    );
  }


  // صفحه خانه
  Widget _buildHomePage(BuildContext context, Color primaryTurquoise, Color darkGray) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.grey.shade50],
        ),
      ),
      child: Column(
        children: [
          // اسلایدر تصویر در بالای صفحه
          _buildImageSlider(context),
          // محتوای باقی‌مانده صفحه
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'دسترسی سریع',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: darkGray,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildQuickAccessGrid(context, primaryTurquoise, darkGray),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // گرید دسترسی سریع
  Widget _buildQuickAccessGrid(BuildContext context, Color primaryTurquoise, Color darkGray) {
    final quickAccessItems = [
      {
        'icon': FontAwesomeIcons.clipboardCheck,
        'title': 'نظر سنجی',
        'color': AppColors.primary,
        'route': null,
      },
      {
        'icon': FontAwesomeIcons.idCard,
        'title': 'کارت شناسایی',
        'color': AppColors.primary,
        'route': const IdCardPage(),
      },
      {
        'icon': FontAwesomeIcons.sitemap,
        'title': 'معرفی شاخه ها',
        'color': AppColors.primary,
        'route': null,
      },
      {
        'icon': FontAwesomeIcons.infoCircle,
        'title': 'درباره ما',
        'color': AppColors.primary,
        'route': null,
      },
      {
        'icon': FontAwesomeIcons.book,
        'title': 'دوره‌ها',
        'color': AppColors.primary,
        'route': null,
      },
      {
        'icon': FontAwesomeIcons.images,
        'title': 'گالری',
        'color': AppColors.primary,
        'route': const GalleryPage(),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.2,
      ),
      itemCount: quickAccessItems.length,
      itemBuilder: (context, index) {
        final item = quickAccessItems[index];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
          child: InkWell(
            onTap: () {
              final route = item['route'] as Widget?;
              if (route != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => route),
                );
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (item['color'] as Color).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: item['color'] as Color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item['title'] as String,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: darkGray,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ویجت اسلایدر تصویر
  Widget _buildImageSlider(BuildContext context) {
    return Container(
      height: 200,
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      child: Stack(
        children: [
          PageView.builder(
            controller: _sliderController,
            onPageChanged: (index) {
              setState(() {
                _currentSliderIndex = index;
              });
            },
            itemCount: _sliderImages.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: _sliderImages[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(
                          FontAwesomeIcons.image,
                          size: 32,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // نشانگر صفحات
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _sliderImages.length,
                (index) => Container(
                  width: _currentSliderIndex == index ? 20 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: _currentSliderIndex == index
                        ? AppColors.primary
                        : Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}
