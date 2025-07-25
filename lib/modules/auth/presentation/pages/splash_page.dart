import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../routes/app_routes.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _fadeController;
  late Animation<double> _progressAnimation;
  late Animation<double> _fadeAnimation;
  int _loadingPercentage = 0;
  bool _isLoadingComplete = false;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _progressAnimation.addListener(() {
      setState(() {
        _loadingPercentage = (_progressAnimation.value * 100).round();
        if (_loadingPercentage >= 100) {
          _isLoadingComplete = true;
        }
      });
    });

    _startLoading();
  }

  Future<void> _startLoading() async {
    // Start animations immediately
    _fadeController.forward();
    _progressController.forward();

    // Wait for animation to complete
    await _progressController.forward();

    // Brief pause to show completion
    await Future.delayed(const Duration(milliseconds: 200));

    if (!mounted) return;

    final isLoggedIn = FirebaseAuth.instance.currentUser != null;

    // Use pushNamedAndRemoveUntil for better memory management
    Navigator.of(context).pushNamedAndRemoveUntil(
      isLoggedIn ? AppRoutes.home : AppRoutes.login,
      (route) => false,
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // App Logo - larger and more prominent
                Image.asset(
                  'assets/images/AGOSLOGOWTEXT.png',
                  width: 240,
                  height: 240,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to icon if image fails to load
                    return const Icon(
                      Icons.directions_boat,
                      size: 120,
                      color: Color(0xFF60A5FA),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Loading section
                if (!_isLoadingComplete) ...[
                  // Loading text
                  Text(
                    '$_loadingPercentage%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Animated boat progress
                  SizedBox(
                    width: 280,
                    height: 40,
                    child: Stack(
                      children: [
                        // Progress track
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),

                        // Progress fill
                        Positioned(
                          bottom: 16,
                          left: 0,
                          child: AnimatedBuilder(
                            animation: _progressAnimation,
                            builder: (context, child) {
                              return Container(
                                width: 280 * _progressAnimation.value,
                                height: 2,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF60A5FA),
                                      Color(0xFF3B82F6),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              );
                            },
                          ),
                        ),

                        // Animated boat
                        AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return Positioned(
                              left: (280 - 24) * _progressAnimation.value,
                              bottom: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF60A5FA),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF60A5FA,
                                      ).withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.directions_boat,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),

                        // Finish line
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 2,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0xFF9CA3AF),
                                  const Color(0xFF9CA3AF).withOpacity(0.3),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Success state
                if (_isLoadingComplete)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF22C55E).withOpacity(0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: Color(0xFF22C55E),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Ready',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF22C55E),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
