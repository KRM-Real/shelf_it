# Shelf-It

**Inventory Management Flutter Application**

A comprehensive Flutter application for inventory management, stock tracking, and business analytics.

## Features

- 📱 **Cross-platform** - iOS, Android, and Web support
- 🔐 **Firebase Authentication** - Secure user login and registration
- 📊 **Real-time Database** - Cloud Firestore integration
- 📈 **Analytics Dashboard** - Business insights and reporting
- 📦 **Stock Management** - Add, edit, and track inventory
- 🔍 **Barcode Scanning** - Quick product identification
- 📄 **PDF Reports** - Generate and share inventory reports
- 👤 **User Profiles** - Customizable user accounts

## Recent Updates (Phase 1 - August 2025)

✅ **Critical Updates Completed:**
- Flutter SDK updated to 3.35.1
- Firebase dependencies migrated to v4.0.0+
- All async context issues resolved
- Modern Material Design components
- Enhanced performance and compatibility

## Tech Stack

- **Flutter** 3.35.1
- **Dart** 3.9.0
- **Firebase Core** 4.0.0
- **Cloud Firestore** 6.0.0
- **Firebase Auth** 6.0.1
- **Firebase Analytics** 12.0.0
- **FL Chart** 1.0.0

## Getting Started

This project is a starting point for a Flutter application focused on inventory management.

### Prerequisites

- Flutter SDK 3.35.1 or later
- Dart 3.9.0 or later
- Android Studio / VS Code
- Firebase project setup

### Installation

1. Clone the repository
```bash
git clone https://github.com/KRM-Real/shelf_it.git
cd shelf_it
```

2. Install dependencies
```bash
flutter pub get
```

3. **🔐 Configure Firebase (REQUIRED)**
   - See [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for detailed instructions
   - Add your `google-services.json` for Android
   - Add your `GoogleService-Info.plist` for iOS
   - **⚠️ DO NOT commit these files to version control!**

4. Run the application
```bash
flutter run
```

## 🔒 Security Notice

This project requires Firebase configuration files that contain sensitive API keys. These files are **NOT** included in the repository for security reasons. Please follow the setup guide in [FIREBASE_SETUP.md](FIREBASE_SETUP.md) to configure your own Firebase project.

## Project Structure

```
lib/
├── main.dart              # App entry point
├── login_screen.dart      # Authentication
├── dashboard_screen.dart  # Main dashboard
├── product_page.dart      # Product management
├── stock_level.dart       # Stock tracking
├── analytics.dart         # Business analytics
├── profile_page.dart      # User profile
└── ...
```

## Development Progress

- [x] **Phase 1**: Critical updates and modernization
- [ ] **Phase 2**: Code quality improvements and maintenance
- [ ] **Phase 3**: Environment setup and optimization
- [ ] **Phase 4**: Future enhancements and new features

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Material Design](https://material.io/)

## License

This project is licensed under the MIT License - see the LICENSE file for details.
