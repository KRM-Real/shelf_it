# 📦 Shelf-It

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.35.1-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.9.0-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-4.0.0+-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

**A comprehensive cross-platform inventory management solution built with Flutter**

*Track inventory • Manage stock levels • Generate reports • Business analytics*

[🚀 Features](#-features) • [📸 Screenshots](#-screenshots) • [⚡ Quick Start](#-quick-start) • [📖 Documentation](#-documentation)

</div>

---

## 🌟 Overview

**Shelf-It** is a modern, cross-platform inventory management application designed for small to medium businesses. Built with Flutter and powered by Firebase, it provides real-time inventory tracking, comprehensive analytics, and seamless user experience across mobile and web platforms.

### 🎯 Perfect For
- **Retail Stores** - Track products, monitor stock levels
- **Warehouses** - Manage inventory across multiple locations  
- **Small Businesses** - Streamlined inventory control
- **E-commerce** - Sync online and offline inventory

---

## ✨ Features

### 📱 **Core Functionality**
- 🔐 **Secure Authentication** - Firebase-powered user management
- 📦 **Product Management** - Add, edit, and organize inventory items
- 📊 **Stock Level Tracking** - Real-time inventory monitoring
- 🔍 **Barcode Scanning** - Quick product identification and lookup
- 📈 **Analytics Dashboard** - Business insights and trend analysis
- 📄 **PDF Reports** - Generate and share inventory reports
- � **Real-time Sync** - Cloud-based data synchronization

### 🌐 **Cross-Platform Support**
- 📱 **Android** - Native mobile experience
- 🍎 **iOS** - Optimized for iPhone and iPad
- 💻 **Web** - Browser-based access
- 🖥️ **Desktop** - Windows, macOS, Linux support

### 🔧 **Advanced Features**
- 👤 **User Profiles** - Customizable user accounts with role management
- 🏷️ **Smart Categorization** - Organize products by categories and tags
- ⚠️ **Low Stock Alerts** - Automated notifications for inventory thresholds
- 📊 **Business Intelligence** - Sales trends and inventory analytics
- 🔄 **Backup & Restore** - Secure cloud data backup
- 🌙 **Dark Mode** - Modern UI with theme support

---

## 📸 Screenshots

<div align="center">

| Dashboard | Product Management | Analytics |
|-----------|-------------------|-----------|
| ![Dashboard](https://via.placeholder.com/300x500/1976D2/FFFFFF?text=Dashboard) | ![Products](https://via.placeholder.com/300x500/388E3C/FFFFFF?text=Products) | ![Analytics](https://via.placeholder.com/300x500/F57C00/FFFFFF?text=Analytics) |

| Stock Levels | Barcode Scanner | Reports |
|--------------|-----------------|---------|
| ![Stock](https://via.placeholder.com/300x500/7B1FA2/FFFFFF?text=Stock+Levels) | ![Scanner](https://via.placeholder.com/300x500/C62828/FFFFFF?text=Barcode+Scanner) | ![Reports](https://via.placeholder.com/300x500/00796B/FFFFFF?text=Reports) |

</div>

---

## ⚡ Quick Start

### Prerequisites

- **Flutter SDK** 3.35.1 or later
- **Dart** 3.9.0 or later
- **Android Studio** / **VS Code** with Flutter extensions
- **Firebase Account** (free tier available)

### 🚀 Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/KRM-Real/shelf_it.git
   cd shelf_it
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **🔐 Configure Firebase** (⚠️ **REQUIRED**)
   ```bash
   # Follow the detailed setup guide
   cat FIREBASE_SETUP.md
   ```
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Add your `google-services.json` for Android
   - Add your `GoogleService-Info.plist` for iOS
   - **⚠️ DO NOT commit these files to version control!**

4. **Run the application**
   ```bash
   # Debug mode
   flutter run
   
   # Release mode
   flutter run --release
   
   # Web
   flutter run -d chrome
   ```

### 🔒 Security Notice

This project requires Firebase configuration files containing sensitive API keys. These files are **NOT** included in the repository for security reasons. Please follow [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for secure configuration.

---

## 🏗️ Tech Stack

### **Frontend**
- **Flutter** 3.35.1 - Cross-platform UI framework
- **Dart** 3.9.0 - Programming language
- **Material Design 3** - Modern UI components

### **Backend & Services**
- **Firebase Core** 4.0.0 - Backend-as-a-Service platform
- **Cloud Firestore** 6.0.0 - NoSQL document database
- **Firebase Auth** 6.0.1 - Authentication service
- **Firebase Analytics** 12.0.0 - App analytics

### **Key Packages**
- **FL Chart** 1.0.0 - Beautiful charts and graphs
- **Barcode Scan2** 4.5.1 - QR/Barcode scanning
- **PDF** 3.11.3 - PDF generation and reports
- **Share Plus** 11.1.0 - Native sharing capabilities
- **Image Picker** 1.1.2 - Camera and gallery access

---

## 📁 Project Structure

```
lib/
├── main.dart                 # Application entry point
├── screens/
│   ├── login_screen.dart     # Authentication screen
│   ├── dashboard_screen.dart # Main dashboard
│   ├── product_page.dart     # Product management
│   ├── stock_level.dart      # Stock tracking
│   ├── analytics.dart        # Analytics dashboard
│   ├── profile_page.dart     # User profile
│   ├── order_page.dart       # Order management
│   └── add_item_screen.dart  # Add new items
├── models/                   # Data models
├── services/                 # Business logic
├── widgets/                  # Reusable UI components
└── utils/                    # Helper functions

android/                      # Android-specific code
├── app/
│   ├── build.gradle
│   └── google-services.json.example
ios/                         # iOS-specific code
web/                         # Web-specific code
```

---

## 🚀 Development Progress

- [x] **Phase 1**: ✅ Core functionality and Firebase integration
- [x] **Security**: ✅ API key protection and secure setup
- [ ] **Phase 2**: Code optimization and maintenance  
- [ ] **Phase 3**: Advanced features and UI improvements
- [ ] **Phase 4**: Multi-language support and enterprise features

### Recent Updates (August 2025)

#### ✅ **Phase 1 - Foundation Complete**
- ⬆️ Updated to Flutter 3.35.1 with latest dependencies
- 🔥 Migrated to Firebase v4.0.0+ with enhanced security
- 🔧 Fixed all async context issues and code quality problems
- 🎨 Implemented Material Design 3 components
- 🔐 Added comprehensive security measures

#### ✅ **Security Enhancements**
- 🛡️ Removed sensitive files from version control
- 📋 Created detailed Firebase setup documentation
- 🔒 Implemented secure development practices
- ⚠️ Added automated security checks

---

## 📖 Documentation

| Document | Description |
|----------|-------------|
| [FIREBASE_SETUP.md](FIREBASE_SETUP.md) | 🔐 Firebase configuration and security guide |
| [TODO.md](TODO.md) | 📋 Development roadmap and progress tracking |
| [CONTRIBUTING.md](#contributing) | 🤝 How to contribute to the project |

---

## 🤝 Contributing

We welcome contributions! Here's how you can help:

### **Getting Started**
1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Follow** the development setup in [Quick Start](#-quick-start)
4. **Make** your changes with proper tests
5. **Commit** with descriptive messages (`git commit -m 'Add amazing feature'`)
6. **Push** to your branch (`git push origin feature/amazing-feature`)
7. **Open** a Pull Request

### **Development Guidelines**
- 📝 Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- 🧪 Add tests for new features
- 📚 Update documentation for API changes
- 🔍 Ensure all tests pass before submitting

### **Areas We Need Help**
- 🌐 Internationalization (i18n) support
- 🎨 UI/UX improvements
- 📊 Advanced analytics features
- 🔧 Performance optimizations
- 📱 Platform-specific enhancements

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2025 KRM-Real

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
```

---

## 🌟 Support

### **Get Help**
- 📖 **Documentation**: Check our [setup guides](FIREBASE_SETUP.md)
- 🐛 **Bug Reports**: [Open an issue](https://github.com/KRM-Real/shelf_it/issues/new?template=bug_report.md)
- 💡 **Feature Requests**: [Request a feature](https://github.com/KRM-Real/shelf_it/issues/new?template=feature_request.md)
- 💬 **Discussions**: [Join our discussions](https://github.com/KRM-Real/shelf_it/discussions)

### **Show Your Support**
If this project helps you, please ⭐ **star this repository**!

---

## 🔗 Resources

- 📚 [Flutter Documentation](https://docs.flutter.dev/)
- 🔥 [Firebase Documentation](https://firebase.google.com/docs)
- 🎨 [Material Design 3](https://m3.material.io/)
- 📱 [Flutter Samples](https://flutter.dev/docs/cookbook)

---

<div align="center">

**Built with ❤️ using Flutter**

[⬆ Back to Top](#-shelf-it)

</div>
