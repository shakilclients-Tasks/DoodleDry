import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doodledry/app.dart';
import 'package:doodledry/core/constants/app_colors.dart';
import 'package:doodledry/core/constants/app_text_styles.dart';
import 'package:doodledry/features/authentication/presentation/providers/auth_provider.dart';
import 'package:doodledry/shared/widgets/custom_button.dart';
import 'package:doodledry/shared/widgets/custom_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        await ref.read(authRepositoryProvider).registerWithEmail(
              _emailCtrl.text.trim(),
              _passwordCtrl.text.trim(),
              _nameCtrl.text.trim(),
            );
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainAppScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString().replaceAll("Exception: ", "");
        });
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Create Caregiver Account",
                    style: AppTextStyles.displaySmall.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Register to connect and monitor your baby's DOODLEDRY device.",
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.dangerBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.danger.withOpacity(0.5)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.danger, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  CustomTextField(
                    label: "Full Name",
                    hint: "e.g. Sarah Jenkins",
                    controller: _nameCtrl,
                    prefixIcon: Icons.person_outline,
                    validator: (v) => (v == null || v.isEmpty) ? "Enter your name" : null,
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: "Email Address",
                    hint: "parent@example.com",
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: (v) => (v == null || !v.contains('@')) ? "Enter a valid email" : null,
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: "Password",
                    hint: "At least 6 characters",
                    controller: _passwordCtrl,
                    obscureText: true,
                    prefixIcon: Icons.lock_outline_rounded,
                    validator: (v) => (v == null || v.length < 6) ? "Password must be at least 6 characters" : null,
                  ),
                  const SizedBox(height: 24),

                  CustomButton(
                    text: "Create Account",
                    isLoading: _isLoading,
                    variant: CustomButtonVariant.primary,
                    onPressed: _handleRegister,
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: Text(
                          "Sign In",
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
