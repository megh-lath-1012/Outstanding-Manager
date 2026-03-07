<div align="center">
  <h1>Outstanding Management App 📊💰</h1>
  <p>A premium, cross-platform Flutter application designed to help businesses track and manage outstanding sales and purchase records with ease, powered by Firebase and intelligent AI features.</p>

  [![Flutter CI](https://github.com/megh-lath-1012/Outstanding-Manager/actions/workflows/flutter.yml/badge.svg)](https://github.com/megh-lath-1012/Outstanding-Manager/actions/workflows/flutter.yml)
  [![Flutter Test](https://github.com/megh-lath-1012/Outstanding-Manager/actions/workflows/test.yml/badge.svg)](https://github.com/megh-lath-1012/Outstanding-Manager/actions/workflows/test.yml)
</div>

---

## ✨ Key Features

- **💡 Pulse AI Assistant**: Built-in generative AI agent powered by Google Gemini that lets you record transactions lightning fast using natural language (e.g., *"Received 50k from Vasant"*).
- **📊 Smart Dashboard**: Real-time summary of total sales and purchase outstandings, including monthly coverage forecasting and auto-allocation calculations.
- **📁 Automated Ledger**: 
  - Manage Sales Invoices, Purchase Bills, Customers, and Suppliers easily.
  - Deleting a payment record automatically restores the invoice balance across the board.
  - "Silent Allocation" allows rapid entry payments to intelligently find their corresponding oldest unpaid invoices automatically.
- **📨 Professional Export**: Generate clean, branded PDF reports and Excel spreadsheets with a single tap.
- **🔒 Bank-Grade Security**: 
  - Fully powered by Firebase Authentication and Firestore.
  - Production-grade Security Rules isolate user data absolutely. All keys are dynamically injected via `flutter_dotenv` keeping the open-source repository pristine.

## 🛠 Tech Stack

- **Frontend**: [Flutter](https://flutter.dev/) (Cross-Platform) & Material 3 / Glassmorphism UI
- **State Management**: [Riverpod](https://riverpod.dev/)
- **Backend & DB**: [Firebase](https://firebase.google.com/) (Firestore, Auth, Storage)
- **Cloud Functions**: Node.js (Aggressive text parsing, AI aggregation)
- **Generative AI**: Google Gemini 2.5 Flash API
- **Docs via GitHub Pages**: MkDocs + Material Theme

## 🚀 Getting Started

### Prerequisites
- Flutter SDK installed
- A Firebase project setup (with Firestore and Auth enabled)

### Local Installation
1.  **Clone the repository**:
    ```bash
    git clone https://github.com/megh-lath-1012/Outstanding-Manager.git
    cd Outstanding-Manager
    ```
2.  **Configure Environment Variables**:
    Create a local `.env` file in the root directory to house your API keys (this keeps them out of version control!):
    ```env
    FIREBASE_ANDROID_API_KEY=your_key_here
    FIREBASE_IOS_API_KEY=your_key_here
    FIREBASE_WEB_API_KEY=your_key_here
    ```
3.  **Install dependencies**:
    ```bash
    flutter pub get
    ```
4.  **Run the app**:
    ```bash
    flutter run
    ```

## 📜 Legal & Documentation

All user terms, privacy policies, and security specifications can be found on our hosted documentation site:

- [Privacy Policy](https://megh-lath-1012.github.io/Outstanding-Manager/privacy-policy.html)
- [Terms & Conditions](https://megh-lath-1012.github.io/Outstanding-Manager/terms-of-service.html)

---
*Built with ❤️ utilizing Flutter and Firebase.*
