<div align="center">
  <img src="https://img.icons8.com/clouds/200/000000/android-os.png" alt="CleanAI Mobile App" width="150" height="150"/>
  <h1>📱 CleanAI - Mobile Application 📱</h1>
  <p><em>The ultimate on-demand cleaning service app for Clients and Workers, built with Flutter.</em></p>

  ![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?logo=Flutter&logoColor=white&style=for-the-badge)
  ![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?logo=dart&logoColor=white&style=for-the-badge)
  ![Android](https://img.shields.io/badge/Android-3DDC84?logo=android&logoColor=white&style=for-the-badge)
  ![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black&style=for-the-badge)
</div>

---

## 📖 Table of Contents

- [Introduction](#-introduction)
- [Main Features](#-main-features)
- [Technology Stack](#-technology-stack)
- [Project Structure](#-project-structure)
- [Installation & Setup](#-installation--setup)
- [Security](#-security)
- [Team](#-team)

---

## 🚀 Introduction

CleanAI is a cross-platform mobile application that provides a seamless, modern, and intuitive interface for booking cleaning services. The app empowers customers to find the best cleaners, while providing workers with tools to manage their tasks and earnings efficiently.

The frontend natively communicates with our ASP.NET Core Backend API and uses real-time SignalR sockets for live updates.

---

## ✨ Main Features

<table>
  <tr>
    <th>🧑‍💼 Client App</th>
    <th>👷 Worker App</th>
    <th>👑 Admin Features (View Only)</th>
  </tr>
  <tr>
    <td>
      <ul>
        <li>Secure Login & OTP Registration</li>
        <li>Browse Cleaning Services</li>
        <li>Create & Track Bookings in Real-Time</li>
        <li>Online VNPAY / Cash Payments</li>
        <li>Live Chat with AI Assistant</li>
        <li>Rate & Review Completed Jobs</li>
      </ul>
    </td>
    <td>
      <ul>
        <li>Receive Push Notifications for New Jobs</li>
        <li>View & Accept Assigned Jobs</li>
        <li>Update Job Status (Start, Complete, etc.)</li>
        <li>Track Daily/Monthly Earnings</li>
        <li>Live GPS Location Updates</li>
      </ul>
    </td>
    <td>
      <ul>
        <li>Monitor Users & Workers</li>
        <li>View Overall Statistics</li>
        <li>Manage Master Services</li>
        <li>Track All Bookings</li>
      </ul>
    </td>
  </tr>
</table>

---

## 🛠 Technology Stack

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **State Management**: Riverpod
- **Networking**: Dio
- **Real-time Communication**: SignalR
- **Authentication**: JWT, OAuth2
- **Mapping & Tracking**: Google Maps SDK
- **Backend API**: ASP.NET Core

---

## 📂 Project Structure

```text
lib/
├── core/
│   ├── constants/       # App-wide constants (Colors, Strings)
│   ├── theme/           # UI Themes, Fonts
│   ├── routes/          # AppRouter configuration
│   └── network/         # Dio Client, Interceptors
│
├── data/
│   ├── models/          # Dart Data Models
│   ├── repositories/    # API Repositories
│   └── services/        # Third-party Services (e.g., SignalR, Maps)
│
├── ui/
│   ├── auth/            # Login, Registration, OTP Screens
│   ├── home/            # Main Dashboard
│   ├── booking/         # Booking Flow & Tracking
│   ├── chat/            # Live AI Chat Interface
│   └── shared/          # Reusable Widgets
│
└── main.dart            # Application Entry Point
```

---

## ⚙️ Installation & Setup

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.19.0+)
- Android Studio / VS Code
- Android Emulator or Physical Device

### 1️⃣ Clone the Repository

```bash
git clone https://github.com/chinsuhdh/PRM393_Cleaning_Android.git
cd PRM393_Cleaning_Android
```

### 2️⃣ Install Dependencies

```bash
flutter pub get
```

### 3️⃣ Run the Application

```bash
flutter run
```

### 4️⃣ Build for Production (APK/AppBundle)

```bash
flutter build apk
flutter build appbundle
```

---

## 🛡️ Security

- **JWT Authentication**: Secure token-based API access.
- **Refresh Token Mechanism**: Seamless session management.
- **Role-Based Authorization**: Distinct flows for Clients and Workers.

---

<div align="center">
  <i>Developed with ❤️ by the CleanAI Team</i>
</div>