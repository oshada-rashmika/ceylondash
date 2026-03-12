import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class RiderRegisterScreen extends StatefulWidget {
  const RiderRegisterScreen({super.key});

  @override
  State<RiderRegisterScreen> createState() => _RiderRegisterScreenState();
}

class _RiderRegisterScreenState extends State<RiderRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _dbService = DatabaseService();

  final _nameCtrl = TextEditingController();
  final _courierCompanyCtrl = TextEditingController();
  final _nicCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

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
        phone: '',
        role: 'rider',
        fcmToken: '',
        email: _emailCtrl.text.trim(),
        courierCompany: _courierCompanyCtrl.text.trim(),
        nic: _nicCtrl.text.trim(),
        isAvailable: false,
      );
      await _dbService.createUser(user);

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthService.friendlyAuthError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _courierCompanyCtrl.dispose();
    _nicCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.cyan),
        elevation: 0,
        title: const Text(
          'Rider Registration',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(
                  Icons.two_wheeler_outlined,
                  size: 56,
                  color: Colors.cyan,
                ),
                const SizedBox(height: 24),

                CustomTextField(
                  controller: _nameCtrl,
                  label: 'Full Name',
                  validator: (v) => AuthService.validateRequired(v, 'Name'),
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  controller: _courierCompanyCtrl,
                  label: 'Courier Company',
                  validator: (v) =>
                      AuthService.validateRequired(v, 'Courier Company'),
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  controller: _nicCtrl,
                  label: 'NIC (National Identity Card)',
                  validator: (v) => AuthService.validateRequired(v, 'NIC'),
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  controller: _emailCtrl,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: AuthService.validateEmail,
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  controller: _passwordCtrl,
                  label: 'Password',
                  obscureText: _obscurePassword,
                  validator: AuthService.validatePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.cyan,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 24),

                CustomButton(
                  text: 'Create Rider Account',
                  isLoading: _isLoading,
                  onPressed: _handleRegister,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
