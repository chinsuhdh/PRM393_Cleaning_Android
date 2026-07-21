# CleanAI - Frontend Mobile Application

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?logo=android&logoColor=white)

## Introduction

CleanAI is a Flutter-based mobile application for an AI-powered cleaning service booking platform.

The application connects customers, cleaning workers, and administrators through a modern and user-friendly interface.

Frontend communicates with ASP.NET Core Backend APIs and PostgreSQL Database.

---

## Table of Contents

- [Introduction](#introduction)
- [Main Features](#main-features)
- [Project Structure](#project-structure)
- [Technology Stack](#technology-stack)
- [Installation](#installation)
- [Security](#security)
- [Team](#team)

---

## Main Features

### Client

- Register and login
- Manage profile
- Manage addresses
- Browse services
- Create bookings
- Track booking status
- Online payments
- Rate completed services
- Chat with AI Assistant

### Worker

- Receive job notifications
- View assigned jobs
- Update job status
- Track earnings
- Update GPS location
- Manage profile

### Admin

- Manage users
- Manage services
- Manage bookings
- Manage workers
- View system statistics

---

## Project Structure

```text
lib/
├── core/
│   ├── constants/
│   ├── theme/
│   ├── routes/
│   └── network/
│
├── data/
│   ├── models/
│   ├── repositories/
│   └── services/
│
├── ui/
│   ├── auth/
│   ├── home/
│   ├── booking/
│   ├── service/
│   ├── chat/
│   ├── notification/
│   ├── profile/
│   ├── worker/
│   ├── admin/
│   └── widgets/
│
└── main.dart
```

---

## Technology Stack

- Flutter
- Dart
- Dio
- SignalR
- JWT Authentication
- OAuth2
- Google Maps
- PostgreSQL
- ASP.NET Core Backend

---

## Installation

Clone repository:

```bash
git clone <repository-url>
```

Install dependencies:

```bash
flutter pub get
```

Run application:

```bash
flutter run
```

Build APK:

```bash
flutter build apk
```

Build App Bundle:

```bash
flutter build appbundle
```

---

## Security

- JWT Authentication
- Refresh Token
- OAuth Login
- OTP Verification
- Role-Based Authorization

---

## Team

CleanAI Development Team