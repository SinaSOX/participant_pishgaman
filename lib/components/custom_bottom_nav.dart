import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants/app_colors.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: 70,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildNavItem(
                      icon: FontAwesomeIcons.user,
                      label: 'پروفایل',
                      index: 0,
                      isCenter: false,
                    ),
                  ),
                  Expanded(
                    child: _buildNavItem(
                      icon: FontAwesomeIcons.users,
                      label: 'شبکه سازی',
                      index: 1,
                      isCenter: false,
                    ),
                  ),
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: _buildNavItem(
                      icon: FontAwesomeIcons.house,
                      label: '',
                      index: 2,
                      isCenter: true,
                    ),
                  ),
                  Expanded(
                    child: _buildNavItem(
                      icon: FontAwesomeIcons.route,
                      label: 'مسیر دوره',
                      index: 3,
                      isCenter: false,
                    ),
                  ),
                  Expanded(
                    child: _buildNavItem(
                      icon: FontAwesomeIcons.gear,
                      label: 'تنظیمات',
                      index: 4,
                      isCenter: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isCenter,
  }) {
    final isSelected = currentIndex == index;

    if (isCenter) {
      // آیتم وسط - مربع با گوشه‌های گرد
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            constraints: const BoxConstraints.tightFor(width: 56, height: 56),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.grey,
              size: 24,
            ),
          ),
        ),
      );
    } else {
      // آیتم‌های عادی
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    child: Icon(
                      icon,
                      key: ValueKey('icon_${index}_$currentIndex'),
                      color: isSelected ? Colors.white : AppColors.grey,
                      size: 22,
                    ),
                  ),
                ),
                if (label.isNotEmpty) ...[
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'Farhang',
                            color: isSelected ? Colors.white : AppColors.grey,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            height: 1.2,
                          ),
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
  }
}

