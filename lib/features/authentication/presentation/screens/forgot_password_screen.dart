import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doodledry/core/constants/app_colors.dart';
import 'package:doodledry/core/constants/app_text_styles.dart';
import 'package:doodledry/features/authentication/presentation/providers/auth_provider.dart';
import 'package:doodledry/shared/widgets/custom_button.dart';
import 'package:doodledry/shared/widgets/custom_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isSent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        await ref.read(authRepositoryProvider).sendPasswordResetEmail(_emailCtrl.text.trim());
        setState(() => _isSent = true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: _isSent
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: AppColors.successBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mark_email_read_rounded, color: AppColors.success, size: 48),
                      ),
                      const SizedBox(height: 18),
                      Text("Reset Link Sent", style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(
                        "We've sent a password reset email to ${_emailCtrl.text.trim()}. Follow the instructions in the email to regain access.",
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: "Back to Sign In",
                        variant: CustomButtonVariant.primary,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Reset Password",
                        style: AppTextStyles.displaySmall.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Enter the email associated with your account and we will send you a password reset link.",
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 24),
                      CustomTextField(
                        label: "Email Address",
                        hint: "parent@example.com",
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        validator: (v) => (v == null || !v.contains('@')) ? "Enter a valid email" : null,
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: "Send Reset Link",
                        isLoading: _isLoading,
                        variant: CustomButtonVariant.primary,
                        onPressed: _handleReset,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
