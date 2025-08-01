# Gemura

A comprehensive Flutter-based financial services application that provides users with a complete suite of financial tools including payments, loans, savings, insurance, and merchant services.

## 📱 Features

### 🏠 **Home Dashboard**
- Multi-tab navigation (Home, Transactions, Ikofi, Chat, Profile)
- Wallet balance display with visibility toggle
- Transaction history with interactive charts
- Quick action buttons for payments and transfers
- Real-time balance updates

### 💳 **Payment System**
- **Request Payment**: Generate payment links and QR codes for easy sharing
- **Pay Screen**: Send money to contacts with multiple payment methods
- **Payouts**: Withdraw funds to bank accounts with transaction tracking
- **Payment Methods**: Mobile Money, Cards, Bank transfers, QR/USSD

### 💰 **Wallet Management**
- Multiple wallet support (individual and joint wallets)
- Balance tracking with visibility controls
- Transaction history per wallet
- Target savings with progress tracking
- Wallet sharing and collaboration features

### 💬 **Chat System**
- Real-time messaging between users
- Multiple message types: text, image, file, payment, system
- Message status tracking (sending, sent, delivered, read, failed)
- Reply functionality and message threading
- File and image sharing capabilities

### 🏦 **Loans Module**
- **Loan Types**: Cash, Device, Float, Product loans
- **Status Tracking**: Pending, Approved, Active, Completed, Rejected, Overdue
- Loan creation with customizable terms and interest rates
- Repayment tracking and history
- Guarantor system for loan security
- Loan calculator and payment scheduling

### 🎯 **Savings Goals**
- Goal-based savings with target amounts and dates
- Progress tracking with visual indicators
- Multiple contributors support for group savings
- Top-up functionality and automatic savings
- Savings analytics and insights

### 🛡️ **Insurance System**
- **Insurance Types**: Health, Life, Property, Vehicle, Business
- Policy management with coverage amounts
- Payment frequency options (monthly, quarterly, annually)
- Renewal tracking and notifications
- Insurance claims processing

### 🏪 **Merchant Features**
- Dashboard with transaction analytics
- Wallet management for businesses
- Transaction history and reporting
- Profile management for merchants
- Business insights and performance metrics

### 🔐 **Authentication & Security**
- Secure login/register with email/password
- Forgot password functionality
- User profile management
- Role-based access control
- Secure data encryption

## 🏗️ Architecture

### **Technology Stack**
- **Framework**: Flutter 3.4.3+
- **State Management**: Riverpod 2.5.1
- **Navigation**: Go Router 13.2.5
- **Database**: SQLite (sqflite 2.3.3+1)
- **HTTP Client**: Dio 5.4.3
- **Local Storage**: Shared Preferences 2.3.3
- **Image Handling**: Image Picker 1.0.7, Image Cropper 5.0.1
- **Notifications**: Flutter Local Notifications 16.3.3
- **Charts**: D-Chart 2.8.0

### **Project Structure**
```
lib/
├── core/
│   ├── config/
│   │   └── app_config.dart
│   └── theme/
│       ├── app_theme.dart
│       └── route_manager.dart
├── features/
│   ├── auth/
│   ├── chat/
│   ├── home/
│   ├── insurance/
│   ├── loans/
│   ├── merchant/
│   └── savings/
├── shared/
│   ├── models/
│   ├── utils/
│   └── widgets/
└── main.dart
```

## 🎨 Design System

### **Color Palette**
- **Primary Color**: `#004AAD` (Blue)
- **Background**: `#F5F5F5` (Light Gray)
- **Surface**: `#FFFFFF` (White)
- **Success**: `#4CAF50` (Green)
- **Error**: `#E53935` (Red)
- **Warning**: `#FFA000` (Orange)

### **Typography**
- **Font Family**: Inter
- **Headline Large**: 32px, Weight 700
- **Title Medium**: 18px, Weight 600
- **Body Medium**: 16px, Weight 400
- **Body Small**: 14px, Weight 400

## 🚀 Getting Started

### **Prerequisites**
- Flutter SDK 3.4.3 or higher
- Dart SDK 3.4.3 or higher
- Android Studio / VS Code
- Git

### **Installation**

1. **Clone the repository**
   ```