import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import '../utils/validators.dart';
import '../widgets/email_input_field.dart';
import '../widgets/top_snackbar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();

  StreamSubscription<UserModel?>? _userSub;
  UserModel? _user;
  bool _loading = true;

  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _slide = Tween(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _bindUser();
  }

  void _bindUser() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    _userSub = _db.streamUser(uid).listen((user) {
      if (!mounted) return;
      setState(() {
        _user = user;
        _loading = false;
      });
      if (!_animCtrl.isCompleted) _animCtrl.forward();
    });
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  String get _initials {
    final name = _user?.name ?? '';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  void _showEditPhoneSheet() {
    final raw = _user?.phone ?? '';
    final existing = raw.startsWith('+94')
        ? Validators.extractPhoneDigits(raw.substring(3))
        : Validators.extractPhoneDigits(raw);
    final phoneCtrl = TextEditingController(text: existing);
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetHandle(),
                  const SizedBox(height: 20),
                  const Text(
                    'Update Phone Number',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPhoneField(phoneCtrl),
                  const SizedBox(height: 20),
                  _sheetButton(
                    label: 'Save',
                    saving: saving,
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      setSheetState(() => saving = true);
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid == null) return;
                      final digits = Validators.extractPhoneDigits(
                        phoneCtrl.text,
                      );
                      try {
                        await _db.updateUserFields(uid, {
                          'phone': '+94$digits',
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          TopSnackbar.show(
                            context,
                            message: 'Phone number updated!',
                            type: SnackbarType.success,
                          );
                        }
                      } catch (_) {
                        setSheetState(() => saving = false);
                        if (mounted) {
                          TopSnackbar.show(
                            context,
                            message: 'Failed to update phone number.',
                            type: SnackbarType.error,
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField(TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(9),
      ],
      validator: Validators.validateSriLankaPhone,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
      ),
      decoration: InputDecoration(
        labelText: 'Phone Number',
        labelStyle: const TextStyle(
          color: Colors.black45,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintText: 'XX XXX XXXX',
        hintStyle: TextStyle(color: Colors.grey.shade400, letterSpacing: 1.5),
        prefixIcon: Container(
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.cyan.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '+94',
                  style: TextStyle(
                    color: Colors.cyan,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 24, color: Colors.grey.shade300),
            ],
          ),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.cyan, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
        errorStyle: TextStyle(color: Colors.red.shade400, fontSize: 12),
      ),
    );
  }

  void _showEditEmailSheet() {
    final emailCtrl = TextEditingController(
      text: _user?.email ?? FirebaseAuth.instance.currentUser?.email ?? '',
    );
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetHandle(),
                  const SizedBox(height: 20),
                  const Text(
                    'Update Email',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'A verification link will be sent to your new email. '
                    'You\'ll be signed out after updating.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.black45),
                  ),
                  const SizedBox(height: 20),
                  EmailInputField(controller: emailCtrl),
                  const SizedBox(height: 20),
                  _sheetButton(
                    label: 'Update Email',
                    saving: saving,
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      setSheetState(() => saving = true);
                      if (ctx.mounted) Navigator.pop(ctx);
                      _performEmailUpdate(emailCtrl.text.trim());
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _performEmailUpdate(String newEmail) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await user.verifyBeforeUpdateEmail(newEmail);
      await _db.updateUserFields(user.uid, {'email': newEmail});
      await FirebaseAuth.instance.signOut();

      TopSnackbar.schedulePending(
        message:
            'Verification email sent to your new address. '
            'Please verify it before logging in.',
      );
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        _showReauthSheet(newEmail);
      } else {
        if (mounted) {
          TopSnackbar.show(
            context,
            message: e.message ?? 'Email update failed.',
            type: SnackbarType.error,
          );
        }
      }
    } catch (_) {
      if (mounted) {
        TopSnackbar.show(
          context,
          message: 'Email update failed. Please try again.',
          type: SnackbarType.error,
        );
      }
    }
  }

  void _showReauthSheet(String newEmail) {
    final passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool saving = false;
    bool obscure = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetHandle(),
                  const SizedBox(height: 20),
                  const Text(
                    'Re-authenticate',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'For security, please enter your current '
                    'password to continue.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.black45),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: passwordCtrl,
                    obscureText: obscure,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Password is required' : null,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(
                        color: Colors.black45,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        color: Colors.black38,
                        size: 20,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: Colors.black38,
                          size: 20,
                        ),
                        onPressed: () =>
                            setSheetState(() => obscure = !obscure),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Colors.cyan,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.red.shade300),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.red.shade400,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sheetButton(
                    label: 'Confirm',
                    saving: saving,
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      setSheetState(() => saving = true);
                      try {
                        final user = FirebaseAuth.instance.currentUser!;
                        final cred = EmailAuthProvider.credential(
                          email: user.email!,
                          password: passwordCtrl.text,
                        );
                        await user.reauthenticateWithCredential(cred);
                        if (ctx.mounted) Navigator.pop(ctx);
                        await _performEmailUpdate(newEmail);
                      } on FirebaseAuthException catch (e) {
                        setSheetState(() => saving = false);
                        if (mounted) {
                          TopSnackbar.show(
                            context,
                            message: e.message ?? 'Authentication failed.',
                            type: SnackbarType.error,
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Widget _sheetHandle() => Container(
    width: 40,
    height: 4,
    decoration: BoxDecoration(
      color: Colors.black12,
      borderRadius: BorderRadius.circular(2),
    ),
  );

  Widget _sheetButton({
    required String label,
    required bool saving,
    required VoidCallback onPressed,
  }) => SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton(
      onPressed: saving ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.cyan,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: saving
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.cyan)),
      );
    }

    final name = _user?.name ?? 'Customer';
    final email =
        _user?.email ?? FirebaseAuth.instance.currentUser?.email ?? '—';
    final phone = _user?.phone ?? '—';
    final address = _user?.address ?? '—';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                _buildAvatar(),
                const SizedBox(height: 16),

                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(fontSize: 14, color: Colors.black45),
                ),
                const SizedBox(height: 24),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 10),
                          child: Text(
                            'Personal Info',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black38,
                            ),
                          ),
                        ),
                        _InfoTile(
                          icon: Icons.phone_rounded,
                          label: 'Phone',
                          value: phone,
                          onEdit: _showEditPhoneSheet,
                        ),
                        _InfoTile(
                          icon: Icons.email_rounded,
                          label: 'Email',
                          value: email,
                          onEdit: _showEditEmailSheet,
                        ),
                        _InfoTile(
                          icon: Icons.location_on_rounded,
                          label: 'Address',
                          value: address,
                        ),
                        const Spacer(),
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 10),
                          child: Text(
                            'Settings',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black38,
                            ),
                          ),
                        ),
                        _SettingsTile(
                          icon: Icons.lock_rounded,
                          label: 'Account Security',
                          onTap: () {},
                        ),
                        _SettingsTile(
                          icon: Icons.notifications_rounded,
                          label: 'Notifications',
                          onTap: () {},
                        ),
                        const SizedBox(height: 8),
                        _SettingsTile(
                          icon: Icons.logout_rounded,
                          label: 'Sign Out',
                          isDestructive: true,
                          onTap: _signOut,
                        ),
                        const SizedBox(height: 16),
                      ],
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

  Widget _buildAvatar() {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.cyan, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withAlpha(50),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipOval(
        child: Container(
          color: Colors.cyan,
          alignment: Alignment.center,
          child: Text(
            _initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 40,
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onEdit;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F7FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.cyan, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.black38,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (onEdit != null)
            GestureDetector(
              onTap: onEdit,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F7FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: Colors.cyan,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDestructive ? Colors.red : Colors.black87;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.cyan.withAlpha(30),
          highlightColor: Colors.cyan.withAlpha(15),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? Colors.red.withAlpha(18)
                        : const Color(0xFFE0F7FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive ? Colors.red : Colors.cyan,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: fg.withAlpha(100)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
