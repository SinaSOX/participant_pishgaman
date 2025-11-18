import 'package:flutter/material.dart';

enum StepStatus {
  locked,
  unlocked,
  completed,
}

class CourseStep {
  final int id;
  final String title;
  final String? subtitle;
  final IconData icon;
  final StepStatus status;
  final Color? color;
  final String? time;

  CourseStep({
    required this.id,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.status,
    this.color,
    this.time,
  });
}



