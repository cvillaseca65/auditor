import 'package:flutter/material.dart';

class SimAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const SimAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 40,
          ),
          const SizedBox(width: 12),
          Text(title),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
