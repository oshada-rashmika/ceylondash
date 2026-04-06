import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_links/app_links.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'providers/cart_provider.dart';
import 'providers/accessibility_provider.dart';
import 'screens/login_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/customer_register_screen.dart';
import 'screens/seller_register_screen.dart';
import 'screens/rider_register_screen.dart';
import 'screens/rider_dashboard_screen.dart';
import 'screens/verification_pending_screen.dart';
import 'screens/customer_dashboard_shell.dart';
import 'screens/profile_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'widgets/slide_page_route.dart';
import 'widgets/top_snackbar.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'models/user_model.dart';
import 'screens/seller_dashboard_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

late SharedPreferences prefs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  prefs = await SharedPreferences.getInstance();
  await NotificationService().initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => AccessibilityProvider()),
      ],
      child: const CeylonDashApp(),
    ),
  );
}

class CeylonDashApp extends StatefulWidget {
  const CeylonDashApp({super.key});

  @override
  State<CeylonDashApp> createState() => _CeylonDashAppState();
}

class _CeylonDashAppState extends State<CeylonDashApp> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;
  StreamSubscription<User?>? _authSub;
  String? _loadedUid;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initDeepLinks();
    _initAuthListener();
  }

  void _initAuthListener() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null && user.emailVerified && user.uid != _loadedUid) {
        _loadedUid = user.uid;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Provider.of<AccessibilityProvider>(
              context,
              listen: false,
            ).loadNeeds(user.uid);
          }
        });
      } else if (user == null) {
        _loadedUid = null;
        if (mounted) {
          Provider.of<AccessibilityProvider>(context, listen: false).clear();
        }
      }
    });
  }

  Future<void> _initDeepLinks() async {
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) _handleDeepLink(initialLink);
    } catch (_) {}
    _linkSub = _appLinks.uriLinkStream.listen(_handleDeepLink);
  }

  void _handleDeepLink(Uri uri) async {
    final user = FirebaseAuth.instance.currentUser;
    bool verified = false;
    if (user != null) {
      try {
        await user.reload();
        verified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
        await FirebaseAuth.instance.signOut();
      } catch (_) {
        await FirebaseAuth.instance.signOut();
      }
    }

    if (verified) {
      TopSnackbar.schedulePending(
        message: 'Email verified successfully! Please sign in.',
        type: SnackbarType.success,
      );
    }

    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessibilityProvider>(
      builder: (context, a11y, _) {
        final primaryColor = a11y.hasColorBlindness
            ? const Color(0xFF005DBA)
            : Colors.cyan;
        final colorScheme = a11y.hasColorBlindness
            ? const ColorScheme.light(
                primary: Color(0xFF005DBA),
                secondary: Color(0xFF0080FF),
                surface: Colors.white,
              )
            : const ColorScheme.light(
                primary: Colors.cyan,
                secondary: Colors.cyanAccent,
                surface: Colors.white,
              );

        final pageTransitions = a11y.needsNeuroSupport
            ? const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
                  TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
                },
              )
            : null;

        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Ceylon Dash',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
            primaryColor: primaryColor,
            colorScheme: colorScheme,
            pageTransitionsTheme:
                pageTransitions ??
                const PageTransitionsTheme(
                  builders: {
                    TargetPlatform.android: ZoomPageTransitionsBuilder(),
                    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                  },
                ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              elevation: 0,
              surfaceTintColor: Colors.white,
            ),
            snackBarTheme: SnackBarThemeData(
              backgroundColor: Colors.black87,
              contentTextStyle: const TextStyle(color: Colors.white),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          builder: (context, child) {
            final data = MediaQuery.of(context);
            return MediaQuery(
              data: data.copyWith(
                textScaler: a11y.isVisuallyImpaired
                    ? const TextScaler.linear(1.3)
                    : const TextScaler.linear(1.0),
                boldText: a11y.isVisuallyImpaired,
              ),
              child: child!,
            );
          },
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Colors.white,
                  body: Center(
                    child: CircularProgressIndicator(color: Colors.cyan),
                  ),
                );
              }
              if (snapshot.hasData) {
                if (snapshot.data!.emailVerified) {
                  return RoleRouterGate(uid: snapshot.data!.uid);
                }
                return const VerificationPendingScreen();
              }
              return const LoginScreen();
            },
          ),
          onGenerateRoute: (settings) {
            final routes = <String, Widget>{
              '/login': const LoginScreen(),
              '/admin-login': const AdminLoginScreen(),
              '/role-selection': const RoleSelectionScreen(),
              '/register/customer': const CustomerRegisterScreen(),
              '/register/seller': const SellerRegisterScreen(),
              '/register/rider': const RiderRegisterScreen(),
              '/verify-email': const VerificationPendingScreen(),
              '/home': const CustomerDashboardShell(),
              '/seller-dashboard': const SellerDashboardScreen(),
              '/rider-dashboard': const RiderDashboardScreen(),
              '/profile': const ProfileScreen(),
            };
            final page = routes[settings.name];
            if (page != null) {
              return SlidePageRoute(page: page);
            }
            return null;
          },
        );
      },
    );
  }
}

class RoleRouterGate extends StatefulWidget {
  final String uid;

  const RoleRouterGate({super.key, required this.uid});

  @override
  State<RoleRouterGate> createState() => _RoleRouterGateState();
}

class _RoleRouterGateState extends State<RoleRouterGate> {
  Future<UserModel?>? _userFuture;
  String? _cachedRole;

  @override
  void initState() {
    super.initState();
    _cachedRole = prefs.getString('user_role_${widget.uid}');
    if (_cachedRole == null) {
      _userFuture = DatabaseService().getUser(widget.uid);
    }
  }

  @override
  void didUpdateWidget(RoleRouterGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid) {
      _cachedRole = prefs.getString('user_role_${widget.uid}');
      if (_cachedRole == null) {
        _userFuture = DatabaseService().getUser(widget.uid);
      }
    }
  }

  Widget _routeByRole(String role) {
    if (role == 'seller') {
      return const SellerDashboardScreen();
    } else if (role == 'rider') {
      return const RiderDashboardScreen();
    } else if (role == 'admin') {
      return const AdminDashboardScreen();
    }
    return const CustomerDashboardShell();
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedRole != null) {
      return _routeByRole(_cachedRole!);
    }

    return FutureBuilder<UserModel?>(
      future: _userFuture,
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF9F9FB),
            body: Center(child: CircularProgressIndicator(color: Colors.cyan)),
          );
        }
        if (userSnapshot.hasData && userSnapshot.data != null) {
          final role = userSnapshot.data!.role;
          prefs.setString('user_role_${widget.uid}', role);
          return _routeByRole(role);
        }
        return const LoginScreen();
      },
    );
  }
}
