# 🚀 CeylonDash - Multi-Role Delivery & E-Commerce Platform

<div align="center">
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-3.x-00B4AB?logo=dart)](https://dart.dev)
  [![Firebase](https://img.shields.io/badge/Firebase-Realtime-orange?logo=firebase)](https://firebase.google.com)
  [![License](https://img.shields.io/badge/License-MIT-green)](#license)

  **The ultimate multi-role platform where riders deliver, customers order, and sellers thrive.** 🛵📱🏪

</div>

---

## ✨ What Makes CeylonDash Special?

CeylonDash isn't just another delivery app—it's a **complete ecosystem** designed for Sri Lanka's vibrant delivery and e-commerce landscape. Whether you're a rider making quick deliveries, a customer craving convenience, or a seller scaling your business, CeylonDash has your back with real-time updates, seamless payments, and an experience that's genuinely *delightful* to use.

---

## 🎯 Core Features

### 🛵 **For Riders**
- 📍 Real-time delivery tracking with map integration
- 📊 Comprehensive delivery history and earnings dashboard
- 🔐 QR code scanning for order verification
- 📲 Instant notifications for new orders
- ⭐ Performance metrics and ratings

### 👥 **For Customers**
- 🛒 Intuitive shopping cart and checkout experience
- 💰 Multiple payment methods support
- 📦 Track orders in real-time
- 💬 Direct seller communication via chat
- 🎁 Personalized promotions and offers
- 🔍 Global search across multiple sellers

### 🏪 **For Sellers**
- 📈 Dashboard with sales analytics and metrics
- 🎯 Promotion management tools
- 💬 Chat with customers directly
- 📊 Order management interface
- 👤 Profile customization and branding

### 🌐 **Platform-Wide**
- 🔐 Secure role-based authentication (Firebase)
- 🔔 Smart notification system
- 🎨 Responsive UI for mobile, tablet, and web
- 🌙 Accessibility features for inclusive experience
- 💬 Real-time chat functionality

---

## 🏗️ Tech Stack

### Frontend
- **Framework**: Flutter 3.x with Dart 3.x
- **State Management**: BLoC Pattern
- **UI Components**: Custom widgets with Material Design

### Backend & Services
- **Backend**: Firebase (Realtime Database, Cloud Firestore)
- **Authentication**: Firebase Auth
- **Notifications**: Firebase Cloud Messaging
- **Hosting**: Firebase Hosting

### Platform Support
- 📱 iOS (11+)
- 🤖 Android (5.0+)
- 🌐 Web
- 💻 macOS & Linux

---

## 🚀 Quick Start

### Prerequisites
- Flutter 3.x ([Install Flutter](https://flutter.dev/docs/get-started/install))
- Dart 3.x (comes with Flutter)
- Firebase account ([Create one here](https://firebase.google.com))

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/ceylondash.git
   cd ceylondash
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Update `lib/firebase_options.dart` with your Firebase credentials
   - Update `android/app/google-services.json` (Android)
   - Configure Firestore rules in `firestore.rules`

4. **Run the app**
   ```bash
   flutter run
   ```

---

## 📁 Project Structure

```
ceylondash/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── firebase_options.dart     # Firebase configuration
│   ├── blocs/                    # BLoC state management
│   ├── features/                 # Feature modules (chat, etc.)
│   ├── models/                   # Data models
│   ├── providers/                # State providers
│   ├── screens/                  # UI screens for all roles
│   ├── services/                 # Backend services
│   ├── utils/                    # Helper utilities
│   └── widgets/                  # Reusable components
├── android/                      # Android native code
├── ios/                          # iOS native code
├── web/                          # Web version
├── macos/                        # macOS version
├── linux/                        # Linux version
├── pubspec.yaml                  # Dependencies
├── firebase.json                 # Firebase config
├── firestore.indexes.json        # Firestore indexes
└── firestore.rules               # Firestore security rules
```

---

## 🔧 Configuration

### Environment Setup
- Update Firebase credentials in `firebase_options.dart`
- Configure Firestore indexes for optimal performance
- Set up authentication providers in Firebase Console

### Security
- Review and customize `firestore.rules` for your use case
- Implement proper role-based access control (RBAC)
- Use environment variables for sensitive data

---

## 📱 Available Screens

### Authentication
- `LoginScreen` - User authentication
- `RoleSelectionScreen` - Rider/Customer/Seller selection
- `CustomerRegisterScreen` - Customer signup
- `RiderRegisterScreen` - Rider signup
- `SellerRegisterScreen` - Seller signup

### Dashboards
- `CustomerDashboardShell` - Customer main interface
- `RiderDashboardScreen` - Rider operations
- `SellerDashboardScreen` - Seller management

### Commerce
- `CartScreen` - Shopping cart
- `CheckoutScreen` - Secure payment
- `PaymentMethodScreen` - Payment options
- `OrderDetailScreen` - Order tracking
- `PromotionsScreen` - Deals & offers

### Communication
- `ChatListScreen` - Conversations overview
- `ChatHistoryScreen` - Chat details
- `ReadOnlyChatScreen` - View-only mode

### Plus much more! Explore the `screens/` directory for the complete list.

---

## 🎮 Usage Examples

### For Customers
1. Register with email and location
2. Browse nearby sellers
3. Add items to cart
4. Complete checkout with preferred payment
5. Track delivery in real-time
6. Rate and review

### For Riders
1. Sign up and verify identity
2. Set availability status
3. Receive new orders
4. Scan QR codes for verification
5. Complete deliveries
6. View earnings dashboard

### For Sellers
1. Register and set up shop profile
2. Manage inventory (via orders)
3. Create and manage promotions
4. Chat with customers
5. Monitor sales and analytics

---

## 🚦 Development Workflow

### Running on Specific Platforms
```bash
# iOS
flutter run -d ios

# Android
flutter run -d android

# Web
flutter run -d web

# macOS
flutter run -d macos
```

### Building for Production
```bash
# Android APK
flutter build apk

# iOS build
flutter build ios

# Web build
flutter build web
```

---

## 🐛 Troubleshooting

### Common Issues

**Firebase Configuration Error**
- Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are properly placed
- Verify Firebase project ID matches your configuration

**Build Errors**
- Run `flutter clean` and `flutter pub get`
- Check that all dependencies are compatible with your Flutter version

**Hot Reload Issues**
- Kill the app and rebuild with `flutter run`

---

## 🤝 Contributing

We ❤️ contributions! Here's how you can help:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code Standards
- Follow Dart style guidelines
- Write meaningful commit messages
- Add tests for new features
- Update documentation

---

## 📚 Documentation

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Dart Language Guide](https://dart.dev/guides)

---

## 📈 Roadmap

- [ ] Push notifications enhancements
- [ ] AI-powered recommendation engine
- [ ] Advanced analytics dashboard
- [ ] Multi-language support
- [ ] Offline mode for key features
- [ ] Voice-based ordering
- [ ] Sustainability metrics tracking

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙌 Acknowledgments

- Built with ❤️ using [Flutter](https://flutter.dev)
- Powered by [Firebase](https://firebase.google.com)
- Inspired by the vibrant startup ecosystem of Sri Lanka

---

## 📞 Support & Contact

- 📧 Email: support@ceylondash.com
- 💬 Discord: [Join our community](https://discord.gg/ceylondash)
- 🐦 Twitter: [@CeylonDash](https://twitter.com/ceylondash)

---

<div align="center">
  
  **Made with 🎨 and ☕ in Sri Lanka**
  
  *If you found this helpful, please consider starring the repository!* ⭐
  
</div>