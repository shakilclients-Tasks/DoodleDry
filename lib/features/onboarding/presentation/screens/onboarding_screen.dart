import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../authentication/presentation/screens/login_screen.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Smart Monitoring',
      'description': 'Monitor important baby health and activity information in real time with medical-grade precision telemetry.',
      'icon': Icons.monitor_heart_rounded,
      'color': AppColors.primary,
      'bgColor': AppColors.primaryContainer,
    },
    {
      'title': 'Connected Wearable',
      'description': 'Connect the removable monitoring module securely with your smartphone over low-energy Bluetooth or Cloud Sync.',
      'icon': Icons.sensors_rounded,
      'color': AppColors.secondary,
      'bgColor': AppColors.secondaryContainer,
    },
    {
      'title': 'Smart Alerts',
      'description': 'Receive instantaneous alerts when the device detects an abnormal vital reading, sudden impact, or connection problem.',
      'icon': Icons.notifications_active_rounded,
      'color': AppColors.heartRate,
      'bgColor': AppColors.heartRateBg,
    },
  ];

  Future<void> _completeOnboarding() async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.setOnboardingCompleted(true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text("DOODLEDRY", style: AppTextStyles.titleSmall.copyWith(letterSpacing: 1.0)),
                    ],
                  ),
                  if (_currentPage < _slides.length - 1)
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(
                        "Skip",
                        style: AppTextStyles.titleSmall.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 48),
                ],
              ),
            ),

            // Page View Carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: slide['bgColor'] as Color,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            slide['icon'] as IconData,
                            size: 64,
                            color: slide['color'] as Color,
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          slide['title'] as String,
                          style: AppTextStyles.displaySmall.copyWith(fontWeight: FontWeight.w800),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide['description'] as String,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Indicators & Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      if (_currentPage > 0) ...[
                        Expanded(
                          flex: 1,
                          child: CustomButton(
                            text: "Back",
                            variant: CustomButtonVariant.outline,
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        flex: 2,
                        child: CustomButton(
                          text: _currentPage == _slides.length - 1 ? "Get Started" : "Next",
                          variant: CustomButtonVariant.primary,
                          onPressed: () {
                            if (_currentPage == _slides.length - 1) {
                              _completeOnboarding();
                            } else {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
