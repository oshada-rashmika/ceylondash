import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/email_input_field.dart';
import '../widgets/password_input_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/top_snackbar.dart';
import '../widgets/slide_page_route.dart';
import 'role_selection_screen.dart';
import 'admin_login_screen.dart';
import 'seller_dashboard_screen.dart';
import 'rider_dashboard_screen.dart';
import 'admin/admin_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _dbService = DatabaseService();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;

  late final AnimationController _entranceCtrl;
  late final List<Animation<double>> _fadeAnims;
  late final List<Animation<Offset>> _slideAnims;

  static const _itemCount =
      7; // logo, title, subtitle, email, password, row, buttons

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnims = List.generate(_itemCount, (i) {
      final start = i * 0.1;
      final end = (start + 0.4).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(start, end, curve: Curves.easeOut),
      );
    });
    _slideAnims = List.generate(_itemCount, (i) {
      final start = i * 0.1;
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween(begin: const Offset(0, 0.15), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _entranceCtrl,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    _entranceCtrl.forward();
    _loadRememberedCredentials();
    TopSnackbar.showPendingIfAny(context);
  }

  Future<void> _loadRememberedCredentials() async {
    final creds = await _authService.getRememberedCredentials();
    if (creds['email'] != null && creds['password'] != null) {
      _emailCtrl.text = creds['email']!;
      _passwordCtrl.text = creds['password']!;
      setState(() => _rememberMe = true);
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final cred = await _authService.signIn(
        _emailCtrl.text,
        _passwordCtrl.text,
      );

      if (cred.user != null && !cred.user!.emailVerified) {
        await _authService.signOut();
        if (mounted) {
          TopSnackbar.show(
            context,
            message: 'Please verify your email to continue.',
            type: SnackbarType.error,
          );
        }
        return;
      }

      if (_rememberMe) {
        await _authService.saveCredentials(_emailCtrl.text, _passwordCtrl.text);
      } else {
        await _authService.clearRememberedCredentials();
      }

      final userModel = await _dbService.getUser(cred.user!.uid);

      if (!mounted) return;

      if (userModel == null || userModel.role.isEmpty) {
        await _authService.signOut();
        if (!mounted) return;
        TopSnackbar.show(
          context,
          message: 'User role not found or invalid.',
          type: SnackbarType.error,
        );
        return;
      }

      if (userModel.role == 'seller') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SellerDashboardScreen()),
        );
      } else if (userModel.role == 'rider') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RiderDashboardScreen()),
        );
      } else if (userModel.role == 'customer') {
        Navigator.pushReplacementNamed(context, '/home');
      } else if (userModel.role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      } else {
        await _authService.signOut();
        if (!mounted) return;
        TopSnackbar.show(
          context,
          message: 'User role not found or invalid.',
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

  Future<void> _handleForgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      TopSnackbar.show(
        context,
        message: 'Enter your email first',
        type: SnackbarType.warning,
      );
      return;
    }
    try {
      await _authService.sendPasswordReset(email);
      if (mounted) {
        TopSnackbar.show(
          context,
          message: 'Password reset email sent',
          type: SnackbarType.success,
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
    }
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Widget _staggered(int index, Widget child) {
    return FadeTransition(
      opacity: _fadeAnims[index],
      child: SlideTransition(position: _slideAnims[index], child: child),
    );
  }

  void _showStaffPortalSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.only(
          top: 16,
          bottom: 48,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Select Staff Portal',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 32),
            _buildPortalButton(
              context,
              title: 'Agent Portal',
              subtitle: 'Manage live customer support',
              icon: Icons.support_agent_rounded,
              color: Colors.blue,
              portalType: 'agent',
            ),
            const SizedBox(height: 16),
            _buildPortalButton(
              context,
              title: 'Supervisor Portal',
              subtitle: 'System overview and analytics',
              icon: Icons.security_rounded,
              color: Colors.deepPurple,
              portalType: 'supervisor',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortalButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String portalType,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          SlidePageRoute(page: AdminLoginScreen(portalType: portalType)),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(20),
          color: color.withOpacity(0.04),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Logo ──
                  _staggered(
                    0,
                    Hero(
                      tag: 'ceylon-logo',
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.07),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.delivery_dining,
                          size: 52,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Title ──
                  _staggered(
                    1,
                    const Text(
                      'Ceylon Dash',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // ── Subtitle ──
                  _staggered(
                    2,
                    Text(
                      'Sign in to continue',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Email ──
                  _staggered(3, EmailInputField(controller: _emailCtrl)),
                  const SizedBox(height: 16),

                  // ── Password ──
                  _staggered(
                    4,
                    PasswordInputField(
                      controller: _passwordCtrl,
                      showRequirements: false,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Remember / Forgot ──
                  _staggered(
                    5,
                    Row(
                      children: [
                        SizedBox(
                          height: 28,
                          width: 28,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (v) =>
                                setState(() => _rememberMe = v ?? false),
                            activeColor: Theme.of(context).primaryColor,
                            side: BorderSide(color: Colors.grey.shade400),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Remember me',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _handleForgotPassword,
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(
                              color: Colors.cyan,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Buttons ──
                  _staggered(
                    6,
                    Column(
                      children: [
                        CustomButton(
                          text: 'Sign In',
                          isLoading: _isLoading,
                          onPressed: _handleLogin,
                        ),
                        const SizedBox(height: 12),
                        CustomButton(
                          text: 'Staff Login',
                          isOutlined: true,
                          icon: Icons.admin_panel_settings_outlined,
                          onPressed: () => _showStaffPortalSheet(context),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account?",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                SlidePageRoute(
                                  page: const RoleSelectionScreen(),
                                ),
                              ),
                              child: const Text(
                                'Register',
                                style: TextStyle(
                                  color: Colors.cyan,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
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
          ),
        ),
      ),
    );
  }
}
