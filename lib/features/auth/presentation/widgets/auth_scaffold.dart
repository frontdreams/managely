import 'package:flutter/material.dart';
import 'auth_widgets.dart';

/// Shared layout for the login, register and forgot-password screens —
/// centralizes the Scaffold/SafeArea/scroll/Form boilerplate and the
/// [AuthLogo] header so each screen only supplies its own form fields.
class AuthScaffold extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final List<Widget> children;

  /// Shows a back-arrow app bar, used when the screen is pushed on top of
  /// login (register, forgot password) rather than being the entry point.
  final bool showBackButton;

  const AuthScaffold({
    super.key,
    required this.formKey,
    required this.children,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showBackButton ? AppBar() : null,
      body: SafeArea(
        top: !showBackButton,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, showBackButton ? 0 : 32, 24, 24),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AuthLogo(),
                const SizedBox(height: 24),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
