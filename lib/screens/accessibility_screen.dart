import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../widgets/top_snackbar.dart';

class AccessibilityScreen extends StatefulWidget {
  const AccessibilityScreen({super.key});

  @override
  State<AccessibilityScreen> createState() => _AccessibilityScreenState();
}

class _AccessibilityScreenState extends State<AccessibilityScreen> {
  final DatabaseService _db = DatabaseService();
  final AuthService _auth = AuthService();

  List<String> _selectedNeeds = [];
  bool _isLoading = false;
  bool _isFetchingUser = true;

  static const List<Map<String, dynamic>> _options = [
    {
      'label': 'Deaf / Hard of Hearing',
      'subtitle': 'Riders will text instead of calling you.',
      'icon': Icons.hearing_disabled_rounded,
    },
    {
      'label': 'Visually Impaired',
      'subtitle': 'Larger text and higher contrast controls.',
      'icon': Icons.visibility_off_rounded,
    },
    {
      'label': 'Mobility Needs',
      'subtitle': 'Riders will assist with heavy items.',
      'icon': Icons.accessible_forward_rounded,
    },
    {
      'label': 'Color Blindness',
      'subtitle': 'Optimised UI colour palette for you.',
      'icon': Icons.palette_outlined,
    },
    {
      'label': 'Neurodivergent Support',
      'subtitle': 'Simplified step-by-step checkout flow.',
      'icon': Icons.psychology_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentNeeds();
  }

  Future<void> _loadCurrentNeeds() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isFetchingUser = false);
      return;
    }
    final userModel = await _db.getUser(user.uid);
    if (mounted) {
      setState(() {
        _selectedNeeds = List<String>.from(userModel?.accessibilityNeeds ?? []);
        _isFetchingUser = false;
      });
    }
  }

  void _toggle(String label) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedNeeds.contains(label)) {
        _selectedNeeds.remove(label);
      } else {
        _selectedNeeds.add(label);
      }
    });
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);
    try {
      await _db.updateUserField(user.uid, {
        'accessibilityNeeds': _selectedNeeds,
      });
      if (mounted) {
        TopSnackbar.show(
          context,
          message: 'Preferences saved securely.',
          type: SnackbarType.success,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        TopSnackbar.show(
          context,
          message: 'Failed to save. Please try again.',
          type: SnackbarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Accessibility',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: _isFetchingUser
          ? const Center(child: CupertinoActivityIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    children: [
                      const Text(
                        'How can we assist you?',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your selections help Riders and Sellers provide a personalised experience — e.g., Riders will text instead of calling if you are Deaf.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black45,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),
                      ..._options.map((option) {
                        final label = option['label'] as String;
                        final subtitle = option['subtitle'] as String;
                        final icon = option['icon'] as IconData;
                        final isSelected = _selectedNeeds.contains(label);
                        return _buildOptionCard(
                          label: label,
                          subtitle: subtitle,
                          icon: icon,
                          isSelected: isSelected,
                        );
                      }),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                _buildSaveButton(),
              ],
            ),
    );
  }

  Widget _buildOptionCard({
    required String label,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _toggle(label),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.cyan.shade400 : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isSelected ? 0.05 : 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.cyan.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 22,
                      color: isSelected ? Colors.cyan.shade600 : Colors.black38,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.black87 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black45,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: isSelected
                        ? Icon(
                            Icons.check_circle_rounded,
                            key: const ValueKey('checked'),
                            color: Colors.cyan.shade500,
                            size: 26,
                          )
                        : Icon(
                            Icons.circle_outlined,
                            key: const ValueKey('unchecked'),
                            color: Colors.grey.shade300,
                            size: 26,
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

  Widget _buildSaveButton() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyan,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.cyan.withValues(alpha: 0.5),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text(
                  'Save Preferences',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
        ),
      ),
    );
  }
}
