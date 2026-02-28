# Invoice & Outstandings Management App - Flutter Specification Document

## Project Overview

Build a production-ready Flutter mobile application for managing sales and purchase invoices with comprehensive payment tracking, multi-invoice payment allocation, and profit dashboard. The app features modern Airbnb-style UI/UX with complete Firebase/Firestore backend integration for authentication and cloud data storage.

---

## Technical Stack

- **Frontend**: Flutter 3.x+ (Dart)
- **Backend**: Firebase (Firestore database, Authentication, Cloud Functions)
- **Database**: Cloud Firestore (NoSQL)
- **State Management**: Riverpod or Provider (recommended)
- **Navigation**: Go Router or Flutter Navigator 2.0
- **Local Storage**: None (pure cloud-based with Firestore)
- **Authentication**: Firebase Auth (email/password, JWT tokens)
- **Storage**: Firebase Storage for files and images

---

## Design System

### Color Palette
- **Primary Color**: #FF385C (Airbnb Coral)
- **Primary Variants**:
  - Light: #FF5A75
  - Dark: #E31C5F
- **Secondary Color**: #00A699 (Teal accent)
- **Background Colors**:
  - Light Mode: #FFFFFF, #F7F7F7
  - Dark Mode: #121212, #1E1E1E
- **Text Colors**:
  - Primary: #484848
  - Secondary: #767676
  - Light: #FFFFFF
- **Status Colors**:
  - Success: #00A699
  - Warning: #FFA726
  - Error: #FF385C
  - Info: #4A90E2

### Typography
- **Primary Font**: Circular (Airbnb's font) or fallback to Montserrat/Poppins
- **Heading Sizes**:
  - H1: 28px, bold
  - H2: 24px, semi-bold
  - H3: 20px, semi-bold
  - H4: 18px, medium
- **Body Text**: 16px, regular
- **Caption**: 14px, regular
- **Small Text**: 12px, regular

### Design Elements
- **Border Radius**: 12px (cards), 8px (buttons), 20px (bottom nav)
- **Shadows**: Soft, elevated shadows for cards (elevation 2-4)
- **Glassmorphic Cards**: Frosted glass effect with blur
- **Gradient Headers**: Linear gradient from primary to primary-dark
- **Smooth Transitions**: 200-300ms animation duration
- **Bottom Navigation**: 5 tabs with icons and labels
- **Floating Action Button**: Coral color for primary actions

---

## Core Features

### 1. Authentication System
- Email/password registration with validation
- Email/password login
- Password reset via email
- Email verification
- JWT token management (handled by Firebase)
- Automatic session persistence
- Logout functionality
- Protected routes (redirect to login if unauthenticated)
- Social authentication (optional: Google, Apple)

### 2. User Profile Management
- View and edit user profile information
- Profile photo upload to Firebase Storage
- Update display name, email, phone number
- Change password functionality
- Account settings

### 3. Party Management
- Create, edit, delete parties (customers/suppliers)
- Party types: Customer or Supplier
- Party information:
  - Name (required)
  - Contact person
  - Phone number
  - Email
  - Address
  - GST/Tax ID
  - Opening balance
- Search and filter parties
- View party-wise outstanding summary
- Party detail page with transaction history

### 4. Invoice Management

#### Sales Invoices
- Create sales invoice with:
  - Party selection (customer)
  - Invoice number (auto-generated or manual)
  - Invoice date
  - Due date
  - Multiple line items (product/service, quantity, rate, amount)
  - Tax/GST calculations
  - Discount (percentage or fixed)
  - Total amount
  - Notes/remarks
- Edit existing invoices (with validation)
- Delete invoices (with confirmation)
- View invoice details
- Filter invoices by:
  - Date range
  - Party
  - Payment status (Paid, Partial, Unpaid)
  - Amount range
- Search invoices by invoice number or party name
- Invoice status indicators (Paid/Unpaid/Overdue)

#### Purchase Invoices
- Same features as sales invoices but for suppliers
- Separate list and management from sales
- Bill number instead of invoice number

### 5. Payment Management

#### Payment Recording
- Record payment against sales invoice (receipt)
- Record payment against purchase invoice (payment)
- Payment information:
  - Payment date
  - Payment method (Cash, Bank Transfer, Cheque, UPI, Card, Other)
  - Reference number
  - Amount
  - Notes
- **Multi-invoice allocation**: Single payment can be allocated across multiple invoices
- Partial payment support
- Full payment support
- Automatic outstanding calculation

#### Payment Allocation Logic
- When recording a payment:
  - Select one or more invoices
  - Allocate payment amount across selected invoices
  - Show remaining balance per invoice
  - Show total payment amount
  - Validate that allocated amount doesn't exceed invoice outstanding
- Display allocation breakdown in payment history

#### Payment History
- Comprehensive payment history per party
- View all payments with:
  - Payment date
  - Amount
  - Payment method
  - Reference number
  - Allocated invoices (with amounts)
  - Running balance
- Filter by date range, payment method
- Export payment history

### 6. Dashboard

#### Key Metrics Cards
- Total Sales (current month/year)
- Total Purchases (current month/year)
- **Gross Profit** = Total Sales - Total Purchases
- **Profit Margin %** = (Gross Profit / Total Sales) × 100
- Total Receivables (outstanding from customers)
- Total Payables (outstanding to suppliers)
- Net Outstanding = Receivables - Payables

#### Charts & Visualizations
- Sales vs Purchases trend (line/bar chart)
- Monthly profit chart
- Payment status pie chart (Paid/Partial/Unpaid)
- Top 5 customers by sales
- Top 5 suppliers by purchases
- Overdue invoices count
- Recent transactions list (last 10)

#### Date Range Filters
- Today
- This Week
- This Month
- This Quarter
- This Year
- Custom date range

### 7. Settings
- **Theme Toggle**: Light/Dark mode with persistent preference
- **Notification Preferences**:
  - Payment reminders
  - Overdue invoice alerts
  - Low balance warnings
- **Business Settings**:
  - Company name
  - Company logo
  - GST/Tax number
  - Invoice prefix
  - Default currency
  - Financial year start month
- **Data Management**:
  - Export data (CSV/PDF)
  - Backup reminder
- **Account Settings**:
  - Change password
  - Email preferences
  - Delete account (with confirmation)

### 8. Navigation Structure

#### Bottom Navigation (5 tabs)
1. **Home** (Dashboard icon) - Dashboard screen
2. **Invoices** (Document icon) - Invoice list (tabs for Sales/Purchase)
3. **Parties** (People icon) - Party list screen
4. **Payments** (Money icon) - Payment history screen
5. **Profile** (User icon) - Profile and settings screen

#### App Bar
- Screen title
- Back button (when applicable)
- Action buttons (search, filter, add, etc.)
- Gradient background matching primary color

---

## Database Schema (Cloud Firestore)

### Collection Structure

Cloud Firestore is a NoSQL database, so the structure is different from SQL. Here's the collection hierarchy:

```
users/ (collection)
  └── {userId}/ (document)
      ├── email: string
      ├── displayName: string
      ├── phoneNumber: string
      ├── avatarUrl: string
      ├── companyName: string
      ├── companyLogoUrl: string
      ├── gstNumber: string
      ├── address: string
      ├── invoicePrefix: string (default: "INV")
      ├── currency: string (default: "INR")
      ├── themePreference: string (default: "light")
      ├── createdAt: timestamp
      └── updatedAt: timestamp

parties/ (collection)
  └── {partyId}/ (document)
      ├── userId: string (indexed)
      ├── partyType: string ("customer" or "supplier")
      ├── name: string
      ├── contactPerson: string
      ├── phoneNumber: string
      ├── email: string
      ├── address: string
      ├── gstNumber: string
      ├── openingBalance: number (default: 0)
      ├── createdAt: timestamp
      └── updatedAt: timestamp

invoices/ (collection)
  └── {invoiceId}/ (document)
      ├── userId: string (indexed)
      ├── partyId: string (indexed)
      ├── partyName: string (denormalized for easier queries)
      ├── invoiceType: string ("sales" or "purchase")
      ├── invoiceNumber: string (indexed)
      ├── invoiceDate: timestamp
      ├── dueDate: timestamp
      ├── subtotal: number (default: 0)
      ├── discountType: string ("percentage" or "fixed")
      ├── discountValue: number (default: 0)
      ├── discountAmount: number (default: 0)
      ├── taxPercentage: number (default: 0)
      ├── taxAmount: number (default: 0)
      ├── totalAmount: number
      ├── paidAmount: number (default: 0)
      ├── outstandingAmount: number
      ├── paymentStatus: string ("paid", "partial", or "unpaid")
      ├── notes: string
      ├── createdAt: timestamp
      └── updatedAt: timestamp
      
      └── items/ (subcollection)
          └── {itemId}/ (document)
              ├── description: string
              ├── quantity: number (default: 1)
              ├── rate: number
              ├── amount: number
              └── createdAt: timestamp

payments/ (collection)
  └── {paymentId}/ (document)
      ├── userId: string (indexed)
      ├── partyId: string (indexed)
      ├── partyName: string (denormalized)
      ├── paymentType: string ("receipt" or "payment")
      ├── paymentDate: timestamp
      ├── totalAmount: number
      ├── paymentMethod: string ("cash", "bank_transfer", "cheque", "upi", "card", "other")
      ├── referenceNumber: string
      ├── notes: string
      ├── createdAt: timestamp
      └── updatedAt: timestamp
      
      └── allocations/ (subcollection)
          └── {allocationId}/ (document)
              ├── invoiceId: string
              ├── invoiceNumber: string (denormalized)
              ├── allocatedAmount: number
              └── createdAt: timestamp
```

### Composite Indexes

Create these composite indexes in Firebase Console:

1. **parties**:
   - userId (Ascending) + partyType (Ascending) + name (Ascending)
   - userId (Ascending) + createdAt (Descending)

2. **invoices**:
   - userId (Ascending) + invoiceType (Ascending) + invoiceDate (Descending)
   - userId (Ascending) + invoiceType (Ascending) + paymentStatus (Ascending)
   - userId (Ascending) + partyId (Ascending) + invoiceDate (Descending)
   - userId (Ascending) + invoiceDate (Ascending) + invoiceDate (Descending)

3. **payments**:
   - userId (Ascending) + paymentType (Ascending) + paymentDate (Descending)
   - userId (Ascending) + partyId (Ascending) + paymentDate (Descending)
   - userId (Ascending) + paymentDate (Ascending) + paymentDate (Descending)

### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    function isValidUser() {
      return isAuthenticated() && 
             request.resource.data.userId == request.auth.uid;
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated() && isOwner(userId);
      allow create: if isAuthenticated() && isOwner(userId);
      allow update: if isAuthenticated() && isOwner(userId);
      allow delete: if false; // Prevent deletion
    }
    
    // Parties collection
    match /parties/{partyId} {
      allow read: if isAuthenticated() && isOwner(resource.data.userId);
      allow create: if isValidUser();
      allow update: if isAuthenticated() && isOwner(resource.data.userId);
      allow delete: if isAuthenticated() && isOwner(resource.data.userId);
    }
    
    // Invoices collection
    match /invoices/{invoiceId} {
      allow read: if isAuthenticated() && isOwner(resource.data.userId);
      allow create: if isValidUser() && 
                      request.resource.data.keys().hasAll(['userId', 'partyId', 'invoiceType', 'totalAmount']);
      allow update: if isAuthenticated() && isOwner(resource.data.userId);
      allow delete: if isAuthenticated() && isOwner(resource.data.userId);
      
      // Invoice items subcollection
      match /items/{itemId} {
        allow read: if isAuthenticated();
        allow write: if isAuthenticated();
      }
    }
    
    // Payments collection
    match /payments/{paymentId} {
      allow read: if isAuthenticated() && isOwner(resource.data.userId);
      allow create: if isValidUser() && 
                      request.resource.data.keys().hasAll(['userId', 'partyId', 'paymentType', 'totalAmount']);
      allow update: if isAuthenticated() && isOwner(resource.data.userId);
      allow delete: if isAuthenticated() && isOwner(resource.data.userId);
      
      // Payment allocations subcollection
      match /allocations/{allocationId} {
        allow read: if isAuthenticated();
        allow write: if isAuthenticated();
      }
    }
  }
}
```

### Firebase Storage Security Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // User avatars
    match /avatars/{userId}/{fileName} {
      allow read: if true; // Public read
      allow write: if request.auth != null && request.auth.uid == userId &&
                     request.resource.size < 5 * 1024 * 1024 && // Max 5MB
                     request.resource.contentType.matches('image/.*');
    }
    
    // Company logos
    match /company_logos/{userId}/{fileName} {
      allow read: if true; // Public read
      allow write: if request.auth != null && request.auth.uid == userId &&
                     request.resource.size < 5 * 1024 * 1024 && // Max 5MB
                     request.resource.contentType.matches('image/.*');
    }
    
    // Invoice PDFs (if needed)
    match /invoices/{userId}/{invoiceId}/{fileName} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId &&
                     request.resource.size < 10 * 1024 * 1024 && // Max 10MB
                     request.resource.contentType == 'application/pdf';
    }
  }
}
```

---

## Cloud Functions (Optional but Recommended)

### Update Invoice Payment Status (Trigger)

This Cloud Function automatically updates invoice payment status when payment allocations change.

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

// Trigger when a payment allocation is created
exports.updateInvoiceOnPaymentAllocation = functions.firestore
  .document('payments/{paymentId}/allocations/{allocationId}')
  .onCreate(async (snap, context) => {
    const allocation = snap.data();
    const invoiceId = allocation.invoiceId;
    
    return updateInvoicePaymentStatus(invoiceId);
  });

// Trigger when a payment allocation is deleted
exports.updateInvoiceOnPaymentAllocationDelete = functions.firestore
  .document('payments/{paymentId}/allocations/{allocationId}')
  .onDelete(async (snap, context) => {
    const allocation = snap.data();
    const invoiceId = allocation.invoiceId;
    
    return updateInvoicePaymentStatus(invoiceId);
  });

// Helper function to update invoice payment status
async function updateInvoicePaymentStatus(invoiceId) {
  const invoiceRef = db.collection('invoices').doc(invoiceId);
  const invoice = await invoiceRef.get();
  
  if (!invoice.exists) {
    console.error('Invoice not found:', invoiceId);
    return;
  }
  
  const invoiceData = invoice.data();
  const totalAmount = invoiceData.totalAmount;
  
  // Calculate total paid amount from all allocations across all payments
  const allocationsSnapshot = await db.collectionGroup('allocations')
    .where('invoiceId', '==', invoiceId)
    .get();
  
  let paidAmount = 0;
  allocationsSnapshot.forEach(doc => {
    paidAmount += doc.data().allocatedAmount;
  });
  
  const outstandingAmount = totalAmount - paidAmount;
  
  let paymentStatus = 'unpaid';
  if (outstandingAmount <= 0) {
    paymentStatus = 'paid';
  } else if (paidAmount > 0) {
    paymentStatus = 'partial';
  }
  
  return invoiceRef.update({
    paidAmount: paidAmount,
    outstandingAmount: outstandingAmount,
    paymentStatus: paymentStatus,
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });
}

// Generate invoice number
exports.generateInvoiceNumber = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  
  const userId = context.auth.uid;
  const invoiceType = data.invoiceType; // 'sales' or 'purchase'
  
  // Get user settings for prefix
  const userDoc = await db.collection('users').doc(userId).get();
  const prefix = userDoc.data()?.invoicePrefix || 'INV';
  
  // Get the count of invoices for this user and type
  const invoicesSnapshot = await db.collection('invoices')
    .where('userId', '==', userId)
    .where('invoiceType', '==', invoiceType)
    .get();
  
  const count = invoicesSnapshot.size + 1;
  const invoiceNumber = `${prefix}-${String(count).padStart(5, '0')}`;
  
  return { invoiceNumber };
});

// Delete user data when account is deleted
exports.deleteUserData = functions.auth.user().onDelete(async (user) => {
  const userId = user.uid;
  
  // Delete all user's parties
  const partiesSnapshot = await db.collection('parties').where('userId', '==', userId).get();
  const partiesDeletePromises = partiesSnapshot.docs.map(doc => doc.ref.delete());
  
  // Delete all user's invoices
  const invoicesSnapshot = await db.collection('invoices').where('userId', '==', userId).get();
  const invoicesDeletePromises = invoicesSnapshot.docs.map(async (doc) => {
    // Delete subcollection items
    const itemsSnapshot = await doc.ref.collection('items').get();
    const itemsDeletePromises = itemsSnapshot.docs.map(item => item.ref.delete());
    await Promise.all(itemsDeletePromises);
    
    // Delete invoice
    return doc.ref.delete();
  });
  
  // Delete all user's payments
  const paymentsSnapshot = await db.collection('payments').where('userId', '==', userId).get();
  const paymentsDeletePromises = paymentsSnapshot.docs.map(async (doc) => {
    // Delete subcollection allocations
    const allocationsSnapshot = await doc.ref.collection('allocations').get();
    const allocationsDeletePromises = allocationsSnapshot.docs.map(alloc => alloc.ref.delete());
    await Promise.all(allocationsDeletePromises);
    
    // Delete payment
    return doc.ref.delete();
  });
  
  // Delete user profile
  const userDeletePromise = db.collection('users').doc(userId).delete();
  
  // Execute all deletions
  await Promise.all([
    ...partiesDeletePromises,
    ...invoicesDeletePromises,
    ...paymentsDeletePromises,
    userDeletePromise
  ]);
  
  console.log('Deleted all data for user:', userId);
});
```

---

## Firebase Configuration

### Install Firebase CLI

```bash
npm install -g firebase-tools
firebase login
firebase init
```

### Firebase Configuration File (firebase.json)

```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "storage": {
    "rules": "storage.rules"
  },
  "functions": {
    "source": "functions",
    "runtime": "nodejs18"
  }
}
```

### Flutter Firebase Configuration

Add these to your Flutter project:

**pubspec.yaml**:
```yaml
dependencies:
  firebase_core: ^2.24.0
  firebase_auth: ^4.15.0
  cloud_firestore: ^4.13.0
  firebase_storage: ^11.5.0
  # Optional
  firebase_analytics: ^10.7.0
  firebase_crashlytics: ^3.4.0
```

### Environment Variables (Firebase Config)

Store these in your Flutter app (use flutter_dotenv or directly in code):

```dart
// lib/core/firebase_config.dart
class FirebaseConfig {
  static const String apiKey = "YOUR_API_KEY";
  static const String appId = "YOUR_APP_ID";
  static const String messagingSenderId = "YOUR_SENDER_ID";
  static const String projectId = "YOUR_PROJECT_ID";
  static const String storageBucket = "YOUR_STORAGE_BUCKET";
  
  // iOS specific
  static const String iosClientId = "YOUR_IOS_CLIENT_ID";
  static const String iosBundleId = "YOUR_BUNDLE_ID";
}
```

**Note**: For production, download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) from Firebase Console and add them to your project.

---

## Screen-by-Screen Breakdown

### 1. Splash Screen
- App logo with gradient background
- Loading animation
- Initialize Firebase
- Check authentication status
- Navigate to Login or Dashboard

### 2. Login Screen
- Email input field
- Password input field (with show/hide toggle)
- "Remember me" checkbox
- Login button (full width, coral color)
- "Forgot Password?" link
- "Don't have an account? Sign up" link
- Optional: Social login buttons (Google, Apple)
- Form validation with error messages
- Loading state during authentication

### 3. Registration Screen
- Full name input
- Email input
- Password input (with strength indicator)
- Confirm password input
- Company name (optional)
- Phone number (optional)
- Register button
- "Already have an account? Login" link
- Form validation
- Loading state
- Email verification sent after registration

### 4. Forgot Password Screen
- Email input
- "Send Reset Link" button
- Back to login link
- Success message after email sent

### 5. Dashboard Screen (Home Tab)
- **App Bar**: "Dashboard" title, notification icon, profile icon
- **Date Range Selector**: Chips for quick filters + custom range
- **Metrics Cards** (2x2 grid with glassmorphic effect):
  - Total Sales (with trend icon)
  - Total Purchases (with trend icon)
  - Gross Profit (with percentage)
  - Net Outstanding (receivables - payables)
- **Chart Section**:
  - Tab selector: "Sales vs Purchases" | "Profit Trend"
  - Interactive chart (bar/line)
- **Quick Stats Section**:
  - Pending invoices count
  - Overdue invoices count
  - Today's collections
  - This month's expenses
- **Recent Activity List**:
  - Last 5-10 transactions
  - Invoice/payment with party name, amount, date
  - Tap to view details
- **Bottom Navigation**: Highlighted on Home tab

### 6. Invoice List Screen (Invoices Tab)
- **App Bar**: "Invoices" title, search icon, filter icon
- **Tab Bar**: "Sales" | "Purchase" (toggle between types)
- **Floating Action Button**: "+" to add new invoice
- **Filter Chips** (horizontal scroll):
  - All
  - Paid
  - Partial
  - Unpaid
  - Overdue
- **Invoice Cards** (list view):
  - Invoice number (bold)
  - Party name
  - Invoice date
  - Total amount
  - Outstanding amount (if any)
  - Status badge (colored)
  - Tap to view details
- **Empty State**: Illustration + "No invoices yet" message
- **Pull to Refresh**
- **Infinite Scroll** / Pagination

### 7. Invoice Detail Screen
- **App Bar**: Invoice number, edit icon, delete icon
- **Status Badge** at top
- **Party Information Card**:
  - Party name
  - Contact details
  - Tap to view party details
- **Invoice Details Card**:
  - Invoice date
  - Due date
  - Days overdue (if applicable)
- **Line Items Table**:
  - Description | Qty | Rate | Amount
  - Scrollable if many items
- **Calculation Summary**:
  - Subtotal
  - Discount (if any)
  - Tax/GST
  - **Total Amount** (bold, large)
  - Paid Amount (green)
  - **Outstanding Amount** (red/orange if unpaid)
- **Payment History Section**:
  - List of payments allocated to this invoice
  - Payment date, amount, method
  - Empty state if no payments
- **Action Buttons**:
  - "Record Payment" (primary button)
  - "Send Reminder" (secondary)
  - "Download PDF" (secondary)
- **Notes Section** (if any)

### 8. Add/Edit Invoice Screen
- **App Bar**: "New Sales Invoice" / "Edit Invoice", save icon
- **Form Fields**:
  - **Party Selection**: Dropdown/searchable list
    - "+ Add New Party" option
  - **Invoice Number**: Auto-generated (editable)
  - **Invoice Date**: Date picker (default today)
  - **Due Date**: Date picker (optional)
  - **Line Items Section**:
    - Add Item button
    - Item list with:
      - Description input
      - Quantity input (numeric)
      - Rate input (currency)
      - Amount (auto-calculated, read-only)
      - Delete icon
    - Minimum 1 item required
  - **Discount Section** (collapsible):
    - Toggle: Percentage / Fixed
    - Discount input
    - Calculated discount amount shown
  - **Tax/GST**: Percentage input (default from settings)
  - **Calculation Summary** (sticky at bottom):
    - Subtotal
    - Discount
    - Tax
    - **Total** (bold, large)
  - **Notes**: Multi-line text input
- **Bottom Action Bar**:
  - Cancel button
  - Save button (disabled until valid)
- **Validation**:
  - Party required
  - At least one line item
  - All amounts must be > 0
- **Auto-save draft** (optional)

### 9. Party List Screen (Parties Tab)
- **App Bar**: "Parties" title, search icon
- **Tab Bar**: "Customers" | "Suppliers"
- **Floating Action Button**: "+" to add new party
- **Search Bar** (expandable or fixed)
- **Party Cards** (list view):
  - Party name (bold)
  - Contact person
  - Phone number
  - Outstanding amount (red if payable, green if receivable)
  - Tap to view details
- **Empty State**: Illustration + "No parties yet"
- **Pull to Refresh**
- **Alphabetical Section Headers**

### 10. Party Detail Screen
- **App Bar**: Party name, edit icon, delete icon
- **Party Info Card**:
  - Name
  - Type badge (Customer/Supplier)
  - Contact person
  - Phone (with call icon)
  - Email (with email icon)
  - Address
  - GST Number
- **Outstanding Summary Card**:
  - Opening balance
  - Total invoices
  - Total payments
  - **Current Outstanding** (large, colored)
- **Tabs**: "Invoices" | "Payments"
  - **Invoices Tab**: List of all invoices for this party
  - **Payments Tab**: List of all payments for this party
- **Action Buttons**:
  - "Create Invoice"
  - "Record Payment"
  - "Send Statement"

### 11. Add/Edit Party Screen
- **App Bar**: "New Party" / "Edit Party", save icon
- **Form Fields**:
  - **Party Type**: Radio buttons (Customer / Supplier)
  - **Name**: Text input (required)
  - **Contact Person**: Text input
  - **Phone Number**: Phone input with country code
  - **Email**: Email input with validation
  - **Address**: Multi-line text input
  - **GST/Tax Number**: Text input
  - **Opening Balance**: Currency input (optional)
- **Bottom Action Bar**:
  - Cancel button
  - Save button (disabled until valid)
- **Validation**:
  - Name required
  - Valid email format
  - Valid phone format

### 12. Payment Recording Screen
- **App Bar**: "Record Payment" / "Record Receipt", save icon
- **Form Fields**:
  - **Party Selection**: Dropdown/searchable (auto-filled if from invoice detail)
  - **Payment Date**: Date picker (default today)
  - **Payment Method**: Dropdown (Cash, Bank Transfer, etc.)
  - **Reference Number**: Text input (optional)
  - **Total Payment Amount**: Currency input (large, prominent)
  - **Invoice Allocation Section**:
    - "Select Invoices" button or auto-show unpaid invoices
    - List of selected invoices with:
      - Invoice number
      - Invoice date
      - Total amount
      - Outstanding amount (before this payment)
      - **Allocated Amount**: Editable input per invoice
      - Remove icon
    - "+ Add Another Invoice" button
    - **Total Allocated**: Auto-sum (must equal Total Payment Amount)
    - Validation: Allocated ≤ Outstanding per invoice
  - **Remaining to Allocate**: Shows difference if total allocated ≠ payment amount
  - **Notes**: Multi-line text input
- **Bottom Action Bar**:
  - Cancel button
  - Save button (disabled until valid)
- **Validation**:
  - Party required
  - Payment amount > 0
  - At least one invoice selected
  - Total allocated = Total payment amount
  - Each allocated amount ≤ invoice outstanding

### 13. Payment History Screen (Payments Tab)
- **App Bar**: "Payment History", filter icon
- **Tab Bar**: "Receipts (Income)" | "Payments (Expense)"
- **Date Range Filter** (top)
- **Payment Cards** (list view):
  - Payment date (large)
  - Party name
  - Payment amount (colored based on type)
  - Payment method icon + label
  - Reference number (if any)
  - Allocated invoices count ("2 invoices")
  - Tap to view details
- **Expandable Detail** on tap:
  - Full allocation breakdown
  - Invoice numbers with amounts
  - Notes
- **Summary Card** at top:
  - Total receipts (selected period)
  - Total payments (selected period)
  - Net cash flow
- **Empty State**
- **Pull to Refresh**

### 14. Profile Screen (Profile Tab)
- **Header Section** (gradient background):
  - Profile photo (circular, large)
  - Tap to change photo
  - Display name (bold)
  - Email (secondary text)
  - "Edit Profile" button
- **Menu List**:
  - **Account Section**:
    - Edit Profile (chevron)
    - Change Password (chevron)
    - Business Settings (chevron)
  - **Preferences Section**:
    - Theme (Light/Dark toggle switch)
    - Notifications (chevron)
    - Language (chevron)
  - **Data Section**:
    - Export Data (chevron)
    - Backup & Restore (chevron)
  - **Support Section**:
    - Help & FAQ (chevron)
    - Contact Support (chevron)
    - About App (chevron)
  - **Logout Button** (red, full width)
- Each item has icon + label + trailing widget

### 15. Edit Profile Screen
- **App Bar**: "Edit Profile", save icon
- **Profile Photo Section**:
  - Current photo (large, circular)
  - "Change Photo" button
  - Photo picker (camera/gallery)
- **Form Fields**:
  - Display Name
  - Email (read-only or requires re-auth)
  - Phone Number
  - Company Name
  - Address
- **Save Button** at bottom
- **Loading state** during update

### 16. Change Password Screen
- **App Bar**: "Change Password"
- **Form Fields**:
  - Current Password (with show/hide)
  - New Password (with strength indicator)
  - Confirm New Password
- **Password Requirements** (checklist):
  - At least 8 characters
  - Contains uppercase letter
  - Contains lowercase letter
  - Contains number
  - Contains special character
- **Change Password Button**
- **Validation**: Current password correct, new password meets requirements

### 17. Business Settings Screen
- **App Bar**: "Business Settings", save icon
- **Form Fields**:
  - Company Logo (image picker)
  - Company Name
  - GST/Tax Number
  - Invoice Number Prefix (e.g., "INV")
  - Default Currency (dropdown)
  - Financial Year Start Month (dropdown)
  - Default Tax Percentage
- **Save Button**

### 18. Theme Settings Screen
- **App Bar**: "Appearance"
- **Theme Options** (radio list):
  - Light Mode (preview thumbnail)
  - Dark Mode (preview thumbnail)
  - System Default
- **Selected theme applied immediately**
- **Accent Color Picker** (optional):
  - Color swatches
  - Custom color picker

### 19. Notifications Settings Screen
- **App Bar**: "Notifications"
- **Toggle Switches**:
  - Enable Notifications (master switch)
  - Payment Reminders
  - Overdue Invoice Alerts
  - Payment Received Notifications
  - Low Balance Warnings
  - Weekly Summary Email
- **Reminder Timing**:
  - Days before due date (slider: 1-7 days)

### 20. Export Data Screen
- **App Bar**: "Export Data"
- **Export Options**:
  - **Data Type** (checkboxes):
    - Parties
    - Sales Invoices
    - Purchase Invoices
    - Payments
  - **Format** (radio buttons):
    - CSV
    - PDF
    - Excel
  - **Date Range**: Date pickers
- **Export Button**
- **Recent Exports List** (if any)
- **Download/Share exported file**

### 21. About Screen
- **App Bar**: "About"
- App logo (centered)
- App name and version
- Developer information
- **Links**:
  - Privacy Policy
  - Terms of Service
  - Licenses
  - Rate App
  - Share App

---

## Business Logic & Calculations

### Invoice Calculations
```dart
double calculateSubtotal(List<InvoiceItem> items) {
  return items.fold(0.0, (sum, item) => sum + item.amount);
}

double calculateDiscountAmount(double subtotal, String discountType, double discountValue) {
  if (discountType == 'percentage') {
    return subtotal * (discountValue / 100);
  } else if (discountType == 'fixed') {
    return discountValue;
  }
  return 0.0;
}

double calculateTaxAmount(double taxableAmount, double taxPercentage) {
  return taxableAmount * (taxPercentage / 100);
}

double calculateTotalAmount(double subtotal, double discountAmount, double taxAmount) {
  double taxableAmount = subtotal - discountAmount;
  return taxableAmount + taxAmount;
}

String calculatePaymentStatus(double totalAmount, double paidAmount) {
  double outstandingAmount = totalAmount - paidAmount;
  
  if (outstandingAmount <= 0) {
    return 'paid';
  } else if (paidAmount > 0) {
    return 'partial';
  }
  return 'unpaid';
}
```

### Dashboard Profit Calculation
```dart
Future<DashboardMetrics> calculateDashboardMetrics(String userId, DateTime startDate, DateTime endDate) async {
  // Query sales invoices
  final salesQuery = await FirebaseFirestore.instance
    .collection('invoices')
    .where('userId', isEqualTo: userId)
    .where('invoiceType', isEqualTo: 'sales')
    .where('invoiceDate', isGreaterThanOrEqualTo: startDate)
    .where('invoiceDate', isLessThanOrEqualTo: endDate)
    .get();
  
  double totalSales = salesQuery.docs.fold(0.0, (sum, doc) => sum + doc.data()['totalAmount']);
  
  // Query purchase invoices
  final purchasesQuery = await FirebaseFirestore.instance
    .collection('invoices')
    .where('userId', isEqualTo: userId)
    .where('invoiceType', isEqualTo: 'purchase')
    .where('invoiceDate', isGreaterThanOrEqualTo: startDate)
    .where('invoiceDate', isLessThanOrEqualTo: endDate)
    .get();
  
  double totalPurchases = purchasesQuery.docs.fold(0.0, (sum, doc) => sum + doc.data()['totalAmount']);
  
  double grossProfit = totalSales - totalPurchases;
  double profitMargin = totalSales > 0 ? (grossProfit / totalSales) * 100 : 0;
  
  // Calculate receivables and payables
  final receivablesQuery = await FirebaseFirestore.instance
    .collection('invoices')
    .where('userId', isEqualTo: userId)
    .where('invoiceType', isEqualTo: 'sales')
    .get();
  
  double totalReceivables = receivablesQuery.docs.fold(0.0, (sum, doc) => sum + doc.data()['outstandingAmount']);
  
  final payablesQuery = await FirebaseFirestore.instance
    .collection('invoices')
    .where('userId', isEqualTo: userId)
    .where('invoiceType', isEqualTo: 'purchase')
    .get();
  
  double totalPayables = payablesQuery.docs.fold(0.0, (sum, doc) => sum + doc.data()['outstandingAmount']);
  
  double netOutstanding = totalReceivables - totalPayables;
  
  return DashboardMetrics(
    totalSales: totalSales,
    totalPurchases: totalPurchases,
    grossProfit: grossProfit,
    profitMargin: profitMargin,
    totalReceivables: totalReceivables,
    totalPayables: totalPayables,
    netOutstanding: netOutstanding,
  );
}
```

### Party Outstanding Calculation
```dart
Future<double> calculatePartyOutstanding(String partyId, String partyType) async {
  final party = await FirebaseFirestore.instance.collection('parties').doc(partyId).get();
  double openingBalance = party.data()?['openingBalance'] ?? 0.0;
  
  if (partyType == 'customer') {
    // For customers: outstanding = opening + sales - receipts
    final invoicesQuery = await FirebaseFirestore.instance
      .collection('invoices')
      .where('partyId', isEqualTo: partyId)
      .where('invoiceType', isEqualTo: 'sales')
      .get();
    
    double totalSales = invoicesQuery.docs.fold(0.0, (sum, doc) => sum + doc.data()['totalAmount']);
    
    final paymentsQuery = await FirebaseFirestore.instance
      .collection('payments')
      .where('partyId', isEqualTo: partyId)
      .where('paymentType', isEqualTo: 'receipt')
      .get();
    
    double totalReceipts = paymentsQuery.docs.fold(0.0, (sum, doc) => sum + doc.data()['totalAmount']);
    
    return openingBalance + totalSales - totalReceipts;
  } else {
    // For suppliers: outstanding = opening + purchases - payments
    final invoicesQuery = await FirebaseFirestore.instance
      .collection('invoices')
      .where('partyId', isEqualTo: partyId)
      .where('invoiceType', isEqualTo: 'purchase')
      .get();
    
    double totalPurchases = invoicesQuery.docs.fold(0.0, (sum, doc) => sum + doc.data()['totalAmount']);
    
    final paymentsQuery = await FirebaseFirestore.instance
      .collection('payments')
      .where('partyId', isEqualTo: partyId)
      .where('paymentType', isEqualTo: 'payment')
      .get();
    
    double totalPayments = paymentsQuery.docs.fold(0.0, (sum, doc) => sum + doc.data()['totalAmount']);
    
    return openingBalance + totalPurchases - totalPayments;
  }
}
```

### Payment Allocation Logic
```dart
Future<void> recordPayment({
  required String userId,
  required String partyId,
  required String partyName,
  required String paymentType,
  required DateTime paymentDate,
  required double totalAmount,
  required String paymentMethod,
  String? referenceNumber,
  String? notes,
  required List<PaymentAllocation> allocations,
}) async {
  // Validate total allocated equals total payment
  double totalAllocated = allocations.fold(0.0, (sum, alloc) => sum + alloc.allocatedAmount);
  if (totalAllocated != totalAmount) {
    throw Exception('Total allocated must equal total payment amount');
  }
  
  // Validate each allocation doesn't exceed invoice outstanding
  for (var allocation in allocations) {
    final invoice = await FirebaseFirestore.instance
      .collection('invoices')
      .doc(allocation.invoiceId)
      .get();
    
    double outstanding = invoice.data()?['outstandingAmount'] ?? 0.0;
    if (allocation.allocatedAmount > outstanding) {
      throw Exception('Allocated amount exceeds invoice outstanding');
    }
  }
  
  // Create payment document
  final paymentRef = await FirebaseFirestore.instance.collection('payments').add({
    'userId': userId,
    'partyId': partyId,
    'partyName': partyName,
    'paymentType': paymentType,
    'paymentDate': Timestamp.fromDate(paymentDate),
    'totalAmount': totalAmount,
    'paymentMethod': paymentMethod,
    'referenceNumber': referenceNumber,
    'notes': notes,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
  
  // Create allocation documents
  for (var allocation in allocations) {
    await paymentRef.collection('allocations').add({
      'invoiceId': allocation.invoiceId,
      'invoiceNumber': allocation.invoiceNumber,
      'allocatedAmount': allocation.allocatedAmount,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Note: Cloud Function will automatically update invoice payment status
}
```

### Overdue Invoice Detection
```dart
bool isInvoiceOverdue(Map<String, dynamic> invoice) {
  if (invoice['paymentStatus'] == 'paid') return false;
  if (invoice['dueDate'] == null) return false;
  
  DateTime dueDate = (invoice['dueDate'] as Timestamp).toDate();
  DateTime today = DateTime.now();
  
  return dueDate.isBefore(today);
}

int daysOverdue(Map<String, dynamic> invoice) {
  if (!isInvoiceOverdue(invoice)) return 0;
  
  DateTime dueDate = (invoice['dueDate'] as Timestamp).toDate();
  DateTime today = DateTime.now();
  
  return today.difference(dueDate).inDays;
}
```

---

## State Management Recommendations

### Using Riverpod (Recommended)

#### Firebase Providers

```dart
// lib/core/firebase_providers.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});
```

#### Auth Provider

```dart
// lib/features/auth/providers/auth_provider.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(firebaseAuthProvider));
});

class AuthRepository {
  final FirebaseAuth _auth;
  
  AuthRepository(this._auth);
  
  User? get currentUser => _auth.currentUser;
  
  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }
  
  Future<UserCredential> signUpWithEmailPassword(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }
  
  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
```

#### Data Providers

```dart
// lib/features/parties/providers/parties_provider.dart
final partiesProvider = StreamProvider.family<List<Party>, String>((ref, userId) {
  return FirebaseFirestore.instance
    .collection('parties')
    .where('userId', isEqualTo: userId)
    .orderBy('name')
    .snapshots()
    .map((snapshot) => snapshot.docs.map((doc) => Party.fromFirestore(doc)).toList());
});

// lib/features/invoices/providers/invoices_provider.dart
final invoicesProvider = StreamProvider.family<List<Invoice>, InvoiceQuery>((ref, query) {
  Query<Map<String, dynamic>> firestoreQuery = FirebaseFirestore.instance
    .collection('invoices')
    .where('userId', isEqualTo: query.userId)
    .where('invoiceType', isEqualTo: query.invoiceType);
  
  if (query.partyId != null) {
    firestoreQuery = firestoreQuery.where('partyId', isEqualTo: query.partyId);
  }
  
  if (query.paymentStatus != null) {
    firestoreQuery = firestoreQuery.where('paymentStatus', isEqualTo: query.paymentStatus);
  }
  
  firestoreQuery = firestoreQuery.orderBy('invoiceDate', descending: true);
  
  return firestoreQuery
    .snapshots()
    .map((snapshot) => snapshot.docs.map((doc) => Invoice.fromFirestore(doc)).toList());
});

// lib/features/payments/providers/payments_provider.dart
final paymentsProvider = StreamProvider.family<List<Payment>, PaymentQuery>((ref, query) {
  return FirebaseFirestore.instance
    .collection('payments')
    .where('userId', isEqualTo: query.userId)
    .where('paymentType', isEqualTo: query.paymentType)
    .orderBy('paymentDate', descending: true)
    .snapshots()
    .map((snapshot) => snapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList());
});

// lib/features/dashboard/providers/dashboard_provider.dart
final dashboardMetricsProvider = FutureProvider.family<DashboardMetrics, DashboardQuery>((ref, query) async {
  return await calculateDashboardMetrics(query.userId, query.startDate, query.endDate);
});
```

#### Repository Pattern

```dart
// lib/features/parties/repositories/party_repository.dart
class PartyRepository {
  final FirebaseFirestore _firestore;
  
  PartyRepository(this._firestore);
  
  Future<void> createParty(Party party) async {
    await _firestore.collection('parties').add(party.toMap());
  }
  
  Future<void> updateParty(String partyId, Party party) async {
    await _firestore.collection('parties').doc(partyId).update(party.toMap());
  }
  
  Future<void> deleteParty(String partyId) async {
    await _firestore.collection('parties').doc(partyId).delete();
  }
  
  Future<Party> getParty(String partyId) async {
    final doc = await _firestore.collection('parties').doc(partyId).get();
    return Party.fromFirestore(doc);
  }
}
```

---

## API Integration (Firebase/Firestore)

### Authentication Flow

```dart
// Sign Up
Future<void> signUp(String email, String password, String displayName) async {
  try {
    // Create user
    final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // Send email verification
    await credential.user?.sendEmailVerification();
    
    // Create user profile in Firestore
    await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
      'email': email,
      'displayName': displayName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'themePreference': 'light',
      'invoicePrefix': 'INV',
      'currency': 'INR',
    });
  } on FirebaseAuthException catch (e) {
    if (e.code == 'weak-password') {
      throw Exception('The password provided is too weak.');
    } else if (e.code == 'email-already-in-use') {
      throw Exception('The account already exists for that email.');
    }
    throw Exception(e.message);
  }
}

// Sign In
Future<UserCredential> signIn(String email, String password) async {
  try {
    return await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  } on FirebaseAuthException catch (e) {
    if (e.code == 'user-not-found') {
      throw Exception('No user found for that email.');
    } else if (e.code == 'wrong-password') {
      throw Exception('Wrong password provided.');
    }
    throw Exception(e.message);
  }
}

// Sign Out
Future<void> signOut() async {
  await FirebaseAuth.instance.signOut();
}

// Password Reset
Future<void> resetPassword(String email) async {
  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
}

// Listen to auth state
Stream<User?> authStateChanges() {
  return FirebaseAuth.instance.authStateChanges();
}
```

### CRUD Operations Example (Parties)

```dart
// Create
Future<String> createParty(Party party) async {
  final docRef = await FirebaseFirestore.instance.collection('parties').add({
    'userId': party.userId,
    'partyType': party.partyType,
    'name': party.name,
    'contactPerson': party.contactPerson,
    'phoneNumber': party.phoneNumber,
    'email': party.email,
    'address': party.address,
    'gstNumber': party.gstNumber,
    'openingBalance': party.openingBalance,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
  return docRef.id;
}

// Read (with filter)
Stream<List<Party>> getParties(String userId, String partyType) {
  return FirebaseFirestore.instance
    .collection('parties')
    .where('userId', isEqualTo: userId)
    .where('partyType', isEqualTo: partyType)
    .orderBy('name')
    .snapshots()
    .map((snapshot) => snapshot.docs.map((doc) => Party.fromFirestore(doc)).toList());
}

// Read single party
Future<Party> getParty(String partyId) async {
  final doc = await FirebaseFirestore.instance.collection('parties').doc(partyId).get();
  if (!doc.exists) {
    throw Exception('Party not found');
  }
  return Party.fromFirestore(doc);
}

// Update
Future<void> updateParty(String partyId, Map<String, dynamic> updates) async {
  updates['updatedAt'] = FieldValue.serverTimestamp();
  await FirebaseFirestore.instance.collection('parties').doc(partyId).update(updates);
}

// Delete
Future<void> deleteParty(String partyId) async {
  await FirebaseFirestore.instance.collection('parties').doc(partyId).delete();
}

// Model class
class Party {
  final String id;
  final String userId;
  final String partyType;
  final String name;
  final String? contactPerson;
  final String? phoneNumber;
  final String? email;
  final String? address;
  final String? gstNumber;
  final double openingBalance;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  Party({
    required this.id,
    required this.userId,
    required this.partyType,
    required this.name,
    this.contactPerson,
    this.phoneNumber,
    this.email,
    this.address,
    this.gstNumber,
    this.openingBalance = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory Party.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Party(
      id: doc.id,
      userId: data['userId'] ?? '',
      partyType: data['partyType'] ?? '',
      name: data['name'] ?? '',
      contactPerson: data['contactPerson'],
      phoneNumber: data['phoneNumber'],
      email: data['email'],
      address: data['address'],
      gstNumber: data['gstNumber'],
      openingBalance: (data['openingBalance'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'partyType': partyType,
      'name': name,
      'contactPerson': contactPerson,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'gstNumber': gstNumber,
      'openingBalance': openingBalance,
    };
  }
}
```

### Complex Queries (Invoices with Items)

```dart
// Create invoice with items
Future<String> createInvoice(Invoice invoice, List<InvoiceItem> items) async {
  final db = FirebaseFirestore.instance;
  
  // Create invoice document
  final invoiceRef = await db.collection('invoices').add(invoice.toMap());
  
  // Create item subcollection documents
  final batch = db.batch();
  for (var item in items) {
    final itemRef = invoiceRef.collection('items').doc();
    batch.set(itemRef, item.toMap());
  }
  await batch.commit();
  
  return invoiceRef.id;
}

// Get invoice with items
Future<InvoiceWithItems> getInvoiceWithItems(String invoiceId) async {
  // Get invoice
  final invoiceDoc = await FirebaseFirestore.instance
    .collection('invoices')
    .doc(invoiceId)
    .get();
  
  if (!invoiceDoc.exists) {
    throw Exception('Invoice not found');
  }
  
  final invoice = Invoice.fromFirestore(invoiceDoc);
  
  // Get items
  final itemsSnapshot = await invoiceDoc.reference.collection('items').get();
  final items = itemsSnapshot.docs.map((doc) => InvoiceItem.fromFirestore(doc)).toList();
  
  return InvoiceWithItems(invoice: invoice, items: items);
}

// Update invoice and items
Future<void> updateInvoice(String invoiceId, Invoice invoice, List<InvoiceItem> items) async {
  final db = FirebaseFirestore.instance;
  final invoiceRef = db.collection('invoices').doc(invoiceId);
  
  // Update invoice
  await invoiceRef.update(invoice.toMap());
  
  // Delete existing items
  final existingItems = await invoiceRef.collection('items').get();
  final batch = db.batch();
  for (var doc in existingItems.docs) {
    batch.delete(doc.reference);
  }
  
  // Add new items
  for (var item in items) {
    final itemRef = invoiceRef.collection('items').doc();
    batch.set(itemRef, item.toMap());
  }
  
  await batch.commit();
}
```

### Real-time Subscriptions

```dart
// Listen to invoice changes in real-time
Stream<List<Invoice>> streamInvoices(String userId, String invoiceType) {
  return FirebaseFirestore.instance
    .collection('invoices')
    .where('userId', isEqualTo: userId)
    .where('invoiceType', isEqualTo: invoiceType)
    .orderBy('invoiceDate', descending: true)
    .limit(50)
    .snapshots()
    .map((snapshot) => snapshot.docs.map((doc) => Invoice.fromFirestore(doc)).toList());
}

// Use in widget
@override
Widget build(BuildContext context) {
  final userId = FirebaseAuth.instance.currentUser!.uid;
  
  return StreamBuilder<List<Invoice>>(
    stream: streamInvoices(userId, 'sales'),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Text('Error: ${snapshot.error}');
      }
      
      if (!snapshot.hasData) {
        return CircularProgressIndicator();
      }
      
      final invoices = snapshot.data!;
      return ListView.builder(
        itemCount: invoices.length,
        itemBuilder: (context, index) {
          return InvoiceCard(invoice: invoices[index]);
        },
      );
    },
  );
}

// Or use Riverpod StreamProvider
final invoicesStreamProvider = StreamProvider.autoDispose<List<Invoice>>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) throw Exception('Not authenticated');
  
  return FirebaseFirestore.instance
    .collection('invoices')
    .where('userId', isEqualTo: userId)
    .where('invoiceType', isEqualTo: 'sales')
    .orderBy('invoiceDate', descending: true)
    .snapshots()
    .map((snapshot) => snapshot.docs.map((doc) => Invoice.fromFirestore(doc)).toList());
});
```

### File Upload (Profile Photo)

```dart
// Upload avatar to Firebase Storage
Future<String> uploadAvatar(File imageFile) async {
  final userId = FirebaseAuth.instance.currentUser!.uid;
  final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
  final storageRef = FirebaseStorage.instance.ref().child('avatars/$userId/$fileName');
  
  // Upload file
  final uploadTask = storageRef.putFile(
    imageFile,
    SettableMetadata(contentType: 'image/jpeg'),
  );
  
  // Wait for upload to complete
  final snapshot = await uploadTask.whenComplete(() {});
  
  // Get download URL
  final downloadUrl = await snapshot.ref.getDownloadURL();
  
  // Update user profile
  await FirebaseFirestore.instance.collection('users').doc(userId).update({
    'avatarUrl': downloadUrl,
    'updatedAt': FieldValue.serverTimestamp(),
  });
  
  return downloadUrl;
}

// Delete old avatar
Future<void> deleteAvatar(String avatarUrl) async {
  try {
    final ref = FirebaseStorage.instance.refFromURL(avatarUrl);
    await ref.delete();
  } catch (e) {
    print('Error deleting avatar: $e');
  }
}
```

### Pagination

```dart
// Paginated invoice list
class InvoiceListController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;
  final String invoiceType;
  final int pageSize;
  
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  List<Invoice> _invoices = [];
  
  InvoiceListController({
    required this.userId,
    required this.invoiceType,
    this.pageSize = 20,
  });
  
  List<Invoice> get invoices => _invoices;
  bool get hasMore => _hasMore;
  
  Future<void> loadMore() async {
    if (!_hasMore) return;
    
    Query query = _firestore
      .collection('invoices')
      .where('userId', isEqualTo: userId)
      .where('invoiceType', isEqualTo: invoiceType)
      .orderBy('invoiceDate', descending: true)
      .limit(pageSize);
    
    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }
    
    final snapshot = await query.get();
    
    if (snapshot.docs.isEmpty) {
      _hasMore = false;
      return;
    }
    
    _lastDocument = snapshot.docs.last;
    _invoices.addAll(snapshot.docs.map((doc) => Invoice.fromFirestore(doc)).toList());
    
    if (snapshot.docs.length < pageSize) {
      _hasMore = false;
    }
  }
  
  void reset() {
    _invoices = [];
    _lastDocument = null;
    _hasMore = true;
  }
}
```

---

## Error Handling & Validation

### Form Validation

```dart
// Email validation
String? validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'Email is required';
  }
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!emailRegex.hasMatch(value)) {
    return 'Enter a valid email';
  }
  return null;
}

// Phone validation
String? validatePhone(String? value) {
  if (value == null || value.isEmpty) {
    return null; // Optional field
  }
  final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
  if (!phoneRegex.hasMatch(value)) {
    return 'Enter a valid phone number';
  }
  return null;
}

// Password validation
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Password is required';
  }
  if (value.length < 8) {
    return 'Password must be at least 8 characters';
  }
  if (!value.contains(RegExp(r'[A-Z]'))) {
    return 'Password must contain uppercase letter';
  }
  if (!value.contains(RegExp(r'[a-z]'))) {
    return 'Password must contain lowercase letter';
  }
  if (!value.contains(RegExp(r'[0-9]'))) {
    return 'Password must contain number';
  }
  return null;
}

// Required field validation
String? validateRequired(String? value, String fieldName) {
  if (value == null || value.isEmpty) {
    return '$fieldName is required';
  }
  return null;
}

// Numeric validation
String? validateNumeric(String? value, {double? min, double? max}) {
  if (value == null || value.isEmpty) {
    return 'Value is required';
  }
  final number = double.tryParse(value);
  if (number == null) {
    return 'Enter a valid number';
  }
  if (min != null && number < min) {
    return 'Value must be at least $min';
  }
  if (max != null && number > max) {
    return 'Value must be at most $max';
  }
  return null;
}
```

### Firebase Error Handling

```dart
// Auth error handling
Future<void> handleAuthOperation(Future<void> Function() operation) async {
  try {
    await operation();
  } on FirebaseAuthException catch (e) {
    String message;
    switch (e.code) {
      case 'user-not-found':
        message = 'No user found with this email.';
        break;
      case 'wrong-password':
        message = 'Wrong password provided.';
        break;
      case 'email-already-in-use':
        message = 'An account already exists with this email.';
        break;
      case 'weak-password':
        message = 'The password is too weak.';
        break;
      case 'invalid-email':
        message = 'The email address is invalid.';
        break;
      case 'user-disabled':
        message = 'This account has been disabled.';
        break;
      case 'too-many-requests':
        message = 'Too many attempts. Please try again later.';
        break;
      default:
        message = 'Authentication failed: ${e.message}';
    }
    throw Exception(message);
  } catch (e) {
    throw Exception('An unexpected error occurred: $e');
  }
}

// Firestore error handling
Future<T> handleFirestoreOperation<T>(Future<T> Function() operation) async {
  try {
    return await operation();
  } on FirebaseException catch (e) {
    String message;
    switch (e.code) {
      case 'permission-denied':
        message = 'You don\'t have permission to perform this action.';
        break;
      case 'unavailable':
        message = 'Service is currently unavailable. Please try again.';
        break;
      case 'not-found':
        message = 'The requested document was not found.';
        break;
      case 'already-exists':
        message = 'A document with this ID already exists.';
        break;
      default:
        message = 'Database error: ${e.message}';
    }
    throw Exception(message);
  } catch (e) {
    throw Exception('An unexpected error occurred: $e');
  }
}

// Usage example
Future<void> createParty(Party party) async {
  try {
    await handleFirestoreOperation(() async {
      await FirebaseFirestore.instance.collection('parties').add(party.toMap());
    });
    // Show success message
  } catch (e) {
    // Show error message to user
    showErrorSnackBar(e.toString());
  }
}
```

### Network Error Handling

```dart
// Check internet connectivity
import 'package:connectivity_plus/connectivity_plus.dart';

Future<bool> hasInternetConnection() async {
  final connectivityResult = await Connectivity().checkConnectivity();
  return connectivityResult != ConnectivityResult.none;
}

// Wrap operations with connectivity check
Future<T> withConnectivityCheck<T>(Future<T> Function() operation) async {
  if (!await hasInternetConnection()) {
    throw Exception('No internet connection. Please check your network.');
  }
  return await operation();
}
```

---

## Navigation & Routing

### Route Structure (using Go Router)

```dart
// lib/config/routes.dart
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

final router = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;
    final isLoggingIn = state.location == '/login' || 
                        state.location == '/register' ||
                        state.location == '/forgot-password';
    
    // Redirect to login if not logged in and not on auth pages
    if (!isLoggedIn && !isLoggingIn && state.location != '/splash') {
      return '/login';
    }
    
    // Redirect to home if logged in and on auth pages
    if (isLoggedIn && isLoggingIn) {
      return '/';
    }
    
    return null;
  },
  refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
  routes: [
    // Splash
    GoRoute(
      path: '/splash',
      builder: (context, state) => SplashScreen(),
    ),
    
    // Auth routes
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => ForgotPasswordScreen(),
    ),
    
    // Main app with bottom navigation
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => DashboardScreen(),
        ),
        GoRoute(
          path: '/invoices',
          builder: (context, state) => InvoiceListScreen(),
        ),
        GoRoute(
          path: '/parties',
          builder: (context, state) => PartyListScreen(),
        ),
        GoRoute(
          path: '/payments',
          builder: (context, state) => PaymentHistoryScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => ProfileScreen(),
        ),
      ],
    ),
    
    // Invoice routes
    GoRoute(
      path: '/invoice/:id',
      builder: (context, state) => InvoiceDetailScreen(
        invoiceId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/invoice/add',
      builder: (context, state) => AddInvoiceScreen(
        invoiceType: state.queryParameters['type'] ?? 'sales',
      ),
    ),
    GoRoute(
      path: '/invoice/:id/edit',
      builder: (context, state) => EditInvoiceScreen(
        invoiceId: state.pathParameters['id']!,
      ),
    ),
    
    // Party routes
    GoRoute(
      path: '/party/:id',
      builder: (context, state) => PartyDetailScreen(
        partyId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/party/add',
      builder: (context, state) => AddPartyScreen(
        partyType: state.queryParameters['type'] ?? 'customer',
      ),
    ),
    GoRoute(
      path: '/party/:id/edit',
      builder: (context, state) => EditPartyScreen(
        partyId: state.pathParameters['id']!,
      ),
    ),
    
    // Payment route
    GoRoute(
      path: '/payment/add',
      builder: (context, state) => RecordPaymentScreen(
        partyId: state.queryParameters['partyId'],
        invoiceId: state.queryParameters['invoiceId'],
      ),
    ),
    
    // Profile routes
    GoRoute(
      path: '/profile/edit',
      builder: (context, state) => EditProfileScreen(),
    ),
    GoRoute(
      path: '/profile/change-password',
      builder: (context, state) => ChangePasswordScreen(),
    ),
    GoRoute(
      path: '/profile/business-settings',
      builder: (context, state) => BusinessSettingsScreen(),
    ),
    GoRoute(
      path: '/profile/theme',
      builder: (context, state) => ThemeSettingsScreen(),
    ),
    GoRoute(
      path: '/profile/notifications',
      builder: (context, state) => NotificationsSettingsScreen(),
    ),
    GoRoute(
      path: '/profile/export',
      builder: (context, state) => ExportDataScreen(),
    ),
    GoRoute(
      path: '/profile/about',
      builder: (context, state) => AboutScreen(),
    ),
  ],
  errorBuilder: (context, state) => ErrorScreen(error: state.error),
);

// Helper class for auth state refresh
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
```

### Back Button Behavior

```dart
// Handle Android back button on main screens
class MainScaffold extends StatelessWidget {
  final Widget child;
  
  const MainScaffold({required this.child});
  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Show confirmation dialog before exiting app
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Exit App'),
            content: Text('Do you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Exit'),
              ),
            ],
          ),
        ) ?? false;
      },
      child: Scaffold(
        body: child,
        bottomNavigationBar: BottomNavBar(),
      ),
    );
  }
}
```

---

## UI/UX Guidelines

### Loading States

```dart
// Shimmer effect for lists
import 'package:shimmer/shimmer.dart';

class InvoiceListShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.all(8.0),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Button loading state
ElevatedButton(
  onPressed: isLoading ? null : () => handleSubmit(),
  child: isLoading 
    ? SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      )
    : Text('Save'),
)
```

### Empty States

```dart
class EmptyState extends StatelessWidget {
  final String imagePath;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  
  const EmptyState({
    required this.imagePath,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, height: 200),
            SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF385C),
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

### Success/Error Feedback

```dart
// Show snackbar
void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.white),
          SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Color(0xFF00A699),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 3),
    ),
  );
}

void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(Icons.error, color: Colors.white),
          SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Color(0xFFFF385C),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 4),
    ),
  );
}

// Confirmation dialog
Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
}) async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFFF385C),
          ),
          child: Text(confirmText),
        ),
      ],
    ),
  ) ?? false;
}
```

### Animations & Transitions

```dart
// Page transition
CustomRoute<T>(
  builder: (context) => NextScreen(),
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    const begin = Offset(1.0, 0.0);
    const end = Offset.zero;
    const curve = Curves.easeInOut;
    
    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    var offsetAnimation = animation.drive(tween);
    
    return SlideTransition(
      position: offsetAnimation,
      child: child,
    );
  },
)

// List item animation
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

AnimationConfiguration.staggeredList(
  position: index,
  duration: const Duration(milliseconds: 375),
  child: SlideAnimation(
    verticalOffset: 50.0,
    child: FadeInAnimation(
      child: InvoiceCard(invoice: invoice),
    ),
  ),
)

// Button press animation
GestureDetector(
  onTapDown: (_) => setState(() => _isPressed = true),
  onTapUp: (_) => setState(() => _isPressed = false),
  onTapCancel: () => setState(() => _isPressed = false),
  onTap: handleTap,
  child: AnimatedScale(
    scale: _isPressed ? 0.95 : 1.0,
    duration: Duration(milliseconds: 100),
    child: Container(
      // Button content
    ),
  ),
)
```

---

## Testing Strategy

### Unit Tests

```dart
// test/models/invoice_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Invoice Calculations', () {
    test('Calculate subtotal correctly', () {
      final items = [
        InvoiceItem(description: 'Item 1', quantity: 2, rate: 100, amount: 200),
        InvoiceItem(description: 'Item 2', quantity: 1, rate: 150, amount: 150),
      ];
      
      final subtotal = calculateSubtotal(items);
      
      expect(subtotal, 350.0);
    });
    
    test('Calculate discount amount for percentage', () {
      final discountAmount = calculateDiscountAmount(1000, 'percentage', 10);
      
      expect(discountAmount, 100.0);
    });
    
    test('Calculate payment status', () {
      expect(calculatePaymentStatus(1000, 0), 'unpaid');
      expect(calculatePaymentStatus(1000, 500), 'partial');
      expect(calculatePaymentStatus(1000, 1000), 'paid');
    });
  });
}
```

### Widget Tests

```dart
// test/widgets/invoice_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('InvoiceCard displays invoice information', (WidgetTester tester) async {
    final invoice = Invoice(
      id: '1',
      invoiceNumber: 'INV-001',
      totalAmount: 1000,
      paymentStatus: 'unpaid',
      // ... other fields
    );
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InvoiceCard(invoice: invoice),
        ),
      ),
    );
    
    expect(find.text('INV-001'), findsOneWidget);
    expect(find.text('\$1,000'), findsOneWidget);
    expect(find.text('Unpaid'), findsOneWidget);
  });
}
```

### Integration Tests

```dart
// integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('end-to-end test', () {
    testWidgets('Login and create invoice flow', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      
      // Wait for splash screen
      await tester.pumpAndSettle(Duration(seconds: 2));
      
      // Enter login credentials
      await tester.enterText(find.byKey(Key('emailField')), 'test@example.com');
      await tester.enterText(find.byKey(Key('passwordField')), 'password123');
      await tester.tap(find.byKey(Key('loginButton')));
      
      // Wait for navigation
      await tester.pumpAndSettle();
      
      // Verify dashboard is shown
      expect(find.text('Dashboard'), findsOneWidget);
      
      // Navigate to invoices
      await tester.tap(find.byIcon(Icons.description));
      await tester.pumpAndSettle();
      
      // Tap FAB to create invoice
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      
      // Fill invoice form
      // ... add more test steps
    });
  });
}
```

---

## Deployment Checklist

### Pre-Launch
- [ ] All Firebase collections and indexes created
- [ ] Firestore security rules deployed
- [ ] Storage security rules deployed
- [ ] Cloud Functions deployed (if using)
- [ ] Firebase project configured for Android and iOS
- [ ] `google-services.json` added to Android project
- [ ] `GoogleService-Info.plist` added to iOS project
- [ ] App icon and splash screen finalized
- [ ] App name and package identifier set
- [ ] Privacy policy and terms of service prepared
- [ ] All API keys secured (use firebase_options.dart)
- [ ] Remove debug logs and print statements
- [ ] Test on multiple devices (Android/iOS)
- [ ] Test on different screen sizes
- [ ] Performance profiling completed
- [ ] Memory leak checks

### Android Release
- [ ] Generate release keystore
- [ ] Configure signing in build.gradle
- [ ] Set app version and build number
- [ ] Enable ProGuard/R8 obfuscation
- [ ] Build release APK/AAB
- [ ] Test release build
- [ ] Prepare Play Store listing (screenshots, description)
- [ ] Upload to Google Play Console

### iOS Release
- [ ] Configure Xcode project
- [ ] Set app version and build number
- [ ] Configure signing certificates and provisioning profiles
- [ ] Build release IPA
- [ ] Test release build
- [ ] Prepare App Store listing (screenshots, description)
- [ ] Upload to App Store Connect via Xcode or Transporter

### Post-Launch
- [ ] Monitor crash reports (Firebase Crashlytics)
- [ ] Monitor analytics (Firebase Analytics)
- [ ] Collect user feedback
- [ ] Plan updates and new features

---

## Future Enhancements (Optional)

1. **Recurring Invoices**: Auto-generate invoices on schedule
2. **Invoice Templates**: Customizable invoice designs
3. **Multi-Currency Support**: Handle multiple currencies with exchange rates
4. **Inventory Management**: Track products/services
5. **Expense Tracking**: Non-invoice expenses
6. **Bank Integration**: Auto-import bank transactions
7. **Tax Reports**: GST returns, profit & loss statements
8. **Multi-User Access**: Team collaboration with roles
9. **Client Portal**: Customers can view their invoices online
10. **Payment Gateway Integration**: Accept online payments (Razorpay, Stripe)
11. **WhatsApp/Email Integration**: Send invoices via WhatsApp or email
12. **Barcode/QR Code Scanner**: For inventory
13. **Biometric Authentication**: Fingerprint/Face ID login
14. **Offline Mode**: Full offline support with sync
15. **Advanced Analytics**: More charts and insights
16. **Cloud Backup**: Automated backups
17. **Multi-Company Support**: Manage multiple businesses

---

## Important Notes

### Security Considerations
- **Never store sensitive data locally** - Use Firebase/Firestore
- **Validate all inputs** on client and server (use security rules)
- **Use Firestore security rules** to enforce access control
- **Sanitize user inputs** to prevent injection attacks
- **Use HTTPS** for all API calls (Firebase default)
- **Secure file uploads** - Validate file types and sizes in storage rules
- **Implement rate limiting** on Cloud Functions
- **Don't log sensitive information** (passwords, tokens)
- **Use Firebase App Check** to protect against abuse

### Development Best Practices
- **Code Organization**: Feature-based folder structure
- **Naming Conventions**: Follow Dart conventions (camelCase for variables, PascalCase for classes)
- **Documentation**: Comment complex logic
- **Version Control**: Use Git with meaningful commit messages
- **Environment Separation**: Dev and production Firebase projects
- **Code Reviews**: Review before merging
- **Linting**: Use `flutter analyze` and fix all warnings
- **Formatting**: Use `dart format`

### Folder Structure Suggestion
```
lib/
├── main.dart
├── app.dart
├── config/
│   ├── theme.dart
│   ├── routes.dart
│   └── constants.dart
├── core/
│   ├── firebase_providers.dart
│   ├── utils/
│   └── extensions/
├── features/
│   ├── auth/
│   │   ├── screens/
│   │   ├── widgets/
│   │   ├── providers/
│   │   ├── repositories/
│   │   └── models/
│   ├── dashboard/
│   ├── invoices/
│   ├── parties/
│   ├── payments/
│   └── profile/
├── shared/
│   ├── widgets/
│   ├── models/
│   └── services/
└── assets/
    ├── images/
    ├── icons/
    └── fonts/
```

---

## Success Criteria

Your Flutter app is production-ready when:
1. ✅ All authentication flows work smoothly without errors
2. ✅ All CRUD operations work for parties, invoices, and payments
3. ✅ Multi-invoice payment allocation works correctly
4. ✅ Dashboard calculations are accurate
5. ✅ All screens are responsive and match design specifications
6. ✅ Theme switching works without requiring restart
7. ✅ Navigation is intuitive with proper back button handling
8. ✅ Forms have proper validation and error handling
9. ✅ No crashes or critical bugs
10. ✅ App performs smoothly with good load times
11. ✅ All Firestore security rules are correctly configured
12. ✅ File uploads work correctly
13. ✅ UI matches Airbnb design aesthetic
14. ✅ Empty states and loading states are polished
15. ✅ App has been tested on multiple devices

---

## Quick Start Command

When providing this document to Claude AI, start with:

**"Please build a Flutter invoice management application based on the complete specification provided. Follow the exact database schema, UI screens, and business logic outlined. Use Firebase/Firestore for backend, Riverpod for state management, and Go Router for navigation. Implement the Airbnb-style design with the coral primary color (#FF385C). Start by setting up the Firebase configuration and then build the authentication flow."**

---

## Contact & Support

For questions or clarifications during development:
- Refer to this specification document
- Check Firebase documentation: https://firebase.google.com/docs
- Check Flutter documentation: https://flutter.dev/docs
- Check Riverpod documentation: https://riverpod.dev

---

**Document Version**: 2.0 (Firebase/Firestore)
**Last Updated**: February 27, 2026
**Created for**: Flutter Development with Claude AI

---

## Appendix: Sample Data for Testing

### Sample Customers
1. John Smith (john@email.com, +1-555-0101)
2. Sarah Johnson (sarah@email.com, +1-555-0102)
3. Michael Brown (michael@email.com, +1-555-0103)

### Sample Suppliers
1. ABC Supplies Inc. (abc@supplier.com, +1-555-0201)
2. XYZ Wholesale (xyz@supplier.com, +1-555-0202)

### Sample Sales Invoices
- INV-001: John Smith, $1,500, Due: 30 days
- INV-002: Sarah Johnson, $2,300, Due: 15 days
- INV-003: Michael Brown, $850, Due: 45 days

### Sample Payments
- Receipt from John Smith: $1,000 (partial payment for INV-001)
- Receipt from Sarah Johnson: $2,300 (full payment for INV-002)

Use this sample data to populate your test Firebase project and verify all features work correctly.

---

**END OF SPECIFICATION DOCUMENT**
