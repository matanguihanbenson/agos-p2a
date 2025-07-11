import 'package:flutter/material.dart';

class SettingsItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isDestructive;

  SettingsItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
    this.trailing,
    this.isDestructive = false,
  });
}
