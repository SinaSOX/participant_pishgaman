import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'models/course_step.dart';

class CoursePathPage extends StatefulWidget {
  const CoursePathPage({super.key});

  @override
  State<CoursePathPage> createState() => _CoursePathPageState();
}

class _CoursePathPageState extends State<CoursePathPage>
    with SingleTickerProviderStateMixin {
  // داده‌های نمونه برای مراحل دوره
  late List<CourseStep> courseSteps;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initializeSteps();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animation after the first frame to ensure widget tree is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.repeat(reverse: true);
        // اسکرول به پایین برای نمایش ابتدای دوره
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _initializeSteps() {
    courseSteps = [
      CourseStep(
        id: 0,
        title: 'شروع',
        icon: Icons.flag,
        status: StepStatus.completed,
        color: Colors.green,
        time: '08:00',
      ),
      CourseStep(
        id: 1,
        title: 'مقدمه',
        subtitle: 'آشنایی با دوره',
        icon: Icons.book,
        status: StepStatus.completed,
        time: '08:15',
      ),
      CourseStep(
        id: 2,
        title: 'درس اول',
        subtitle: 'مبانی اولیه',
        icon: Icons.school,
        status: StepStatus.completed,
        time: '09:00',
      ),
      CourseStep(
        id: 3,
        title: 'استراحت',
        subtitle: 'زنگ تفریح',
        icon: Icons.coffee,
        status: StepStatus.completed,
        color: const Color(0xFF8B4513),
        time: '09:45',
      ),
      CourseStep(
        id: 4,
        title: 'درس دوم',
        subtitle: 'پیشرفته',
        icon: Icons.lightbulb,
        status: StepStatus.completed,
        time: '10:00',
      ),
      CourseStep(
        id: 5,
        title: 'نماز ظهر',
        subtitle: 'وقت نماز',
        icon: Icons.mosque,
        status: StepStatus.completed,
        color: const Color(0xFF2E7D32),
        time: '12:30',
      ),
      CourseStep(
        id: 6,
        title: 'درس سوم',
        subtitle: 'تخصصی',
        icon: Icons.auto_stories,
        status: StepStatus.unlocked,
        time: '13:00',
      ),
      CourseStep(
        id: 7,
        title: 'ناهار',
        subtitle: 'وقت غذا',
        icon: Icons.restaurant,
        status: StepStatus.unlocked,
        color: const Color(0xFFFF6B35),
        time: '13:30',
      ),
      CourseStep(
        id: 8,
        title: 'درس چهارم',
        subtitle: 'کاربردی',
        icon: Icons.code,
        status: StepStatus.unlocked,
        time: '14:30',
      ),
      CourseStep(
        id: 9,
        title: 'استراحت',
        subtitle: 'زنگ تفریح',
        icon: Icons.coffee,
        status: StepStatus.unlocked,
        color: const Color(0xFF8B4513),
        time: '15:15',
      ),
      CourseStep(
        id: 10,
        title: 'درس پنجم',
        subtitle: 'پروژه محور',
        icon: Icons.work,
        status: StepStatus.locked,
        time: '15:30',
      ),
      CourseStep(
        id: 11,
        title: 'نماز عصر',
        subtitle: 'وقت نماز',
        icon: Icons.mosque,
        status: StepStatus.locked,
        color: const Color(0xFF2E7D32),
        time: '16:00',
      ),
      CourseStep(
        id: 12,
        title: 'درس ششم',
        subtitle: 'بهینه‌سازی',
        icon: Icons.tune,
        status: StepStatus.locked,
        time: '16:15',
      ),
      CourseStep(
        id: 13,
        title: 'استراحت',
        subtitle: 'زنگ تفریح',
        icon: Icons.coffee,
        status: StepStatus.locked,
        color: const Color(0xFF8B4513),
        time: '17:00',
      ),
      CourseStep(
        id: 14,
        title: 'درس هفتم',
        subtitle: 'تست و دیباگ',
        icon: Icons.bug_report,
        status: StepStatus.locked,
        time: '17:15',
      ),
      CourseStep(
        id: 15,
        title: 'شام',
        subtitle: 'وقت غذا',
        icon: Icons.restaurant_menu,
        status: StepStatus.locked,
        color: const Color(0xFFFF6B35),
        time: '19:00',
      ),
      CourseStep(
        id: 16,
        title: 'درس هشتم',
        subtitle: 'استقرار',
        icon: Icons.cloud_upload,
        status: StepStatus.locked,
        time: '19:30',
      ),
      CourseStep(
        id: 17,
        title: 'نماز مغرب',
        subtitle: 'وقت نماز',
        icon: Icons.mosque,
        status: StepStatus.locked,
        color: const Color(0xFF2E7D32),
        time: '19:45',
      ),
      CourseStep(
        id: 18,
        title: 'درس نهم',
        subtitle: 'نگهداری',
        icon: Icons.settings,
        status: StepStatus.locked,
        time: '20:00',
      ),
      CourseStep(
        id: 19,
        title: 'استراحت',
        subtitle: 'زنگ تفریح',
        icon: Icons.coffee,
        status: StepStatus.locked,
        color: const Color(0xFF8B4513),
        time: '20:45',
      ),
      CourseStep(
        id: 20,
        title: 'درس دهم',
        subtitle: 'پیشرفته',
        icon: Icons.trending_up,
        status: StepStatus.locked,
        time: '21:00',
      ),
      CourseStep(
        id: 21,
        title: 'پایان',
        icon: Icons.emoji_events,
        status: StepStatus.locked,
        color: Colors.orange,
        time: '21:30',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مسیر دوره'),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          elevation: 0,
        ),
        backgroundColor: Colors.white,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                AppColors.primary.withOpacity(0.03),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: _buildPathWidget(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPathWidget() {
    // لیست را معکوس می‌کنیم تا ابتدای دوره در پایین باشد
    final reversedSteps = courseSteps.reversed.toList();
    
    return Column(
      children: reversedSteps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final originalIndex = courseSteps.length - 1 - index;
        final isLast = index == reversedSteps.length - 1;
        
        return Column(
          children: [
            _buildStepItem(step, originalIndex),
            if (!isLast) _buildConnector(originalIndex, index),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildStepItem(CourseStep step, int index) {
    final isLeft = index % 2 == 0;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isLeft) ...[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (step.time != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          step.time!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontFamily: 'Farhang',
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                if (step.subtitle != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      step.subtitle!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'Farhang',
                        color: AppColors.darkGray,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  step.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Farhang',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2C2C),
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildStepSquare(step),
          const SizedBox(width: 16),
          const SizedBox(width: 80), // Space for right side
        ] else ...[
          const SizedBox(width: 80), // Space for left side
          _buildStepSquare(step),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (step.time != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          step.time!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontFamily: 'Farhang',
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                if (step.subtitle != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      step.subtitle!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'Farhang',
                        color: AppColors.darkGray,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  step.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Farhang',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2C2C),
                  ),
                  textAlign: TextAlign.left,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildConnector(int originalIndex, int reversedIndex) {
    // در لیست معکوس، آیتم بعدی در واقع آیتم قبلی در لیست اصلی است
    final nextOriginalIndex = originalIndex - 1;
    final isLeft = originalIndex % 2 == 0;
    final nextStep = courseSteps[nextOriginalIndex];
    final currentStep = courseSteps[originalIndex];
    
    Color connectorColor;
    double strokeWidth = 4;
    if (currentStep.status == StepStatus.completed && 
        nextStep.status != StepStatus.locked) {
      connectorColor = AppColors.primary;
      strokeWidth = 4;
    } else if (nextStep.status == StepStatus.locked) {
      connectorColor = AppColors.grey.withOpacity(0.3);
      strokeWidth = 3;
    } else {
      connectorColor = AppColors.primary.withOpacity(0.4);
      strokeWidth = 3.5;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // محاسبه موقعیت مرکز مربع‌ها بر اساس عرض واقعی
        const double squareSize = 80;
        const double squareCenter = squareSize / 2;
        const double spacing = 16;
        const double sideSpace = 80;
        const double padding = 20;
        
        // موقعیت مرکز مربع فعلی (پایین)
        double currentCenterX;
        if (isLeft) {
          // مربع در سمت راست (RTL)
          currentCenterX = constraints.maxWidth - padding - sideSpace - spacing - squareCenter;
        } else {
          // مربع در سمت چپ (RTL)
          currentCenterX = padding + sideSpace + spacing + squareCenter;
        }
        
        // موقعیت مرکز مربع بعدی (بالا) - برعکس
        double nextCenterX;
        if (!isLeft) {
          // مربع بعدی در سمت راست (RTL)
          nextCenterX = constraints.maxWidth - padding - sideSpace - spacing - squareCenter;
        } else {
          // مربع بعدی در سمت چپ (RTL)
          nextCenterX = padding + sideSpace + spacing + squareCenter;
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          height: 60,
          child: CustomPaint(
            painter: CurvedConnectorPainter(
              startX: currentCenterX,
              endX: nextCenterX,
              connectorColor: connectorColor,
              strokeWidth: strokeWidth,
            ),
            child: Container(),
          ),
        );
      },
    );
  }

  Widget _buildStepSquare(CourseStep step) {
    Color squareColor;
    Color iconColor = Colors.white;
    double squareSize = 80;
    double borderRadius = 16;
    
    switch (step.status) {
      case StepStatus.completed:
        squareColor = step.color ?? AppColors.primary;
        break;
      case StepStatus.unlocked:
        squareColor = AppColors.primary;
        break;
      case StepStatus.locked:
        squareColor = AppColors.grey;
        iconColor = Colors.white.withOpacity(0.7);
        break;
    }

    // ایجاد ویجت مربع گرد پایه
    Widget baseSquareWidget = Container(
      width: squareSize,
      height: squareSize,
      decoration: BoxDecoration(
        color: squareColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: squareColor.withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        step.icon,
        color: iconColor,
        size: 36,
      ),
    );

    // اضافه کردن تیک برای مراحل تکمیل شده (به جز شروع و پایان)
    if (step.status == StepStatus.completed && 
        step.id != 0 && 
        step.id != courseSteps.length - 1) {
      baseSquareWidget = Stack(
        alignment: Alignment.center,
        children: [
          baseSquareWidget,
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ],
      );
    }

    // استایل خاص برای پرچم شروع
    if (step.id == 0) {
      baseSquareWidget = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.5),
              blurRadius: 15,
              spreadRadius: 5,
            ),
          ],
        ),
        child: baseSquareWidget,
      );
    }

    // استایل خاص برای پرچم پایان
    if (step.id == courseSteps.length - 1) {
      baseSquareWidget = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 5,
            ),
          ],
        ),
        child: baseSquareWidget,
      );
    }

    // اضافه کردن انیمیشن پالس برای مراحل باز شده
    Widget finalSquareWidget;
    if (step.status == StepStatus.unlocked && mounted) {
      finalSquareWidget = AnimatedBuilder(
        key: ValueKey('pulse_${step.id}'),
        animation: _pulseAnimation,
        builder: (BuildContext context, Widget? child) {
          if (!mounted) return child ?? baseSquareWidget;
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: squareColor.withOpacity(0.3 * (2 - _pulseAnimation.value)),
                    blurRadius: 20 * _pulseAnimation.value,
                    spreadRadius: 5 * _pulseAnimation.value,
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: baseSquareWidget,
      );
    } else {
      finalSquareWidget = baseSquareWidget;
    }

    return GestureDetector(
      onTap: step.status != StepStatus.locked
          ? () {
              // TODO: Navigate to step
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('باز کردن ${step.title}'),
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          : null,
      child: finalSquareWidget,
    );
  }
}

// کلاس برای رسم خطوط منحنی اتصال
class CurvedConnectorPainter extends CustomPainter {
  final double startX;
  final double endX;
  final Color connectorColor;
  final double strokeWidth;

  CurvedConnectorPainter({
    required this.startX,
    required this.endX,
    required this.connectorColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = connectorColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // نقطه شروع (بالا - مرکز مربع فعلی - چون لیست معکوس است)
    final startPoint = Offset(startX, 0);
    
    // نقطه پایان (پایین - مرکز مربع بعدی - چون لیست معکوس است)
    final endPoint = Offset(endX, size.height);

    // ایجاد منحنی مارپیچی زیبا
    final path = Path();
    path.moveTo(startPoint.dx, startPoint.dy);

    // محاسبه نقاط کنترل برای منحنی S شکل نرم
    final midY = size.height / 2;
    
    // محاسبه فاصله افقی برای تعیین شدت منحنی
    final horizontalDistance = (endPoint.dx - startPoint.dx).abs();
    final curveIntensity = horizontalDistance * 0.6; // شدت منحنی
    
    // نقاط کنترل برای منحنی S شکل
    // نقطه کنترل اول: از نقطه شروع به سمت وسط با انحنا
    final controlPoint1X = startPoint.dx;
    final controlPoint1Y = midY - curveIntensity * 0.3;
    
    // نقطه کنترل دوم: از وسط به سمت نقطه پایان با انحنا
    final controlPoint2X = endPoint.dx;
    final controlPoint2Y = midY + curveIntensity * 0.3;

    // استفاده از cubic bezier برای منحنی S شکل نرم و مارپیچی
    path.cubicTo(
      controlPoint1X,
      controlPoint1Y,
      controlPoint2X,
      controlPoint2Y,
      endPoint.dx,
      endPoint.dy,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CurvedConnectorPainter oldDelegate) {
    return oldDelegate.startX != startX ||
        oldDelegate.endX != endX ||
        oldDelegate.connectorColor != connectorColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

