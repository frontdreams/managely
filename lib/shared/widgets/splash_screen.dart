import 'package:flutter/material.dart';

/// Shown briefly while the auth state and (if signed in) the user's
/// Firestore profile are still loading, before routing decides where to go.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}
