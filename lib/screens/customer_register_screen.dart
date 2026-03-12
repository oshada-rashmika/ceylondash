import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../utils/validators.dart';
import '../widgets/premium_text_field.dart';
import '../widgets/phone_input_field.dart';
import '../widgets/email_input_field.dart';
import '../widgets/password_input_field.dart';
import '../widgets/custom_button.dart';

class CustomerRegisterScreen extends StatefulWidget {
  const CustomerRegisterScreen({super.key});

  @override
  State<CustomerRegisterScreen> createState() => _CustomerRegisterScreenState();
}

class _CustomerRegisterScreenState extends State<CustomerRegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _dbService = DatabaseService();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;

  late final AnimationController _entranceCtrl;
  late final List<Animation<double>> _fades;
  late final List<Animation<Offset>> _slides;

  static const _count = 7;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fades = List.generate(_count, (i) {
      final s = i * 0.08;
      return CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(s, (s + 0.35).clamp(0, 1), curve: Curves.easeOut),
      );
    });
    _slides = List.generate(_count, (i) {
      final s = i * 0.08;
      return Tween(begin: const Offset(0, 0.12), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _entranceCtrl,
          curve: Interval(
            s,
            (s + 0.35).clamp(0, 1),
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });
    _entranceCtrl.forward();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final cred = await _authService.register(
        _emailCtrl.text,
        _passwordCtrl.text,
      );

      final user = UserModel(
        uid: cred.user!.uid,
        name: _nameCtrl.text.trim(),
        phone: '+94${_phoneCtrl.text.trim()}',
        role: 'customer',
        fcmToken: '',
        email: _emailCtrl.text.trim(),
      );
      await _dbService.createUser(user);

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AuthService.friendlyAuthError(e)),
            backgroundColor: Colors.black87,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _anim(
                  0,
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.cyan.withAlpha(18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      size: 40,
                      color: Colors.cyan,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _anim(
                  0,
                  const Text(
                    'Customer Registration',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                _anim(
                  1,
                  PremiumTextField(
                    controller: _nameCtrl,
                    label: 'Full Name',
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: Colors.black38,
                      size: 20,
                    ),
                    validator: (v) => Validators.validateRequired(v, 'Name'),
                  ),
                ),
                const SizedBox(height: 14),

                _anim(2, PhoneInputField(controller: _phoneCtrl)),
                const SizedBox(height: 14),

                _anim(
                  3,
                  PremiumTextField(
                    controller: _addressCtrl,
                    label: 'Address',
                    prefixIcon: const Icon(
                      Icons.location_on_outlined,
                      color: Colors.black38,
                      size: 20,
                    ),
                    validator: (v) => Validators.validateRequired(v, 'Address'),
                  ),
                ),
                const SizedBox(height: 14),

                _anim(4, EmailInputField(controller: _emailCtrl)),
                const SizedBox(height: 14),

                _anim(5, PasswordInputField(controller: _passwordCtrl)),
                const SizedBox(height: 28),

                _anim(
                  6,
                  CustomButton(
                    text: 'Create Account',
                    isLoading: _isLoading,
                    onPressed: _handleRegister,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
