import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60, height: 60,
              child: CircularProgressIndicator(
                color: AppColors.primaryBlue, strokeWidth: 2.5),
            ),
            SizedBox(height: 24),
            Text('ميزانيتي AI',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
