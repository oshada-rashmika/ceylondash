import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/top_snackbar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricEnabled = false;
  bool _orderNotifications = true;
  bool _promoAlerts = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _safePop() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _showChangePasswordBottomSheet() {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Change Password',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: currentPasswordController,
                      label: 'Current Password',
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: newPasswordController,
                      label: 'New Password',
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: confirmPasswordController,
                      label: 'Confirm Password',
                      obscureText: true,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (newPasswordController.text !=
                                  confirmPasswordController.text) {
                                TopSnackbar.show(
                                  context,
                                  message: 'New passwords do not match',
                                  type: SnackbarType.error,
                                );
                                return;
                              }
                              setState(() => isLoading = true);
                              try {
                                User? user = _auth.currentUser;
                                if (user != null && user.email != null) {
                                  AuthCredential credential =
                                      EmailAuthProvider.credential(
                                        email: user.email!,
                                        password:
                                            currentPasswordController.text,
                                      );
                                  await user.reauthenticateWithCredential(
                                    credential,
                                  );
                                  await user.updatePassword(
                                    newPasswordController.text,
                                  );
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  TopSnackbar.show(
                                    context,
                                    message: 'Password updated successfully',
                                  );
                                }
                              } on FirebaseAuthException catch (e) {
                                if (!context.mounted) return;
                                TopSnackbar.show(
                                  context,
                                  message: e.message ?? 'An error occurred',
                                  type: SnackbarType.error,
                                );
                              } finally {
                                if (context.mounted) {
                                  setState(() => isLoading = false);
                                }
                              }
                            },
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Save Password',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmLogout() {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel', style: TextStyle(color: Colors.blue)),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () async {
                HapticFeedback.heavyImpact();
                await AuthService().signOut();
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteAccount() {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'This action is highly destructive and cannot be undone. All your data will be permanently removed. Are you sure?',
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel', style: TextStyle(color: Colors.blue)),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () async {
                HapticFeedback.heavyImpact();
                try {
                  User? user = _auth.currentUser;
                  if (user != null) {
                    try {
                      await DatabaseService().deleteUserData(user.uid);
                    } catch (_) {}
                    await user.delete();
                    if (!context.mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  TopSnackbar.show(
                    context,
                    message: 'Error deleting account: \${e.toString()}',
                    type: SnackbarType.error,
                  );
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: const Color(0xFFF9F9F9),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8, top: 24),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    bool isDestructive = false,
    Color? overrideIconColor,
    VoidCallback? onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap != null
                ? () {
                    if (isDestructive) {
                      HapticFeedback.heavyImpact();
                    } else {
                      HapticFeedback.lightImpact();
                    }
                    onTap();
                  }
                : null,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDestructive
                          ? Colors.red.withValues(alpha: 0.1)
                          : (overrideIconColor != null
                                ? overrideIconColor.withValues(alpha: 0.1)
                                : const Color(0xFFE0F7FA)),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: isDestructive
                          ? Colors.red
                          : (overrideIconColor ?? Colors.cyan.shade700),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDestructive ? Colors.red : Colors.black,
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 56),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: Colors.grey.shade200,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: _safePop,
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
          _buildSection(
            title: 'SECURITY',
            children: [
              _buildTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey,
                ),
                onTap: _showChangePasswordBottomSheet,
              ),
              _buildTile(
                icon: Icons.fingerprint,
                title: 'Biometric Login',
                trailing: CupertinoSwitch(
                  value: _biometricEnabled,
                  activeTrackColor: Colors.cyan.shade600,
                  onChanged: (val) {
                    HapticFeedback.lightImpact();
                    setState(() => _biometricEnabled = val);
                  },
                ),
                showDivider: false,
              ),
            ],
          ),
          _buildSection(
            title: 'PREFERENCES',
            children: [
              _buildTile(
                icon: Icons.notifications_none_rounded,
                title: 'Order Notifications',
                trailing: CupertinoSwitch(
                  value: _orderNotifications,
                  activeTrackColor: Colors.cyan.shade600,
                  onChanged: (val) {
                    HapticFeedback.lightImpact();
                    setState(() => _orderNotifications = val);
                  },
                ),
              ),
              _buildTile(
                icon: Icons.campaign_outlined,
                title: 'Promotional Alerts',
                trailing: CupertinoSwitch(
                  value: _promoAlerts,
                  activeTrackColor: Colors.cyan.shade600,
                  onChanged: (val) {
                    HapticFeedback.lightImpact();
                    setState(() => _promoAlerts = val);
                  },
                ),
                showDivider: false,
              ),
            ],
          ),
          _buildSection(
            title: 'ACCOUNT ACTIONS',
            children: [
              _buildTile(
                icon: Icons.logout_rounded,
                title: 'Log Out',
                isDestructive: false,
                overrideIconColor: Colors.red,
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey,
                ),
                onTap: _confirmLogout,
              ),
              _buildTile(
                icon: Icons.person_remove_rounded,
                title: 'Delete Account',
                isDestructive: true,
                onTap: _confirmDeleteAccount,
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
