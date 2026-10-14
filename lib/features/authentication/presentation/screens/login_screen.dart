import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doodledry/app.dart';
import 'package:doodledry/core/constants/app_colors.dart';
import 'package:doodledry/core/constants/app_text_styles.dart';
import 'package:doodledry/features/authentication/presentation/providers/auth_provider.dart';
import 'package:doodledry/features/authentication/presentation/screens/forgot_password_screen.dart';
import 'package:doodledry/features/authentication/presentation/screens/register_screen.dart';
import 'package:doodledry/shared/widgets/custom_button.dart';
import 'package:doodledry/shared/widgets/custom_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController(text: 'parent@doodledry.com');
  final _passwordCtrl = TextEditingController(text: 'password123');
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        await ref.read(authRepositoryProvider).loginWithEmail(
              _emailCtrl.text.trim(),
              _passwordCtrl.text.trim(),
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Branding
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "DOODLEDRY",
                          style: AppTextStyles.displaySmall.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Smart Baby Monitoring Platform",
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  Text(
                    "Caregiver Sign In",
                    style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Enter your email to connect with your baby's wearable.",
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
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: AppColors.danger, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

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
                    hint: "••••••••",
                    controller: _passwordCtrl,
                    obscureText: true,
                    prefixIcon: Icons.lock_outline_rounded,
                    validator: (v) => (v == null || v.length < 6) ? "Password must be at least 6 characters" : null,
                  ),
                  const SizedBox(height: 10),

                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                        );
                      },
                      child: Text(
                        "Forgot Password?",
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  CustomButton(
                    text: "Sign In",
                    isLoading: _isLoading,
                    variant: CustomButtonVariant.primary,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 20),

                  // Demo Quick Sign In
                  CustomButton(
                    text: "Quick Demo Access (Leo's Monitor)",
                    variant: CustomButtonVariant.secondary,
                    icon: Icons.flash_on_rounded,
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const MainAppScreen()),
                        (route) => false,
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "New caregiver? ",
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: Text(
                          "Create an account",
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
