import 'package:flutter/material.dart';
import 'package:peereess/core/app_button.dart';
import 'package:peereess/core/app_images.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  /// Mark onboarding as seen so Splash never shows it again
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xffB0864C), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            if (index == 1) {
              _rotationController.forward(from: 0);
            } else {
              _rotationController.reset();
            }
          },
          children: [
            // ── Page 1 ──
            _buildPage(
              context: context,
              image: AppImages.onboarding1,
              title: "Women Who Value Quality",
              description:
                  "Enjoy a personalized shopping experience with items picked just for you and delivered beautifully.",
              isTablet: isTablet,
              activeIndex: 0,
              onNext: () => _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              // "Skip" on page 1 → go directly to home
              onAltAction: () async {
                await _completeOnboarding();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (_) => false,
                  );
                }
              },
            ),

            // ── Page 2 (last) ──
            _buildPage(
              context: context,
              image: AppImages.onboarding2,
              title: "Shop like a queen You Are",
              description:
                  "Discover curated style picks made just for you. Peeress brings effortless luxury your way.",
              isTablet: isTablet,
              activeIndex: 1,
              isLastPage: true,
              spinImage: true,
              // "Get Started" → go to signup
              onNext: () async {
                await _completeOnboarding();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/signup',
                    (_) => false,
                  );
                }
              },
              // "Login" → go to login
              onAltAction: () async {
                await _completeOnboarding();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (_) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required BuildContext context,
    required String image,
    required String title,
    required String description,
    required bool isTablet,
    required int activeIndex,
    required VoidCallback onNext,
    VoidCallback? onAltAction,
    bool isLastPage = false,
    bool spinImage = false,
  }) {
    Widget imageWidget = SizedBox(
      height: isTablet ? 450 : 300,
      child: Image.asset(image, fit: BoxFit.contain),
    );

    if (spinImage) {
      imageWidget = RotationTransition(
        turns: _rotationController,
        child: imageWidget,
      );
    }

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 500 : double.infinity,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  imageWidget,
                  const SizedBox(height: 40),

                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isTablet ? 24 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xff6A7686),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Dot indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(2, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 6,
                        width: activeIndex == index ? 20 : 10,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: activeIndex == index
                              ? const Color(0xffB0864C)
                              : Colors.grey.shade400,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 40),

                  AppButtons(
                    onPressed: onNext,
                    text: isLastPage ? "Get Started" : "Continue",
                  ),
                  const SizedBox(height: 12),
                  Appbuttons2(
                    onPressed: onAltAction ?? onNext,
                    text: isLastPage ? "Login" : "Skip",
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
