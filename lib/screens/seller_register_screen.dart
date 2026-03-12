import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class SellerRegisterScreen extends StatefulWidget {
  const SellerRegisterScreen({super.key});

  @override
  State<SellerRegisterScreen> createState() => _SellerRegisterScreenState();
}

class _SellerRegisterScreenState extends State<SellerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _dbService = DatabaseService();

  final _ownerNameCtrl = TextEditingController();
  final _businessNameCtrl = TextEditingController();
  final _businessAddressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _socialsCtrl = TextEditingController();
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
        name: _ownerNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        role: 'seller',
        fcmToken: '',
        email: _emailCtrl.text.trim(),
        businessName: _businessNameCtrl.text.trim(),
        businessAddress: _businessAddressCtrl.text.trim(),
        socials: _socialsCtrl.text.trim().isEmpty
            ? null
            : _socialsCtrl.text.trim(),
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
    _ownerNameCtrl.dispose();
    _businessNameCtrl.dispose();
    _businessAddressCtrl.dispose();
    _phoneCtrl.dispose();
    _socialsCtrl.dispose();
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
          'Seller Registration',
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
                const Icon(Icons.store_outlined, size: 56, color: Colors.cyan),
                const SizedBox(height: 24),

                CustomTextField(
                  controller: _ownerNameCtrl,
                  label: 'Owner Name',
                  validator: (v) =>
                      AuthService.validateRequired(v, 'Owner Name'),
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  controller: _businessNameCtrl,
                  label: 'Business Name',
                  validator: (v) =>
                      AuthService.validateRequired(v, 'Business Name'),
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  controller: _businessAddressCtrl,
                  label: 'Business Address',
                  validator: (v) =>
                      AuthService.validateRequired(v, 'Business Address'),
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  controller: _phoneCtrl,
                  label: 'Phone Number',
                  keyboardType: TextInputType.phone,
                  validator: AuthService.validatePhone,
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  controller: _socialsCtrl,
                  label: 'Socials (optional)',
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
                  text: 'Create Seller Account',
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
