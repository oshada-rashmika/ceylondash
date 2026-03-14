import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_links/app_links.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/cart_provider.dart';
import 'screens/login_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/customer_register_screen.dart';
import 'screens/seller_register_screen.dart';
import 'screens/rider_register_screen.dart';
import 'screens/seller_dashboard_screen.dart';
import 'screens/rider_dashboard_screen.dart';
import 'screens/verification_pending_screen.dart';
import 'screens/customer_dashboard_shell.dart';
import 'screens/profile_screen.dart';
import 'widgets/slide_page_route.dart';
import 'widgets/top_snackbar.dart';
import 'services/database_service.dart';
import 'models/user_model.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => CartProvider())],
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

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initDeepLinks();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Ceylon Dash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        primaryColor: Colors.cyan,
        colorScheme: const ColorScheme.light(
          primary: Colors.cyan,
          secondary: Colors.cyanAccent,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
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

  @override
  void initState() {
    super.initState();
    _userFuture = DatabaseService().getUser(widget.uid);
  }

  @override
  void didUpdateWidget(RoleRouterGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid) {
      _userFuture = DatabaseService().getUser(widget.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _userFuture,
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator(color: Colors.cyan)),
          );
        }
        if (userSnapshot.hasData && userSnapshot.data != null) {
          final role = userSnapshot.data!.role;
          if (role == 'seller') {
            return const SellerDashboardScreen();
          } else if (role == 'rider') {
            return const RiderDashboardScreen();
          }
          return const CustomerDashboardShell();
        }
        return const LoginScreen();
      },
    );
  }
}
