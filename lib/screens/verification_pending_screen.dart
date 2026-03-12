import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/top_snackbar.dart';
import '../widgets/custom_button.dart';

class VerificationPendingScreen extends StatefulWidget {
  const VerificationPendingScreen({super.key});

  @override
  State<VerificationPendingScreen> createState() =>
      _VerificationPendingScreenState();
}

class _VerificationPendingScreenState extends State<VerificationPendingScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  bool _canResend = false;
  int _countdown = 60;
  Timer? _timer;
  bool _isResending = false;

  late final AnimationController _entranceCtrl;
  late final List<Animation<double>> _fades;
  late final List<Animation<Offset>> _slides;

  static const _count = 5;

  String get _email => FirebaseAuth.instance.currentUser?.email ?? 'your email';

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fades = List.generate(_count, (i) {
      final s = i * 0.12;
      return CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(s, (s + 0.4).clamp(0, 1), curve: Curves.easeOut),
      );
    });
    _slides = List.generate(_count, (i) {
      final s = i * 0.12;
      return Tween(begin: const Offset(0, 0.12), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _entranceCtrl,
          curve: Interval(s, (s + 0.4).clamp(0, 1), curve: Curves.easeOutCubic),
        ),
      );
    });
    _entranceCtrl.forward();
    _startCountdown();
  }

  void _startCountdown() {
    setState(() {
      _canResend = false;
      _countdown = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 1) {
        t.cancel();
        if (mounted) setState(() => _canResend = true);
      } else {
        if (mounted) setState(() => _countdown--);
      }
    });
  }

  Future<void> _resendEmail() async {
    if (!_canResend || _isResending) return;
    setState(() => _isResending = true);
    try {
      await _authService.sendVerificationEmail();
      if (mounted) {
        TopSnackbar.show(
          context,
          message: 'Verification email resent to $_email',
          type: SnackbarType.success,
        );
        _startCountdown();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        TopSnackbar.show(
          context,
          message: AuthService.friendlyAuthError(e),
          type: SnackbarType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        TopSnackbar.show(
          context,
          message: 'Failed to resend verification email. Please try again.',
          type: SnackbarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _backToLogin() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _entranceCtrl.dispose();
    super.dispose();
  }

  Widget _anim(int i, Widget child) => FadeTransition(
    opacity: _fades[i],
    child: SlideTransition(position: _slides[i], child: child),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _anim(
                  0,
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.cyan.withAlpha(18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_outlined,
                      size: 52,
                      color: Colors.cyan,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _anim(
                  1,
                  const Text(
                    'Verify Your Email',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _anim(
                  2,
                  Text(
                    'We sent a verification link to\n$_email',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                _anim(
                  3,
                  CustomButton(
                    text: _canResend
                        ? 'Resend Verification Email'
                        : 'Resend in ${_countdown}s',
                    isLoading: _isResending,
                    onPressed: _canResend ? _resendEmail : null,
                  ),
                ),
                const SizedBox(height: 16),
                _anim(
                  4,
                  TextButton(
                    onPressed: _backToLogin,
                    child: const Text(
                      'Back to Login',
                      style: TextStyle(
                        color: Colors.cyan,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
