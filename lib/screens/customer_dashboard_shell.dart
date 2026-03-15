import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'customer_dashboard_screen.dart';
import 'chat_list_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'accessibility_screen.dart';
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
      const OrdersScreen(),
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
                  return Stack(
                    children: [
                      IgnorePointer(
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
                      ),
                      if (_menuAnim.value > 0)
                        Positioned(
                          bottom: 50,
                          left: 0,
                          right: 0,
                          child: SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: _buildRadialItems(),
                            ),
                          ),
                        ),
                    ],
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
        return Transform.rotate(
          angle: _menuAnim.value * math.pi / 4,
          child: FloatingActionButton(
            onPressed: _toggleMenu,
            backgroundColor: Theme.of(context).primaryColor,
            elevation: 4 + (4 * _menuAnim.value),
            shape: const CircleBorder(),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
          ),
        );
      },
    );
  }

  List<Widget> _buildRadialItems() {
    final icons = [
      Icons.accessibility_new_rounded,
      Icons.settings_rounded,
      Icons.support_agent_rounded,
    ];

    final labels = ['Accessibility', 'Settings', 'Support'];

    return List.generate(3, (index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned(
                right: (MediaQuery.of(context).size.width / 2) + 26,
                child: Transform.scale(
                  scale: _menuAnim.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
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
                ),
              ),
              Transform.scale(
                scale: _menuAnim.value,
                child: FloatingActionButton.small(
                  heroTag: 'fab_vert_$index',
                  backgroundColor: Colors.white,
                  elevation: 2,
                  shape: const CircleBorder(),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _toggleMenu();
                    if (labels[index] == 'Settings') {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    } else if (labels[index] == 'Accessibility') {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => const AccessibilityScreen(),
                        ),
                      );
                    } else {
                      TopSnackbar.show(
                        context,
                        message: '${labels[index]} coming soon!',
                        type: SnackbarType.success,
                      );
                    }
                  },
                  child: Icon(
                    icons[index],
                    color: Theme.of(context).primaryColor,
                  ),
                ),
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
            const SizedBox(width: 48),
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
                color: isSelected
                    ? Theme.of(context).primaryColor.withOpacity(0.8)
                    : Colors.black45,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Theme.of(context).primaryColor.withOpacity(0.8)
                    : Colors.black45,
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
