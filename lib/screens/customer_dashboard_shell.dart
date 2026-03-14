// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'customer_dashboard_screen.dart';
import 'chat_list_screen.dart';
import 'quick_actions_screen.dart';
import 'profile_screen.dart';
import '../widgets/top_snackbar.dart';

class CustomerDashboardShell extends StatefulWidget {
  const CustomerDashboardShell({super.key});

  @override
  State<CustomerDashboardShell> createState() => _CustomerDashboardShellState();
}

class _CustomerDashboardShellState extends State<CustomerDashboardShell>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  late final AnimationController _menuCtrl;
  late final Animation<double> _menuAnim;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _menuCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _menuAnim = CurvedAnimation(
      parent: _menuCtrl,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInBack,
    );
  }

  @override
  void dispose() {
    _menuCtrl.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (_currentIndex == index) return;
    if (_isMenuOpen) _toggleMenu();
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
  }

  void _toggleMenu() {
    HapticFeedback.lightImpact();
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      if (_isMenuOpen) {
        _menuCtrl.forward();
      } else {
        _menuCtrl.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const CustomerDashboardScreen(),
      const QuickActionsScreen(),
      ChatListScreen(isActive: _currentIndex == 2),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF9F9FB),
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: screens),
          if (_isMenuOpen || _menuCtrl.isAnimating)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _menuCtrl,
                builder: (context, child) {
                  return IgnorePointer(
                    ignoring: !_isMenuOpen,
                    child: GestureDetector(
                      onTap: _toggleMenu,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 5.0 * _menuCtrl.value,
                          sigmaY: 5.0 * _menuCtrl.value,
                        ),
                        child: Container(
                          color: Colors.black.withOpacity(
                            0.3 * _menuCtrl.value,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildRadialFab(),
      bottomNavigationBar: _buildBottomAppBar(),
    );
  }

  Widget _buildRadialFab() {
    return AnimatedBuilder(
      animation: _menuAnim,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            ..._buildRadialItems(),
            Transform.rotate(
              angle: _menuAnim.value * math.pi / 4,
              child: FloatingActionButton(
                onPressed: _toggleMenu,
                backgroundColor: Colors.cyan,
                elevation: 4 + (4 * _menuAnim.value),
                shape: const CircleBorder(),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildRadialItems() {
    if (_menuAnim.value == 0) return [];

    final double radius = 100.0;
    final angles = [-5 * math.pi / 6, -math.pi / 2, -math.pi / 6];
    final icons = [
      Icons.support_agent_rounded,
      Icons.settings_rounded,
      Icons.accessibility_new_rounded,
    ];

    final labels = [
      'Support',
      'Settings',
      'Accessibility',
    ];

    return List.generate(3, (index) {
      final theta = angles[index];
      final double dx = math.cos(theta) * radius * _menuAnim.value;
      final double dy = math.sin(theta) * radius * _menuAnim.value;

      return Transform.translate(
        offset: Offset(dx, dy),
        child: Transform.scale(
          scale: _menuAnim.value,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  labels[index],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FloatingActionButton.small(
                heroTag: 'fab_rad_$index',
                backgroundColor: Colors.white,
                elevation: 4,
                shape: const CircleBorder(),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _toggleMenu();
                  TopSnackbar.show(
                    context,
                    message: '${labels[index]} coming soon!',
                    type: SnackbarType.success,
                  );
                },
                child: Icon(icons[index], color: Colors.cyan.shade700),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildBottomAppBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 16,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    Icons.space_dashboard_outlined,
                    Icons.space_dashboard_rounded,
                    0,
                    'Home',
                  ),
                  _buildNavItem(
                    Icons.receipt_long_outlined,
                    Icons.receipt_long_rounded,
                    1,
                    'Orders',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 48), // Cutout space
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    Icons.chat_bubble_outline_rounded,
                    Icons.chat_rounded,
                    2,
                    'Chat',
                  ),
                  _buildNavItem(
                    Icons.person_outline_rounded,
                    Icons.person_rounded,
                    3,
                    'Profile',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    IconData activeIcon,
    int index,
    String label,
  ) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onNavTap(index),
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                size: 26,
                color: isSelected ? Colors.cyan.shade700 : Colors.black45,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.cyan.shade700 : Colors.black45,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
