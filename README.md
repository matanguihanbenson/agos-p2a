# 🌊 AGOS - AI-Powered Water Quality Management

**AGOS** is an AI-powered mobile application that helps monitor, detect, and manage floating trash and water quality in rivers and inland waterways—making cleanup smarter, faster, and more effective.

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-039BE5?style=for-the-badge&logo=Firebase&logoColor=white)](https://firebase.google.com)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)

---

## 📑 Table of Contents

- [🎯 Overview](#-overview)
- [✨ Features](#-features)
- [🛠️ Tech Stack](#️-tech-stack)
- [📱 Screenshots](#-screenshots)
- [🚀 Getting Started](#-getting-started)
- [⚙️ Installation](#️-installation)
- [🏗️ Project Structure](#️-project-structure)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)

---

## 🎯 Overview

AGOS revolutionizes environmental monitoring by combining AI technology with real-time data collection to address water pollution challenges. The app enables users to:

- **Monitor** water quality in real-time
- **Detect** floating debris and pollutants
- **Manage** cleanup operations efficiently
- **Track** environmental impact over time

**Target Users:** Environmental agencies, field operators, researchers, and concerned citizens

---

## ✨ Features

### 🤖 AI-Powered Detection

- Real-time trash and debris detection
- Water quality analysis using AI algorithms
- Automated pollution reporting

### 📊 Data Management

- Live feed monitoring
- Interactive maps with heatmap visualization
- Charts and analytics for environmental data
- Historical data tracking

### 🚁 Bot Management

- Bot selection and assignment
- Remote bot control interface
- Scheduled cleanup operations
- Field operator management

### 👥 User Management

- Secure authentication with Firebase
- Role-based access (Admin, Field Operator)
- User profile management
- Team collaboration tools

### 📱 Mobile Features

- QR code scanning for bot identification
- GPS location services
- Offline data synchronization
- Push notifications

---

## 🛠️ Tech Stack

### **Frontend**

- **Flutter** - Cross-platform mobile development
- **Dart** - Programming language
- **Riverpod** - State management
- **Material Design** - UI components

### **Backend & Services**

- **Firebase Core** - Backend infrastructure
- **Firebase Auth** - User authentication
- **Cloud Firestore** - Real-time database
- **Firebase Realtime Database** - Live data sync

### **Maps & Visualization**

- **Flutter Map** - Interactive mapping
- **Heatmap** - Data visualization
- **FL Chart** - Charts and graphs
- **LatLong2** - Coordinate handling

### **Device Integration**

- **Geolocator** - GPS services
- **Mobile Scanner** - QR/Barcode scanning
- **Permission Handler** - Device permissions
- **URL Launcher** - External links

### **UI/UX**

- **Google Fonts** - Typography
- **Flutter SVG** - Vector graphics
- **Badges** - Notification indicators
- **Custom Theming** - Consistent design

---

## 📱 Screenshots

_Screenshots will be added here once the app UI is implemented_

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (^3.8.0)
- Dart SDK
- Android Studio / VS Code
- Git

### Quick Start

```bash
# Clone the repository
git clone <repository-url>
cd agos

# Install dependencies
flutter pub get

# Run the app
flutter run
```

---

## ⚙️ Installation

### 1. **Environment Setup**

```bash
# Verify Flutter installation
flutter doctor

# Enable required platforms
flutter config --enable-android
flutter config --enable-ios  # For iOS development
```

### 2. **Dependencies**

```bash
# Install all project dependencies
flutter pub get

# Generate launcher icons
flutter pub run flutter_launcher_icons:main
```

### 3. **Firebase Configuration**

1. Create a Firebase project
2. Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
3. Enable Authentication, Firestore, and Realtime Database

### 4. **Permissions**

The app requires the following permissions:

- Location access (GPS)
- Camera access (QR scanning)
- Internet connectivity
- Storage access

---

## 🏗️ Project Structure

```
agos/
├── lib/
│   ├── core/
│   │   └── theme/           # App theming
│   ├── data/
│   │   └── firebase_initializer.dart
│   ├── routes/
│   │   ├── app_routes.dart  # Route definitions
│   │   └── route_generator.dart
│   └── main.dart           # App entry point
├── assets/
│   ├── images/             # Image assets
│   └── icons/              # Icon assets
├── android/                # Android-specific files
├── ios/                    # iOS-specific files
└── pubspec.yaml           # Project dependencies
```

### **Key Routes**

- `/` - Splash screen
- `/login` - User authentication
- `/home` - Main dashboard
- `/live-feed` - Real-time monitoring
- `/bot-list` - Bot management
- `/bot-control` - Remote bot control

---

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### **Development Guidelines**

- Follow Flutter/Dart coding standards
- Write meaningful commit messages
- Add tests for new features
- Update documentation as needed

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📞 Support

For support and questions:

- Create an issue on GitHub
- Contact the development team
- Check the documentation

---

**Made with ❤️ for a cleaner environment**
