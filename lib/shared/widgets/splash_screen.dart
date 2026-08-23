import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Shown briefly while the auth state and (if signed in) the user's
/// Firestore profile are still loading, before routing decides where to go.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            const SizedBox(
              width: 220,
              height: 220,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.textOnBrand,
              ),
            ),
            Image.asset(
              'assets/icon.png',
              width: 150,
              height: 150,
              color: AppColors.textOnBrand,
            ),
          ],
        ),
      ),
    );
  }
}
