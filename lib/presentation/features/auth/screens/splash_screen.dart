import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iotframework/core/routing/app_router.dart';
import 'package:iotframework/presentation/features/auth/providers/auth_provider.dart';
import 'package:iotframework/data/repositories/auth_repository_impl.dart';
import 'package:iotframework/core/di/injection_container.dart';
import 'package:flutter/foundation.dart';
import 'package:iotframework/core/util/constants.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  bool _isAuthChecked = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.1),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0),
        weight: 1,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeInOut),
      ),
    );

    _animationController.forward();

    // Check authentication status right away, but navigate only when animation completes
    _checkAuthStatus();

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _isAuthChecked) {
        _navigateToNextScreen();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // First, check if credentials exist
      final authRepository = ref.read(ServiceLocator.authRepositoryProvider);

      if (authRepository is AuthRepositoryImpl) {
        final tokenStatus = await authRepository.checkTokenStatus();
        debugPrint('📌 Token status on splash: $tokenStatus');

        // If we have email and password stored, attempt automatic login
        if (tokenStatus['hasEmail'] == true &&
            tokenStatus['hasPassword'] == true) {
          debugPrint('🔄 Found stored credentials, attempting auto-login');

          // Get the stored credentials using the correct keys
          final email = await authRepository.secureStorage
              .read(key: AppConstants.userEmailKey);
          final password = await authRepository.secureStorage
              .read(key: AppConstants.userPasswordKey);

          if (email != null && password != null) {
            // Attempt to login with stored credentials
            debugPrint('🔑 Auto-logging in with: $email');
            await ref.read(authProvider.notifier).login(email, password);
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error during auth check: $e');
    } finally {
      setState(() {
        _isAuthChecked = true;
      });

      // If animation has already completed, navigate to the next screen
      if (_animationController.isCompleted) {
        _navigateToNextScreen();
      }
    }
  }

  void _navigateToNextScreen() {
    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      // Navigate to main screen if already authenticated
      AppRouter.navigateToReplacement(AppRouter.mainRoute);
    } else {
      // Navigate to login screen if not authenticated
      AppRouter.navigateToReplacement(AppRouter.loginRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value * _pulseAnimation.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: Colors.greenAccent,
                      size: 80,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "SecureIOT",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent,
                      ),
                    ),
                    const SizedBox(height: 60),
                    const CircularProgressIndicator(
                      color: Colors.greenAccent,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
