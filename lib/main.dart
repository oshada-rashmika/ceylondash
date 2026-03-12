import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'services/database_service.dart';
import 'models/user_model.dart';
import 'models/order_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const CeylonDashApp());
}

class CeylonDashApp extends StatelessWidget {
  const CeylonDashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ceylon Dash',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TestDatabaseScreen(),
    );
  }
}

class TestDatabaseScreen extends StatelessWidget {
  const TestDatabaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();

    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Initialization Test')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              final dummyUser = UserModel(
                uid: 'test_user_123',
                name: 'Kamal Perera',
                phone: '+94771234567',
                role: 'customer',
                fcmToken: 'dummy_token',
              );
              await dbService.createUser(dummyUser);

              final dummyOrder = OrderModel(
                id: '',
                externalPlatformRef: 'DARAZ-TEST',
                sellerId: 'test_seller_456',
                customerId: 'test_user_123',
                courierId: 'courier_abc',
                status: 'processing',
                dropoffLocation: const GeoPoint(6.9271, 79.8612),
                dropoffAddress: '123 Galle Road, Colombo',
                verification: {
                  'isCustomerAway': false,
                  'type': 'qr',
                  'isGenerated': false
                },
                timestamps: {
                  'createdAt': FieldValue.serverTimestamp()
                },
              );
              await dbService.createOrder(dummyOrder);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Success! Check Firebase Console.')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          },
          child: const Text('Create Collections & Dummy Data'),
        ),
      ),
    );
  }
}