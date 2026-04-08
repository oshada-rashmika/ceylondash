import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/user_model.dart';
import '../services/database_service.dart';
import '../utils/validators.dart';
import '../widgets/email_input_field.dart';
import '../widgets/top_snackbar.dart';
import '../widgets/slide_page_route.dart';
import 'map_selection_screen.dart';
import 'settings_screen.dart';
import 'leaderboard_dashboard_screen.dart';

class SellerProfileScreen extends StatefulWidget {
  const SellerProfileScreen({super.key});

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();

  StreamSubscription<UserModel?>? _userSub;
  UserModel? _user;
  bool _loading = true;
  bool _isSigningOut = false;

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
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _bindUser();
  }

  void _bindUser() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    _userSub = _db.streamUser(uid).listen(
      (user) {
        if (!mounted) return;
        setState(() {
          _user = user;
          _loading = false;
        });
        if (!_animCtrl.isCompleted) _animCtrl.forward();
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _loading = false);
        TopSnackbar.show(
          context,
          message: 'Failed to load profile details.',
          type: SnackbarType.error,
        );
      },
    );
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  // ─── DISPLAY HELPERS ──────────────────────────────────────
  String get _businessInitials {
    final name = (_user?.businessName ?? _user?.name ?? '').trim();
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  String get _businessName {
    final name = (_user?.businessName ?? '').trim();
    return name.isEmpty ? 'My Business' : name;
  }

  String get _ownerName {
    final name = (_user?.name ?? '').trim();
    return name.isEmpty ? 'Seller' : name;
  }

  String get _displayEmail {
    final email =
        (_user?.email ?? FirebaseAuth.instance.currentUser?.email ?? '').trim();
    return email.isEmpty ? '—' : email;
  }

  String get _displayPhone {
    final phone = (_user?.phone ?? '').trim();
    return phone.isEmpty ? '—' : phone;
  }

  String get _displayAddress {
    final businessAddress = _user?.businessAddress?.trim() ?? '';
    if (businessAddress.isNotEmpty) return businessAddress;
    final address = _user?.address?.trim() ?? '';
    if (address.isNotEmpty) return address;
    return 'Add business address';
  }

  String get _displaySocials {
    final socials = (_user?.socials ?? '').trim();
    return socials.isEmpty ? 'Add social link' : socials;
  }

  int get _trustScore => _user?.trustScore ?? 0;

  // ─── UPDATE HELPERS ───────────────────────────────────────
  Future<void> _updateUserFields(
    Map<String, dynamic> fields, {
    required String successMessage,
    required String errorMessage,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        TopSnackbar.show(
          context,
          message: 'You need to be logged in to update your profile.',
          type: SnackbarType.error,
        );
      }
      return;
    }
    try {
      await _db.updateUserFields(uid, fields);
      if (mounted) {
        TopSnackbar.show(
          context,
          message: successMessage,
          type: SnackbarType.success,
        );
      }
    } catch (_) {
      if (mounted) {
        TopSnackbar.show(
          context,
          message: errorMessage,
          type: SnackbarType.error,
        );
      }
    }
  }

  // ─── EDIT SHEETS ──────────────────────────────────────────
  void _showEditBusinessNameSheet() {
    final ctrl = TextEditingController(text: _user?.businessName ?? '');
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
          child: _buildSheetContainer(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetHandle(),
                  const SizedBox(height: 24),
                  const Text(
                    'Update Business Name',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: ctrl,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Business name is required';
                      }
                      return null;
                    },
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: _inputDecoration(labelText: 'Business Name'),
                  ),
                  const SizedBox(height: 24),
                  _sheetButton(
                    label: 'Save',
                    saving: saving,
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      setSheetState(() => saving = true);
                      await _updateUserFields(
                        {'businessName': ctrl.text.trim()},
                        successMessage: 'Business name updated!',
                        errorMessage: 'Failed to update business name.',
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
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

  void _showEditOwnerNameSheet() {
    final ctrl = TextEditingController(text: _user?.name ?? '');
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
          child: _buildSheetContainer(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetHandle(),
                  const SizedBox(height: 24),
                  const Text(
                    'Update Owner Name',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: ctrl,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Owner name is required';
                      }
                      return null;
                    },
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: _inputDecoration(labelText: 'Owner Name'),
                  ),
                  const SizedBox(height: 24),
                  _sheetButton(
                    label: 'Save',
                    saving: saving,
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      setSheetState(() => saving = true);
                      await _updateUserFields(
                        {'name': ctrl.text.trim()},
                        successMessage: 'Owner name updated!',
                        errorMessage: 'Failed to update owner name.',
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
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
          child: _buildSheetContainer(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetHandle(),
                  const SizedBox(height: 24),
                  const Text(
                    'Update Phone Number',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildPhoneField(phoneCtrl),
                  const SizedBox(height: 24),
                  _sheetButton(
                    label: 'Save Phone',
                    saving: saving,
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      setSheetState(() => saving = true);
                      final digits =
                          Validators.extractPhoneDigits(phoneCtrl.text.trim());
                      await _updateUserFields(
                        {'phone': '+94$digits'},
                        successMessage: 'Phone number updated!',
                        errorMessage: 'Failed to update phone number.',
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
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
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
      decoration: _inputDecoration(
        labelText: 'Phone Number',
        hintText: 'XX XXX XXXX',
        prefixIcon: Container(
          padding: const EdgeInsets.only(left: 16, right: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.cyan.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+94',
                  style: TextStyle(
                    color: Colors.cyan.shade700,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 1.5,
                height: 28,
                color: Colors.black.withValues(alpha: 0.08),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditEmailSheet() {
    final emailCtrl = TextEditingController(
      text: _displayEmail == '—' ? '' : _displayEmail,
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
          child: _buildSheetContainer(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetHandle(),
                  const SizedBox(height: 24),
                  const Text(
                    'Update Email',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'A verification link will be sent to your new email. '
                    'You will be signed out after the update.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  EmailInputField(controller: emailCtrl),
                  const SizedBox(height: 24),
                  _sheetButton(
                    label: 'Update Email',
                    saving: saving,
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;

                      final nextEmail = emailCtrl.text.trim();
                      if (nextEmail == _displayEmail) {
                        TopSnackbar.show(
                          context,
                          message: 'Please enter a different email address.',
                          type: SnackbarType.error,
                        );
                        return;
                      }

                      setSheetState(() => saving = true);
                      if (ctx.mounted) Navigator.pop(ctx);
                      await _performEmailUpdate(nextEmail);
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
    if (user == null) {
      if (mounted) {
        TopSnackbar.show(
          context,
          message: 'You need to be logged in to update your email.',
          type: SnackbarType.error,
        );
      }
      return;
    }
    try {
      await user.verifyBeforeUpdateEmail(newEmail);
      await _db.updateUserFields(user.uid, {'email': newEmail});
      await FirebaseAuth.instance.signOut();

      TopSnackbar.schedulePending(
        message:
            'Verification email sent to your new address. Please verify it before logging in.',
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
          child: _buildSheetContainer(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetHandle(),
                  const SizedBox(height: 24),
                  const Text(
                    'Re-authenticate',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'For security, please enter your current password to continue.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: passwordCtrl,
                    obscureText: obscure,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      return null;
                    },
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: _inputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        color: Colors.black38,
                        size: 22,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: Colors.black38,
                          size: 22,
                        ),
                        onPressed: () {
                          setSheetState(() => obscure = !obscure);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _sheetButton(
                    label: 'Confirm',
                    saving: saving,
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;

                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null || user.email == null) {
                        TopSnackbar.show(
                          context,
                          message: 'Unable to re-authenticate this account.',
                          type: SnackbarType.error,
                        );
                        return;
                      }

                      setSheetState(() => saving = true);

                      try {
                        final credential = EmailAuthProvider.credential(
                          email: user.email!,
                          password: passwordCtrl.text,
                        );
                        await user.reauthenticateWithCredential(credential);
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
                      } catch (_) {
                        setSheetState(() => saving = false);
                        if (mounted) {
                          TopSnackbar.show(
                            context,
                            message: 'Authentication failed.',
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

  void _showEditAddressSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildSheetContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetHandle(),
            const SizedBox(height: 24),
            const Text(
              'Update Business Address',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Choose how you want to update your business location.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 28),
            _AddressOptionTile(
              icon: Icons.edit_location_alt_rounded,
              title: 'Enter address manually',
              subtitle: 'Type and save your address',
              onTap: () {
                Navigator.pop(ctx);
                _showEditAddressTextSheet();
              },
            ),
            const SizedBox(height: 16),
            _AddressOptionTile(
              icon: Icons.map_rounded,
              title: 'Choose on map',
              subtitle: 'Pinpoint your exact location',
              onTap: () async {
                Navigator.pop(ctx);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MapSelectionScreen()),
                );
                if (!mounted || result == null) return;
                if (result is MapSelectionResult) {
                  await _saveAddress(
                    address: result.address,
                    latitude: result.latitude,
                    longitude: result.longitude,
                  );
                } else if (result is String && result.trim().isNotEmpty) {
                  await _saveAddress(address: result.trim());
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAddressTextSheet() {
    final currentAddress = (_user?.businessAddress?.isNotEmpty == true)
        ? _user!.businessAddress
        : _user?.address;
    final addressCtrl = TextEditingController(text: currentAddress ?? '');
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
          child: _buildSheetContainer(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetHandle(),
                  const SizedBox(height: 24),
                  const Text(
                    'Update Business Address',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: addressCtrl,
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Address is required';
                      }
                      if (value.trim().length < 8) {
                        return 'Please enter a more complete address';
                      }
                      return null;
                    },
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: _inputDecoration(
                      labelText: 'Business Address',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _sheetButton(
                    label: 'Save Address',
                    saving: saving,
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      setSheetState(() => saving = true);
                      await _saveAddress(address: addressCtrl.text.trim());
                      if (ctx.mounted) Navigator.pop(ctx);
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

  Future<void> _saveAddress({
    required String address,
    double? latitude,
    double? longitude,
  }) async {
    final payload = <String, dynamic>{'businessAddress': address};
    if (latitude != null) payload['latitude'] = latitude;
    if (longitude != null) payload['longitude'] = longitude;
    await _updateUserFields(
      payload,
      successMessage: 'Business address updated!',
      errorMessage: 'Failed to update address.',
    );
  }

  void _showEditSocialsSheet() {
    final ctrl = TextEditingController(
      text: _displaySocials == 'Add social link' ? '' : _displaySocials,
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
          child: _buildSheetContainer(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetHandle(),
                  const SizedBox(height: 24),
                  const Text(
                    'Update Socials',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Add your Instagram, Facebook, or website URL.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: ctrl,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter a link';
                      }
                      return null;
                    },
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: _inputDecoration(
                      labelText: 'Social Link',
                      prefixIcon: const Icon(
                        Icons.link_rounded,
                        color: Colors.black38,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _sheetButton(
                    label: 'Save',
                    saving: saving,
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      setSheetState(() => saving = true);
                      await _updateUserFields(
                        {'socials': ctrl.text.trim()},
                        successMessage: 'Socials updated!',
                        errorMessage: 'Failed to update socials.',
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
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

  // ─── SIGN OUT ─────────────────────────────────────────────
  Future<void> _signOut() async {
    if (_isSigningOut) return;

    final shouldSignOut = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              'Sign Out',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            content: const Text(
              'Are you sure you want to sign out from this account?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldSignOut) return;
    setState(() => _isSigningOut = true);

    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, '/login', (route) => false);
      }
    } catch (_) {
      if (mounted) {
        TopSnackbar.show(
          context,
          message: 'Failed to sign out. Please try again.',
          type: SnackbarType.error,
        );
        setState(() => _isSigningOut = false);
      }
    }
  }

  // ─── SHEET / INPUT WIDGETS ────────────────────────────────
  Widget _buildSheetContainer({required Widget child}) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration({
    required String labelText,
    String? hintText,
    bool alignLabelWithHint = false,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      alignLabelWithHint: alignLabelWithHint,
      hintStyle: TextStyle(
        color: Colors.black26,
        letterSpacing: hintText == null ? 0 : 2,
      ),
      labelStyle: const TextStyle(
        color: Colors.black45,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.08),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.cyan.shade600, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.shade400, width: 2),
      ),
    );
  }

  Widget _sheetHandle() => Container(
        width: 48,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(3),
        ),
      );

  Widget _sheetButton({
    required String label,
    required bool saving,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: saving ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyan.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: saving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  // ─── BUILD ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Colors.cyan.shade600),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          'Seller Profile',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Column(
              children: [
                const SizedBox(height: 16),
                // ── HEADER ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Business avatar
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.cyan.shade600,
                              Colors.cyan.shade900,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyan.withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _businessInitials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 10),
                            _buildSellerBadge(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // ── SCROLLABLE CONTENT ──
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── BUSINESS INFO ──
                          const Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 12),
                            child: Text(
                              'BUSINESS INFO',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.black38,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                _SellerInfoTile(
                                  icon: Icons.store_rounded,
                                  label: 'Business Name',
                                  value: _businessName,
                                  onEdit: _showEditBusinessNameSheet,
                                ),
                                _tileDivider(),
                                _SellerInfoTile(
                                  icon: Icons.person_rounded,
                                  label: 'Owner Name',
                                  value: _ownerName,
                                  onEdit: _showEditOwnerNameSheet,
                                ),
                                _tileDivider(),
                                _SellerInfoTile(
                                  icon: Icons.email_rounded,
                                  label: 'Email',
                                  value: _displayEmail,
                                  onEdit: _showEditEmailSheet,
                                ),
                                _tileDivider(),
                                _SellerInfoTile(
                                  icon: Icons.phone_rounded,
                                  label: 'Phone',
                                  value: _displayPhone,
                                  onEdit: _showEditPhoneSheet,
                                ),
                                _tileDivider(),
                                _SellerInfoTile(
                                  icon: Icons.location_on_rounded,
                                  label: 'Business Address',
                                  value: _displayAddress,
                                  onEdit: _showEditAddressSheet,
                                  allowExpandedText: true,
                                ),
                                _tileDivider(),
                                _SellerInfoTile(
                                  icon: Icons.link_rounded,
                                  label: 'Socials',
                                  value: _displaySocials,
                                  onEdit: _showEditSocialsSheet,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // ── BUSINESS STATS CARD ──
                          _buildStatsCard(),
                          const SizedBox(height: 24),
                          // ── LEADERBOARD OVERVIEW ──
                          _buildLeaderboardCard(),
                          const SizedBox(height: 24),
                          // ── ACCOUNT ──
                          const Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 12),
                            child: Text(
                              'ACCOUNT',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.black38,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          _SellerSettingsTile(
                            icon: Icons.settings_rounded,
                            label: 'Settings',
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.push(
                                context,
                                SlidePageRoute(
                                    page: const SettingsScreen()),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          _SellerSettingsTile(
                            icon: Icons.logout_rounded,
                            label: _isSigningOut
                                ? 'Signing Out...'
                                : 'Sign Out',
                            isDestructive: true,
                            onTap: _signOut,
                          ),
                          const SizedBox(height: 24),
                        ],
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

  Widget _tileDivider() => Divider(
        height: 1,
        color: Colors.grey.withValues(alpha: 0.2),
      );

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _businessName,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            letterSpacing: -0.8,
            height: 1.1,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          _ownerName,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black45,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSellerBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.cyan.shade400, Colors.cyan.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified_rounded,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          const Text(
            'Verified Seller',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.cyan.shade700, Colors.cyan.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.shade900.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.chart_bar_alt_fill,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Business Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: CupertinoIcons.shield_lefthalf_fill,
                  label: 'Trust Score',
                  value: '$_trustScore',
                ),
              ),
              Container(
                width: 1,
                height: 48,
                color: Colors.white.withValues(alpha: 0.15),
              ),
              Expanded(
                child: _StatItem(
                  icon: CupertinoIcons.cube_box_fill,
                  label: 'Status',
                  value: 'Active',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: const Center(
              child: Text(
                'CeylonDash Seller Partner',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── LEADERBOARD OVERVIEW CARD ─────────────────────────────
  Widget _buildLeaderboardCard() {
    // Demo leaderboard data
    const int sellerRank = 12;
    const int totalSellers = 240;
    const int totalDeliveries = 187;
    const double onTimeRate = 96.5;

    final List<Map<String, dynamic>> topSellers = [
      {'name': 'DailyMart LK', 'deliveries': 342, 'rank': 1},
      {'name': 'Island Threads', 'deliveries': 298, 'rank': 2},
      {'name': 'SpicePack Co.', 'deliveries': 261, 'rank': 3},
    ];

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          SlidePageRoute(page: const LeaderboardDashboardScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1A2E).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.amber,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Leaderboard Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'This Month',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.amber,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // ── Your Rank Banner ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.withValues(alpha: 0.12),
                    Colors.orange.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  // Rank circle
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '#$sellerRank',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Rank',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '#$sellerRank of $totalSellers sellers',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Progress ring
                  SizedBox(
                    width: 42,
                    height: 42,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: 1 - (sellerRank / totalSellers),
                          strokeWidth: 4,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.08),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.amber),
                        ),
                        const Text(
                          'Top\n5%',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.amber,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // ── Stats Row ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: _LeaderboardStat(
                    icon: CupertinoIcons.cube_box_fill,
                    label: 'Deliveries',
                    value: '$totalDeliveries',
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                Expanded(
                  child: _LeaderboardStat(
                    icon: CupertinoIcons.timer,
                    label: 'On-Time Rate',
                    value: '$onTimeRate%',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // ── Top Sellers List ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOP SELLERS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.35),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                ...topSellers.map((seller) {
                  final rank = seller['rank'] as int;
                  final medalColors = [
                    const Color(0xFFFFD700), // gold
                    const Color(0xFFC0C0C0), // silver
                    const Color(0xFFCD7F32), // bronze
                  ];
                  final medalColor = medalColors[rank - 1];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Medal
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: medalColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.workspace_premium_rounded,
                                color: medalColor,
                                size: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              seller['name'] as String,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            '${seller['deliveries']} deliveries',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
    );
  }
}

// ─── PRIVATE WIDGET: LEADERBOARD STAT ───────────────────────────
class _LeaderboardStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _LeaderboardStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white54, size: 18),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

// ─── PRIVATE WIDGET: STAT ITEM ──────────────────────────────
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

// ─── PRIVATE WIDGET: ADDRESS OPTION TILE ────────────────────
class _AddressOptionTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AddressOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_AddressOptionTile> createState() => _AddressOptionTileState();
}

class _AddressOptionTileState extends State<_AddressOptionTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(
      begin: 1,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        _ctrl.forward();
      },
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  color: Colors.cyan.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.black.withValues(alpha: 0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── PRIVATE WIDGET: INFO TILE ──────────────────────────────
class _SellerInfoTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onEdit;
  final bool allowExpandedText;

  const _SellerInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onEdit,
    this.allowExpandedText = false,
  });

  @override
  State<_SellerInfoTile> createState() => _SellerInfoTileState();
}

class _SellerInfoTileState extends State<_SellerInfoTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(
      begin: 1,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _isPlaceholder => [
        'My Business',
        'Add business address',
        'Add social link',
        '—',
      ].contains(widget.value);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onEdit == null
          ? null
          : (_) {
              HapticFeedback.lightImpact();
              _ctrl.forward();
            },
      onTapUp: widget.onEdit == null
          ? null
          : (_) {
              _ctrl.reverse();
              widget.onEdit!();
            },
      onTapCancel: widget.onEdit == null ? null : () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(color: Colors.transparent),
          child: Row(
            crossAxisAlignment: widget.allowExpandedText
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.cyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  widget.icon,
                  color: Colors.cyan.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: widget.allowExpandedText ? 2 : 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black45,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.value,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: _isPlaceholder
                              ? FontWeight.w500
                              : FontWeight.w700,
                          color: _isPlaceholder ? Colors.black45 : Colors.black,
                          letterSpacing: -0.2,
                          height: 1.35,
                        ),
                        maxLines: widget.allowExpandedText ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.onEdit != null) ...[
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    color: Colors.black.withValues(alpha: 0.6),
                    size: 20,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── PRIVATE WIDGET: SETTINGS TILE ──────────────────────────
class _SellerSettingsTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SellerSettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  State<_SellerSettingsTile> createState() => _SellerSettingsTileState();
}

class _SellerSettingsTileState extends State<_SellerSettingsTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(
      begin: 1,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foreground = widget.isDestructive ? Colors.red : Colors.black87;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        _ctrl.forward();
      },
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: widget.isDestructive
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.isDestructive
                        ? Colors.red.shade600
                        : Colors.black87,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: foreground,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: foreground.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
