import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/customer_register_screen.dart';
import 'screens/seller_register_screen.dart';
import 'screens/rider_register_screen.dart';
import 'widgets/slide_page_route.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const CeylonDashApp());
}

class CeylonDashApp extends StatelessWidget {
  const CeylonDashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
            return const HomePlaceholderScreen();
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
          '/home': const HomePlaceholderScreen(),
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

class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Ceylon Dash',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.cyan),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Welcome to Ceylon Dash!',
          style: TextStyle(color: Colors.black87, fontSize: 20),
        ),
      ),
    );
  }
}
