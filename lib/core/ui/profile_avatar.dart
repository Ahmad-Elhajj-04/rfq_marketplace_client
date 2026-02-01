import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String name;
  final double size;

  const ProfileAvatar({
    super.key,
    required this.name,
    this.size = 36,
  });

  String get initial {
    final trimmed = name.trim();
    return trimmed.isEmpty ? "?" : trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Colors.black.withOpacity(0.08),
      child: Text(
        initial,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}