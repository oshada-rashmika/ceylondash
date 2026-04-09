// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/email_input_field.dart';
import '../widgets/password_input_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/top_snackbar.dart';
import 'admin/admin_dashboard_screen.dart';
import '../utils/validators.dart';
import 'admin/supervisor_dashboard_shell.dart';

class AdminLoginScreen extends StatefulWidget {
  final String portalType;

  const AdminLoginScreen({super.key, this.portalType = 'agent'});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _dbService = DatabaseService();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;

  late final AnimationController _entranceCtrl;
  late final List<Animation<double>> _fades;
  late final List<Animation<Offset>> _slides;

  static const _count = 5;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fades = List.generate(_count, (i) {
      final s = i * 0.1;
      return CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(s, (s + 0.4).clamp(0, 1), curve: Curves.easeOut),
      );
    });
    _slides = List.generate(_count, (i) {
      final s = i * 0.1;
      return Tween(begin: const Offset(0, 0.12), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _entranceCtrl,
          curve: Interval(s, (s + 0.4).clamp(0, 1), curve: Curves.easeOutCubic),
        ),
      );
    });
    _entranceCtrl.forward();
  }

  Future<void> _handleAdminLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final cred = await _authService.signIn(
        _emailCtrl.text,
        _passwordCtrl.text,
      );

      var user = await _dbService.getUser(cred.user!.uid);
      
      // Fallback: the UID in database might be outdated (manual creation)
      if (user == null && cred.user?.email != null) {
        debugPrint('🔍 UID lookup failed, searching for email: ${cred.user!.email}');
        user = await _dbService.getUserByEmail(cred.user!.email!);
      }

      final role = (user?.role ?? 'customer').trim().toLowerCase();
      
      debugPrint('🔑 Resolved Role: UID=${cred.user!.uid}, Role=$role');

      if (!mounted) return;

      if (role == 'supervisor') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SupervisorDashboardShell()),
          (route) => false,
        );
      } else if (role == 'agent') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminDashboardScreen(),
          ),
          (route) => false,
        );
      } else {
        await _authService.signOut();
        TopSnackbar.show(
          context,
          message: 'Unauthorized. Staff access only.',
          type: SnackbarType.error,
        );
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
          message: 'An unexpected error occurred. Please try again.',
          type: SnackbarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _anim(
                    0,
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.cyan.withAlpha(18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_outlined,
                        size: 46,
                        color: Colors.cyan,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _anim(
                    1,
                    Text(
                      widget.portalType == 'supervisor'
                          ? 'Supervisor Portal'
                          : 'Agent Portal',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  _anim(2, EmailInputField(controller: _emailCtrl)),
                  const SizedBox(height: 16),

                  _anim(
                    3,
                    PasswordInputField(
                      controller: _passwordCtrl,
                      showRequirements: false,
                      validator: widget.portalType == 'supervisor'
                          ? Validators.validateSupervisorPassword
                          : Validators.validatePassword,
                    ),
                  ),
                  const SizedBox(height: 32),

                  _anim(
                    4,
                    CustomButton(
                      text: widget.portalType == 'supervisor'
                          ? 'Sign In as Supervisor'
                          : 'Sign In as Agent',
                      isLoading: _isLoading,
                      icon: Icons.shield_outlined,
                      onPressed: _handleAdminLogin,
                    ),
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
