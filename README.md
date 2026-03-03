# Outstanding Management App 📊💰

A premium, cross-platform Flutter application designed to help businesses track and manage outstanding sales and purchase records with ease. Featuring a modern UI, Firebase integration, and professional reporting capabilities.

## ✨ Features

- **📊 Dashboard Overview**: Real-time summary of total sales and purchase outstandings.
- **📁 Record Management**:
    - **Sales Outstanding**: Track invoices, party details, and pending amounts.
    - **Purchase Outstanding**: Manage vendor bills and payables.
- **💳 Payment Tracking**:
    - Record full or partial payments for any invoice.
    - Automatic history logging for all transactions.
    - **Intelligent Restoration**: Deleting a payment record automatically restores the invoice balance.
- **📨 Professional Export**:
    - **PDF Export**: Generate clean, landscape-oriented reports with branding and total summaries.
    - **Excel Export**: Export data to spreadsheets for further analysis.
- **🔍 Advanced Search & Sorting**:
    - Real-time search by party name or invoice number.
    - Sort by Date, Amount, or Party Name.
- **👤 Profile & Settings**: Manage business details and app preferences.
- **🔒 Secure & Sync**: Powered by Firebase for real-time data sync and secure authentication.

## 🔄 Application Flow

Understanding how the application works is key to effective management:

1.  **Dashboard**: Start here for a high-level overview of total receivables (from customers) and payables (to suppliers).
2.  **Parties**: Add and manage Customers (who buy from you) and Suppliers (you buy from).
3.  **Invoices**:
    *   Create **Sales Invoices** for customers.
    *   Create **Purchase Invoices** for suppliers.
    *   Invoices track line items, discounts, and taxes.
4.  **Payments**:
    *   Record **Receipts** when a customer pays you.
    *   Record **Payments** when you pay a supplier.
    *   A single payment can be allocated across multiple invoices.

## ⚙️ Core Logic

The application features an automated balance management system:

*   **Real-time Updates**: When a payment is recorded and allocated to an invoice, the invoice's `paidAmount` and `outstandingAmount` are recalculated automatically.
*   **Balance Restoration**: If a payment record is deleted, the system automatically restores the corresponding invoice balances, ensuring your records always stay accurate.
*   **Status Management**: Invoices automatically transition between `Unpaid`, `Partial`, and `Paid` statuses based on the total allocated payments.

## 🛠 Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (3.11+)
- **State Management**: [Riverpod](https://riverpod.dev/)
- **Database & Auth**: [Firebase](https://firebase.google.com/) (Firestore, Auth)
- **Reporting**: `pdf` and `excel` packages
- **CI/CD**: GitHub Actions (Automated Analysis & Testing)

## 🚀 Getting Started

### Prerequisites
- Flutter SDK installed
- A Firebase project setup

### Installation
1.  **Clone the repository**:
    ```bash
    git clone https://github.com/your-username/outstanding-management-app.git
    cd outstanding_management_app
    ```
2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Configure Firebase**:
    - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS).
    - Run `flutterfire configure` if using FlutterFire CLI.
4.  **Run the app**:
    ```bash
    flutter run
    ```

## 📸 Screenshots
*(Add your screenshots here after uploading to GitHub)*

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
Built with ❤️ using Flutter and Firebase.
