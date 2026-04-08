import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../utils/validators.dart';
import '../widgets/email_input_field.dart';
import '../widgets/top_snackbar.dart';
import '../widgets/slide_page_route.dart';
import 'map_selection_screen.dart';
import 'promotions_screen.dart';
import 'settings_screen.dart';
import 'rider_delivery_history_screen.dart';
import 'leaderboard_dashboard_screen.dart';

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
      setState(() {
        _loading = false;
      });
      return;
    }

    _userSub = _db
        .streamUser(uid)
        .listen(
          (user) {
            if (!mounted) return;

            setState(() {
              _user = user;
              _loading = false;
            });

            if (!_animCtrl.isCompleted) {
              _animCtrl.forward();
            }
          },
          onError: (_) {
            if (!mounted) return;

            setState(() {
              _loading = false;
            });

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

  String get _initials {
    final name = (_user?.name ?? '').trim();
    if (name.isEmpty) return '?';

    final parts = name.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    return parts.first[0].toUpperCase();
  }

  String get _displayName {
    final name = (_user?.name ?? '').trim();
    return name.isEmpty ? 'Customer' : name;
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
    final address = _user?.address?.trim() ?? '';
    if (address.isNotEmpty) return address;

    final businessAddress = _user?.businessAddress?.trim() ?? '';
    if (businessAddress.isNotEmpty) return businessAddress;

    return 'No address yet';
  }

  String get _displayBirthday {
    final bday = (_user?.birthday ?? '').trim();
    return bday.isEmpty ? 'Add Birthday' : bday;
  }

  String get _displayGender {
    final gen = (_user?.gender ?? '').trim();
    return gen.isEmpty ? 'Select Gender' : gen;
  }

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

  Future<void> _saveAddress({
    required String address,
    double? latitude,
    double? longitude,
  }) async {
    final payload = <String, dynamic>{'address': address};

    if (latitude != null) {
      payload['latitude'] = latitude;
    }

    if (longitude != null) {
      payload['longitude'] = longitude;
    }

    await _updateUserFields(
      payload,
      successMessage: 'Address updated successfully!',
      errorMessage: 'Failed to update address.',
    );
  }

  Future<void> _savePhone(String phoneDigits) async {
    final digits = Validators.extractPhoneDigits(phoneDigits);

    await _updateUserFields(
      {'phone': '+94$digits'},
      successMessage: 'Phone number updated!',
      errorMessage: 'Failed to update phone number.',
    );
  }

  void _showEditAddressTextSheet() {
    final currentAddress = (_user?.address?.isNotEmpty == true)
        ? _user!.address
        : _user?.businessAddress;
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
                    'Update Address',
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
                      labelText: 'Full Address',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _sheetButton(
                    label: 'Save Address',
                    saving: saving,
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;

                      setSheetState(() {
                        saving = true;
                      });

                      await _saveAddress(address: addressCtrl.text.trim());

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
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

  void _showAddressOptionsSheet() {
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
              'Update Address',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Choose how you want to update your delivery location.',
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
                  MaterialPageRoute(builder: (_) => const MapSelectionScreen()),
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

                      setSheetState(() {
                        saving = true;
                      });

                      await _savePhone(phoneCtrl.text.trim());

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
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
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+94',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.8),
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

                      setSheetState(() {
                        saving = true;
                      });

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }

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

  void _showEditBirthdaySheet() {
    DateTime selectedDate = DateTime.now();
    if (_user?.birthday != null && _user!.birthday!.isNotEmpty) {
      try {
        selectedDate = DateFormat('MMMM d, yyyy').parse(_user!.birthday!);
      } catch (e) {
        // Fallback to now if parsing fails
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext builder) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        final formattedDate = DateFormat(
                          'MMMM d, yyyy',
                        ).format(selectedDate);
                        _updateUserFields(
                          {'birthday': formattedDate},
                          successMessage: 'Birthday updated successfully.',
                          errorMessage: 'Failed to update birthday.',
                        );
                        await NotificationService().requestAlarmPermission(
                          context,
                        );
                        NotificationService().scheduleBirthdayNotification(
                          _user?.name ?? 'User',
                          selectedDate,
                        );
                      },
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 250,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: selectedDate,
                  onDateTimeChanged: (DateTime newDate) {
                    selectedDate = newDate;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditGenderSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Select Gender'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _updateUserFields(
                {'gender': 'Male'},
                successMessage: 'Gender updated successfully.',
                errorMessage: 'Failed to update gender.',
              );
            },
            child: const Text('Male'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _updateUserFields(
                {'gender': 'Female'},
                successMessage: 'Gender updated successfully.',
                errorMessage: 'Failed to update gender.',
              );
            },
            child: const Text('Female'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _updateUserFields(
                {'gender': 'Prefer not to say'},
                successMessage: 'Gender updated successfully.',
                errorMessage: 'Failed to update gender.',
              );
            },
            child: const Text('Prefer not to say'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          isDefaultAction: true,
          child: const Text('Cancel'),
        ),
      ),
    );
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
                          setSheetState(() {
                            obscure = !obscure;
                          });
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

                      setSheetState(() {
                        saving = true;
                      });

                      try {
                        final credential = EmailAuthProvider.credential(
                          email: user.email!,
                          password: passwordCtrl.text,
                        );

                        await user.reauthenticateWithCredential(credential);

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }

                        await _performEmailUpdate(newEmail);
                      } on FirebaseAuthException catch (e) {
                        setSheetState(() {
                          saving = false;
                        });

                        if (mounted) {
                          TopSnackbar.show(
                            context,
                            message: e.message ?? 'Authentication failed.',
                            type: SnackbarType.error,
                          );
                        }
                      } catch (_) {
                        setSheetState(() {
                          saving = false;
                        });

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

  Future<void> _signOut() async {
    if (_isSigningOut) return;

    final shouldSignOut =
        await showDialog<bool>(
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

    setState(() {
      _isSigningOut = true;
    });

    try {
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (_) {
      if (mounted) {
        TopSnackbar.show(
          context,
          message: 'Failed to sign out. Please try again.',
          type: SnackbarType.error,
        );

        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }

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
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
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
          backgroundColor: Colors.black87,
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
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
          'Profile',
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF141E30), Color(0xFF243B55)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _initials,
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
                            _buildLuxuryHeader(),
                            const SizedBox(height: 12),
                            _buildTierBadge(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 12),
                            child: Text(
                              'PERSONAL INFO',
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
                                _InfoTile(
                                  icon: Icons.phone_rounded,
                                  label: 'Phone',
                                  value: _displayPhone,
                                  onEdit: _showEditPhoneSheet,
                                ),
                                Divider(
                                  height: 1,
                                  color: Colors.grey.withValues(alpha: 0.2),
                                ),
                                _InfoTile(
                                  icon: Icons.email_rounded,
                                  label: 'Email',
                                  value: _displayEmail,
                                  onEdit: _showEditEmailSheet,
                                ),
                                Divider(
                                  height: 1,
                                  color: Colors.grey.withValues(alpha: 0.2),
                                ),
                                _InfoTile(
                                  icon: Icons.location_on_rounded,
                                  label: 'Address',
                                  value: _displayAddress,
                                  onEdit: _showAddressOptionsSheet,
                                  allowExpandedText: true,
                                ),
                                Divider(
                                  height: 1,
                                  color: Colors.grey.withValues(alpha: 0.2),
                                ),
                                _InfoTile(
                                  icon: CupertinoIcons.gift_fill,
                                  label: 'Birthday',
                                  value: _displayBirthday,
                                  onEdit: _showEditBirthdaySheet,
                                ),
                                Divider(
                                  height: 1,
                                  color: Colors.grey.withValues(alpha: 0.2),
                                ),
                                _InfoTile(
                                  icon: CupertinoIcons.person_2_fill,
                                  label: 'Gender',
                                  value: _displayGender,
                                  onEdit: _showEditGenderSheet,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildPremiumCard(),
                          const SizedBox(height: 24),
                          if (_user?.role == 'rider' || _user?.role == 'customer') ...[
                            _buildLeaderboardCard(),
                            const SizedBox(height: 24),
                          ],
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
                          if (_user?.role == 'customer')
                            _SettingsTile(
                              icon: Icons.sell_rounded,
                              label: 'Promotions',
                              onTap: () {
                                if (_user == null) return;
                                Navigator.push(
                                  context,
                                  SlidePageRoute(
                                    page: PromotionsScreen(user: _user!),
                                  ),
                                );
                              },
                            ),
                          if (_user?.role == 'rider')
                            _SettingsTile(
                              icon: Icons.history_rounded,
                              label: 'Delivery History',
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.push(
                                  context,
                                  SlidePageRoute(page: const RiderDeliveryHistoryScreen()),
                                );
                              },
                            ),
                          _SettingsTile(
                            icon: Icons.settings_rounded,
                            label: 'Settings',
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.push(
                                context,
                                SlidePageRoute(page: const SettingsScreen()),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          _SettingsTile(
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

  Widget _buildLuxuryHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _displayName,
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            letterSpacing: -1.0,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _displayEmail,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black45,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTierBadge() {
    final tier = _user?.loyaltyTier ?? 'Bronze';
    List<Color> gradientColors;
    IconData icon;
    Color iconColor;

    switch (tier) {
      case 'Diamond':
        gradientColors = [const Color(0xFFB9F2FF), const Color(0xFF6DD5FA)];
        icon = CupertinoIcons.sparkles;
        iconColor = Colors.blue.shade800;
        break;
      case 'Gold':
        gradientColors = [const Color(0xFFFFD700), const Color(0xFFDAA520)];
        icon = CupertinoIcons.star_fill;
        iconColor = Colors.brown.shade800;
        break;
      case 'Silver':
        gradientColors = [const Color(0xFFE0E0E0), const Color(0xFF9E9E9E)];
        icon = CupertinoIcons.shield_fill;
        iconColor = Colors.grey.shade800;
        break;
      case 'Bronze':
      default:
        gradientColors = [const Color(0xFFCD7F32), const Color(0xFFA0522D)];
        icon = CupertinoIcons.rosette;
        iconColor = Colors.white;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: tier == 'Diamond'
            ? [
                BoxShadow(
                  color: const Color(0xFF6DD5FA).withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Text(
            '$tier Member',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: iconColor,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard() {
    final isPremium = _user?.isPremium ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF141E30), Color(0xFF243B55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF141E30).withValues(alpha: 0.3),
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
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.shield_lefthalf_fill,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'CeylonDash Premium',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isPremium
                ? 'Your premium subscription is active. Enjoy exclusive perks, zero delivery fees, and priority support.'
                : 'Unlock zero delivery fees, priority customer support, and exclusive lifestyle rewards.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                TopSnackbar.show(
                  context,
                  message: 'Premium portals are opening soon!',
                  type: SnackbarType.success,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isPremium
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white,
                foregroundColor: isPremium ? Colors.white : Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: isPremium
                      ? BorderSide(color: Colors.white.withValues(alpha: 0.2))
                      : BorderSide.none,
                ),
              ),
              child: Text(
                isPremium ? 'Manage Subscription' : 'Upgrade to Premium',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
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
    final bool isCustomer = _user?.role == 'customer';
    
    // Demo leaderboard data
    final int rank = isCustomer ? 6 : 12;
    final int totalCount = isCustomer ? 1500 : 240;
    final int activityCount = isCustomer ? 45 : 187;
    final String metric = isCustomer ? '12.5k' : '96.5%';
    final String metricLabel = isCustomer ? 'Points' : 'On-Time Rate';

    final List<Map<String, dynamic>> topList = isCustomer
        ? [
            {'name': 'Amal Silva', 'count': 89, 'rank': 1},
            {'name': 'Kasun Perera', 'count': 75, 'rank': 2},
            {'name': 'Nimal Fernando', 'count': 62, 'rank': 3},
          ]
        : [
            {'name': 'Anton Jayakody', 'count': 342, 'rank': 1},
            {'name': 'Amal Perera', 'count': 298, 'rank': 2},
            {'name': 'John Doe', 'count': 261, 'rank': 3},
          ];

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          SlidePageRoute(
              page: LeaderboardDashboardScreen(
            isRider: !isCustomer,
            isCustomer: isCustomer,
          )),
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
                      child: Center(
                        child: Text(
                          '#$rank',
                          style: const TextStyle(
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
                            '#$rank of $totalCount ${isCustomer ? "shoppers" : "riders"}',
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
                            value: 1 - (rank / totalCount),
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
                      label: isCustomer ? 'Orders' : 'Deliveries',
                      value: '$activityCount',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  Expanded(
                    child: _LeaderboardStat(
                      icon: isCustomer ? CupertinoIcons.star_fill : CupertinoIcons.timer,
                      label: metricLabel,
                      value: metric,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // ── Top List ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCustomer ? 'TOP BUYERS' : 'TOP RIDERS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.35),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...topList.map((person) {
                    final rank = person['rank'] as int;
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
                                person['name'] as String,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Text(
                              '${person['count']} ${isCustomer ? "orders" : "deliveries"}',
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
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.8),
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

class _InfoTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onEdit;
  final bool allowExpandedText;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onEdit,
    this.allowExpandedText = false,
  });

  @override
  State<_InfoTile> createState() => _InfoTileState();
}

class _InfoTileState extends State<_InfoTile>
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
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  widget.icon,
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.8),
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
                          fontWeight:
                              [
                                'Add Birthday',
                                'Select Gender',
                                'No address yet',
                              ].contains(widget.value)
                              ? FontWeight.w500
                              : FontWeight.w700,
                          color:
                              [
                                'Add Birthday',
                                'Select Gender',
                                'No address yet',
                              ].contains(widget.value)
                              ? Colors.black45
                              : Colors.black,
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

class _SettingsTile extends StatefulWidget {
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
  State<_SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<_SettingsTile>
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
