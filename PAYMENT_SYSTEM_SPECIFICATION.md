# Payment System Specification - Invoice Management App

## Document Purpose
This document provides a complete, unambiguous specification for the payment recording and allocation system. Use this to understand how payments work in relation to parties, invoices, and the overall flow.

---

## Core Concepts Overview

### 1. The Data Hierarchy
```
USER (authenticated person)
  └── PARTIES (Customers & Suppliers)
       └── INVOICES (Sales & Purchase)
            └── PAYMENTS (Receipts & Payments)
                 └── ALLOCATIONS (linking payments to invoices)
```

### 2. Key Terminology

| Term | Meaning |
|------|---------|
| **Party** | A customer (who owes you money) OR a supplier (whom you owe money) |
| **Customer** | A party of type "customer" - they buy from you |
| **Supplier** | A party of type "supplier" - you buy from them |
| **Sales Invoice** | Invoice you create when selling to a customer |
| **Purchase Invoice** | Invoice you create when buying from a supplier |
| **Receipt** | Money you RECEIVE from a customer (for sales invoices) |
| **Payment** | Money you PAY to a supplier (for purchase invoices) |
| **Allocation** | Assigning a payment amount to a specific invoice |
| **Outstanding Amount** | How much is still unpaid on an invoice |
| **Partial Payment** | When only part of an invoice is paid |
| **Full Payment** | When an invoice is completely paid |

---

## Invoice System (Foundation for Payments)

### Invoice Types and Their Direction

#### Sales Invoice (Money Coming IN)
- Created for: **Customers**
- Direction: Customer owes YOU money
- Payment type: **Receipt** (you receive money)
- Invoice outstanding: Shows as **RECEIVABLE** (positive)

#### Purchase Invoice (Money Going OUT)
- Created for: **Suppliers**
- Direction: YOU owe Supplier money
- Payment type: **Payment** (you pay money)
- Invoice outstanding: Shows as **PAYABLE** (positive)

### Invoice Payment Status

An invoice can have 3 payment statuses:

1. **Unpaid**: `paidAmount = 0` and `outstandingAmount = totalAmount`
2. **Partial**: `paidAmount > 0` and `paidAmount < totalAmount`
3. **Paid**: `paidAmount >= totalAmount` and `outstandingAmount = 0`

### Invoice Data Structure (Firestore)

```javascript
// Collection: invoices/{invoiceId}
{
  id: "invoice_abc123",
  userId: "user_xyz789",
  partyId: "party_def456",
  partyName: "John Smith", // Denormalized for quick display
  invoiceType: "sales", // or "purchase"
  invoiceNumber: "INV-00001",
  invoiceDate: Timestamp,
  dueDate: Timestamp, // optional
  
  // Line items are in subcollection (see below)
  
  // Calculations
  subtotal: 1000.00,
  discountType: "percentage", // or "fixed" or null
  discountValue: 10, // 10% or $10
  discountAmount: 100.00,
  taxPercentage: 18,
  taxAmount: 162.00, // calculated on (subtotal - discount)
  totalAmount: 1062.00,
  
  // Payment tracking
  paidAmount: 0, // Updated automatically via Cloud Function
  outstandingAmount: 1062.00, // totalAmount - paidAmount
  paymentStatus: "unpaid", // "unpaid" | "partial" | "paid"
  
  createdAt: Timestamp,
  updatedAt: Timestamp
}

// Subcollection: invoices/{invoiceId}/items/{itemId}
{
  id: "item_001",
  description: "Product/Service Name",
  quantity: 2,
  rate: 500.00,
  amount: 1000.00, // quantity * rate
  createdAt: Timestamp
}
```

---

## Payment System (Core Focus)

### Payment Types

| Payment Type | Used For | Party Type | Money Direction | Updates |
|-------------|----------|------------|-----------------|---------|
| **Receipt** | Sales Invoices | Customer | Money IN | Reduces customer's outstanding (receivable) |
| **Payment** | Purchase Invoices | Supplier | Money OUT | Reduces supplier's outstanding (payable) |

### Payment Allocation Concept

**Critical Understanding**: A single payment can be split across MULTIPLE invoices.

#### Example Scenario:
```
Customer: John Smith
Outstanding Invoices:
  - INV-001: $1,000 outstanding
  - INV-002: $500 outstanding
  - INV-003: $300 outstanding

John pays you: $1,200

You allocate this as:
  - $1,000 → INV-001 (fully paid)
  - $200 → INV-002 (partial payment, $300 still outstanding)
  - $0 → INV-003 (not paid yet)

Result:
  - INV-001: Status = "paid"
  - INV-002: Status = "partial", outstanding = $300
  - INV-003: Status = "unpaid", outstanding = $300
```

### Payment Data Structure (Firestore)

```javascript
// Collection: payments/{paymentId}
{
  id: "payment_xyz123",
  userId: "user_abc789",
  partyId: "party_def456",
  partyName: "John Smith", // Denormalized
  
  paymentType: "receipt", // or "payment"
  paymentDate: Timestamp,
  totalAmount: 1200.00, // Total money received/paid
  
  paymentMethod: "bank_transfer", // Options below
  referenceNumber: "TXN123456", // Optional
  notes: "Payment for invoices", // Optional
  
  createdAt: Timestamp,
  updatedAt: Timestamp
}

// Subcollection: payments/{paymentId}/allocations/{allocationId}
{
  id: "alloc_001",
  invoiceId: "invoice_abc123",
  invoiceNumber: "INV-001", // Denormalized for display
  allocatedAmount: 1000.00,
  createdAt: Timestamp
}

// Another allocation in same payment
{
  id: "alloc_002",
  invoiceId: "invoice_def456",
  invoiceNumber: "INV-002",
  allocatedAmount: 200.00,
  createdAt: Timestamp
}
```

### Payment Methods (Enum Values)

```dart
enum PaymentMethod {
  cash,           // Cash payment
  bank_transfer,  // Bank/Wire transfer
  cheque,         // Cheque
  upi,           // UPI (India specific)
  card,          // Credit/Debit card
  other          // Other methods
}
```

---

## Payment Recording Flow (Step-by-Step)

### Flow 1: Record Payment from Invoice Detail Screen

**User Journey:**
1. User views Invoice Detail Screen (e.g., INV-001, outstanding: $1,000)
2. User taps "Record Payment" button
3. Navigation: Goes to Payment Recording Screen
4. Screen pre-fills:
   - Party: Auto-selected (from invoice)
   - Invoice: INV-001 pre-selected with full outstanding amount
   - Total Amount: Suggested as $1,000 (can be edited)

**User Actions:**
- Can change total payment amount
- Can adjust allocated amount for pre-selected invoice
- Can add MORE invoices to allocate this payment
- Fills payment method, date, reference number
- Taps "Save"

### Flow 2: Record Payment from Party Detail Screen

**User Journey:**
1. User views Party Detail Screen (e.g., John Smith, Customer)
2. User sees list of unpaid/partial invoices
3. User taps "Record Payment" button
4. Navigation: Goes to Payment Recording Screen
5. Screen pre-fills:
   - Party: Auto-selected (John Smith)
   - Invoices: Shows ALL unpaid/partial invoices for this party
   - Total Amount: Empty (user must enter)

**User Actions:**
- Enters total payment amount
- Selects which invoices to pay
- Allocates amounts to each selected invoice
- Fills payment method, date, reference number
- Taps "Save"

### Flow 3: Record Payment from Payments Tab

**User Journey:**
1. User taps Payments tab in bottom navigation
2. User taps floating action button (+)
3. Navigation: Goes to Payment Recording Screen
4. Screen is empty (nothing pre-filled)

**User Actions:**
- Selects party (customer or supplier)
- App shows unpaid/partial invoices for that party
- Enters total payment amount
- Selects invoices and allocates amounts
- Fills payment method, date, reference number
- Taps "Save"

---

## Payment Recording Screen (Detailed Specification)

### Screen Structure

```
┌─────────────────────────────────────┐
│ [←] Record Receipt           [Save] │ ← App Bar
├─────────────────────────────────────┤
│                                     │
│ Party *                             │
│ ┌─────────────────────────────────┐ │
│ │ [👤] John Smith          [▼]   │ │ ← Dropdown/Search
│ └─────────────────────────────────┘ │
│                                     │
│ Payment Date *                      │
│ ┌─────────────────────────────────┐ │
│ │ [📅] Feb 27, 2026               │ │ ← Date Picker
│ └─────────────────────────────────┘ │
│                                     │
│ Payment Method *                    │
│ ┌─────────────────────────────────┐ │
│ │ [💳] Bank Transfer       [▼]   │ │ ← Dropdown
│ └─────────────────────────────────┘ │
│                                     │
│ Reference Number                    │
│ ┌─────────────────────────────────┐ │
│ │ TXN123456                       │ │ ← Text Input
│ └─────────────────────────────────┘ │
│                                     │
│ Total Payment Amount *              │
│ ┌─────────────────────────────────┐ │
│ │ $ 1,200.00                      │ │ ← Currency Input (Large)
│ └─────────────────────────────────┘ │
│                                     │
├─────────────────────────────────────┤
│ ALLOCATE TO INVOICES               │
├─────────────────────────────────────┤
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ INV-001                    [×]  │ │
│ │ Date: Jan 15, 2026             │ │
│ │ Total: $1,000 | Due: $1,000    │ │
│ │                                 │ │
│ │ Allocate: $ [____1000.00____]  │ │ ← Editable
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ INV-002                    [×]  │ │
│ │ Date: Jan 20, 2026             │ │
│ │ Total: $500 | Due: $500        │ │
│ │                                 │ │
│ │ Allocate: $ [_____200.00____]  │ │ ← Editable
│ └─────────────────────────────────┘ │
│                                     │
│ [+ Add Another Invoice]             │
│                                     │
├─────────────────────────────────────┤
│ Total Allocated: $1,200.00    ✓   │ ← Must equal total
│ Remaining: $0.00                   │
├─────────────────────────────────────┤
│                                     │
│ Notes                               │
│ ┌─────────────────────────────────┐ │
│ │                                 │ │
│ │                                 │ │
│ └─────────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

### Field Specifications

#### 1. Party Selection
- **Type**: Searchable dropdown
- **Required**: Yes
- **Options**: 
  - If coming from invoice/party screen: Pre-selected, non-editable
  - If coming from payments tab: All parties of correct type
- **Filtering**:
  - If recording receipt: Show only CUSTOMERS
  - If recording payment: Show only SUPPLIERS
- **Display**: Party name with contact info

#### 2. Payment Date
- **Type**: Date picker
- **Required**: Yes
- **Default**: Today's date
- **Validation**: Cannot be future date (optional rule)

#### 3. Payment Method
- **Type**: Dropdown
- **Required**: Yes
- **Options**: Cash, Bank Transfer, Cheque, UPI, Card, Other
- **Display**: Icon + Text

#### 4. Reference Number
- **Type**: Text input
- **Required**: No
- **Example**: Transaction ID, Cheque number, etc.
- **Max Length**: 50 characters

#### 5. Total Payment Amount
- **Type**: Currency input
- **Required**: Yes
- **Validation**: Must be > 0
- **Display**: Large, prominent font
- **Auto-calculation**: Sum of all allocations must equal this

#### 6. Invoice Selection & Allocation
- **Display**: List of invoice cards
- **Source**: All unpaid/partial invoices for selected party
- **Actions**:
  - Add invoice: Opens modal/bottom sheet to select from available invoices
  - Remove invoice: Removes from allocation list
- **Per Invoice Fields**:
  - Invoice number (read-only)
  - Invoice date (read-only)
  - Total amount (read-only)
  - Outstanding amount (read-only)
  - **Allocated amount** (editable)

#### 7. Allocation Summary
- **Total Allocated**: Auto-sum of all allocated amounts
- **Remaining**: Total Payment - Total Allocated
- **Validation Indicator**:
  - ✓ Green checkmark if Total Allocated = Total Payment
  - ⚠️ Warning if not equal

#### 8. Notes
- **Type**: Multi-line text input
- **Required**: No
- **Max Length**: 500 characters

---

## Validation Rules (Critical)

### Rule 1: Total Allocation Must Equal Total Payment
```dart
double totalAllocated = allocations.fold(0.0, (sum, a) => sum + a.allocatedAmount);
bool isValid = totalAllocated == totalPaymentAmount;

if (!isValid) {
  throw ValidationException('Total allocated must equal total payment amount');
}
```

### Rule 2: Allocated Amount Cannot Exceed Invoice Outstanding
```dart
for (var allocation in allocations) {
  if (allocation.allocatedAmount > allocation.invoice.outstandingAmount) {
    throw ValidationException(
      'Allocated amount for ${allocation.invoice.invoiceNumber} '
      'exceeds outstanding amount'
    );
  }
}
```

### Rule 3: At Least One Invoice Must Be Selected
```dart
if (allocations.isEmpty) {
  throw ValidationException('Please select at least one invoice');
}
```

### Rule 4: All Allocated Amounts Must Be Positive
```dart
for (var allocation in allocations) {
  if (allocation.allocatedAmount <= 0) {
    throw ValidationException('All allocated amounts must be greater than 0');
  }
}
```

### Rule 5: Party Type Must Match Invoice Type
```dart
// If party is customer (receives sales invoices):
//   - Can only allocate to sales invoices
//   - Payment type must be "receipt"

// If party is supplier (receives purchase invoices):
//   - Can only allocate to purchase invoices
//   - Payment type must be "payment"

if (party.partyType == 'customer') {
  paymentType = 'receipt';
  // Filter invoices: only show sales invoices
} else {
  paymentType = 'payment';
  // Filter invoices: only show purchase invoices
}
```

---

## Backend Logic (Firestore + Cloud Functions)

### Step 1: Create Payment Document

```dart
Future<String> recordPayment({
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
  final db = FirebaseFirestore.instance;
  
  // Validate before saving
  validatePayment(totalAmount, allocations);
  
  // Create payment document
  final paymentRef = await db.collection('payments').add({
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
  
  // Create allocation documents in subcollection
  final batch = db.batch();
  for (var allocation in allocations) {
    final allocRef = paymentRef.collection('allocations').doc();
    batch.set(allocRef, {
      'invoiceId': allocation.invoiceId,
      'invoiceNumber': allocation.invoiceNumber,
      'allocatedAmount': allocation.allocatedAmount,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
  
  return paymentRef.id;
}
```

### Step 2: Cloud Function - Update Invoice Status (CRITICAL)

This runs automatically when allocations are created/deleted.

```javascript
// functions/index.js

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

// Trigger on allocation created
exports.updateInvoiceOnAllocationCreate = functions.firestore
  .document('payments/{paymentId}/allocations/{allocationId}')
  .onCreate(async (snap, context) => {
    const allocation = snap.data();
    return updateInvoicePaymentStatus(allocation.invoiceId);
  });

// Trigger on allocation deleted
exports.updateInvoiceOnAllocationDelete = functions.firestore
  .document('payments/{paymentId}/allocations/{allocationId}')
  .onDelete(async (snap, context) => {
    const allocation = snap.data();
    return updateInvoicePaymentStatus(allocation.invoiceId);
  });

// Helper function to recalculate invoice payment status
async function updateInvoicePaymentStatus(invoiceId) {
  const invoiceRef = db.collection('invoices').doc(invoiceId);
  const invoice = await invoiceRef.get();
  
  if (!invoice.exists) {
    console.error('Invoice not found:', invoiceId);
    return;
  }
  
  const invoiceData = invoice.data();
  const totalAmount = invoiceData.totalAmount;
  
  // Query ALL allocations for this invoice across ALL payments
  const allocationsSnapshot = await db.collectionGroup('allocations')
    .where('invoiceId', '==', invoiceId)
    .get();
  
  // Calculate total paid from all allocations
  let paidAmount = 0;
  allocationsSnapshot.forEach(doc => {
    paidAmount += doc.data().allocatedAmount;
  });
  
  // Calculate outstanding
  const outstandingAmount = totalAmount - paidAmount;
  
  // Determine payment status
  let paymentStatus = 'unpaid';
  if (outstandingAmount <= 0.01) { // Use small epsilon for floating point
    paymentStatus = 'paid';
    outstandingAmount = 0; // Ensure it's exactly 0
  } else if (paidAmount > 0) {
    paymentStatus = 'partial';
  }
  
  // Update invoice
  return invoiceRef.update({
    paidAmount: paidAmount,
    outstandingAmount: Math.max(0, outstandingAmount),
    paymentStatus: paymentStatus,
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });
}
```

---

## UI Examples & User Scenarios

### Scenario 1: Full Payment for Single Invoice

**Initial State:**
- Invoice INV-001: Total = $1,000, Outstanding = $1,000, Status = Unpaid

**User Action:**
1. Opens INV-001 detail screen
2. Taps "Record Payment"
3. Payment screen shows:
   - Party: John Smith (locked)
   - Total Amount: $1,000 (suggested)
   - INV-001 pre-selected with allocation: $1,000
4. User confirms and saves

**Result:**
- New payment created: $1,000 receipt
- Allocation: $1,000 → INV-001
- Cloud Function updates INV-001:
  - paidAmount: $1,000
  - outstandingAmount: $0
  - paymentStatus: "paid"

### Scenario 2: Partial Payment for Single Invoice

**Initial State:**
- Invoice INV-001: Total = $1,000, Outstanding = $1,000, Status = Unpaid

**User Action:**
1. Opens INV-001 detail screen
2. Taps "Record Payment"
3. Changes total amount to $400
4. Changes allocation for INV-001 to $400
5. Saves

**Result:**
- New payment created: $400 receipt
- Allocation: $400 → INV-001
- Cloud Function updates INV-001:
  - paidAmount: $400
  - outstandingAmount: $600
  - paymentStatus: "partial"

### Scenario 3: Payment Split Across Multiple Invoices

**Initial State:**
- INV-001: Total = $1,000, Outstanding = $1,000
- INV-002: Total = $800, Outstanding = $800
- INV-003: Total = $500, Outstanding = $500

**User Action:**
1. Opens Party detail screen (John Smith)
2. Taps "Record Payment"
3. Enters total amount: $2,000
4. INV-001 allocation: $1,000 (full)
5. Taps "+ Add Another Invoice", selects INV-002
6. INV-002 allocation: $800 (full)
7. Taps "+ Add Another Invoice", selects INV-003
8. INV-003 allocation: $200 (partial)
9. Total allocated = $2,000 ✓
10. Saves

**Result:**
- New payment created: $2,000 receipt with 3 allocations
- Cloud Function updates:
  - INV-001: paidAmount = $1,000, outstanding = $0, status = "paid"
  - INV-002: paidAmount = $800, outstanding = $0, status = "paid"
  - INV-003: paidAmount = $200, outstanding = $300, status = "partial"

### Scenario 4: Multiple Partial Payments (Sequential)

**Initial State:**
- INV-001: Total = $1,000, Outstanding = $1,000, Status = Unpaid

**Payment 1:**
- User records $300 payment → allocated to INV-001
- Result: INV-001 status = "partial", outstanding = $700

**Payment 2 (later):**
- User records $400 payment → allocated to INV-001
- Result: INV-001 status = "partial", outstanding = $300
- (Cloud Function adds $400 to existing $300 = $700 paid total)

**Payment 3 (later):**
- User records $300 payment → allocated to INV-001
- Result: INV-001 status = "paid", outstanding = $0
- (Cloud Function adds $300 to existing $700 = $1,000 paid total)

---

## Payment History & Display

### View Payment Details

When user views a payment from Payment History screen:

```
┌─────────────────────────────────────┐
│ [←] Receipt #PAY-001                │
├─────────────────────────────────────┤
│                                     │
│ [Status Badge: Completed]           │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Payment Information             │ │
│ │                                 │ │
│ │ Party: John Smith               │ │
│ │ Type: Receipt (Income)          │ │
│ │ Date: Feb 27, 2026              │ │
│ │ Method: Bank Transfer           │ │
│ │ Reference: TXN123456            │ │
│ │                                 │ │
│ │ Total Amount: $2,000.00         │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Allocation Details              │ │
│ │                                 │ │
│ │ INV-001          $1,000.00  →  │ │
│ │ INV-002            $800.00  →  │ │
│ │ INV-003            $200.00  →  │ │
│ │                  ──────────     │ │
│ │ Total:          $2,000.00       │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Notes:                              │
│ Payment for January invoices        │
│                                     │
└─────────────────────────────────────┘
```

### Invoice Detail Screen - Payment History Section

Shows all payments allocated to this specific invoice:

```
Payment History:
┌─────────────────────────────────────┐
│ Feb 27, 2026                        │
│ Receipt • Bank Transfer             │
│ Reference: TXN123456                │
│ Amount: $400.00                     │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ Feb 15, 2026                        │
│ Receipt • Cash                      │
│ Amount: $300.00                     │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ Feb 10, 2026                        │
│ Receipt • UPI                       │
│ Reference: UPI/123                  │
│ Amount: $300.00                     │
└─────────────────────────────────────┘

Total Paid: $1,000.00
```

---

## Query Examples (Firestore)

### Get All Payments for a Party

```dart
Stream<List<Payment>> getPartyPayments(String partyId) {
  return FirebaseFirestore.instance
    .collection('payments')
    .where('partyId', isEqualTo: partyId)
    .orderBy('paymentDate', descending: true)
    .snapshots()
    .map((snapshot) => 
      snapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList()
    );
}
```

### Get Payment with Allocations

```dart
Future<PaymentWithAllocations> getPaymentDetails(String paymentId) async {
  // Get payment
  final paymentDoc = await FirebaseFirestore.instance
    .collection('payments')
    .doc(paymentId)
    .get();
  
  final payment = Payment.fromFirestore(paymentDoc);
  
  // Get allocations
  final allocationsSnapshot = await paymentDoc.reference
    .collection('allocations')
    .get();
  
  final allocations = allocationsSnapshot.docs
    .map((doc) => PaymentAllocation.fromFirestore(doc))
    .toList();
  
  return PaymentWithAllocations(
    payment: payment,
    allocations: allocations,
  );
}
```

### Get All Payments Allocated to an Invoice

```dart
Future<List<PaymentAllocationWithPayment>> getInvoicePayments(
  String invoiceId
) async {
  // Use collectionGroup to query across all payments
  final allocationsSnapshot = await FirebaseFirestore.instance
    .collectionGroup('allocations')
    .where('invoiceId', isEqualTo: invoiceId)
    .get();
  
  List<PaymentAllocationWithPayment> result = [];
  
  for (var allocDoc in allocationsSnapshot.docs) {
    final allocation = PaymentAllocation.fromFirestore(allocDoc);
    
    // Get parent payment document
    final paymentDoc = await allocDoc.reference.parent.parent!.get();
    final payment = Payment.fromFirestore(paymentDoc);
    
    result.add(PaymentAllocationWithPayment(
      allocation: allocation,
      payment: payment,
    ));
  }
  
  return result;
}
```

### Get Unpaid/Partial Invoices for Party

```dart
Stream<List<Invoice>> getUnpaidInvoices({
  required String userId,
  required String partyId,
  required String invoiceType,
}) {
  return FirebaseFirestore.instance
    .collection('invoices')
    .where('userId', isEqualTo: userId)
    .where('partyId', isEqualTo: partyId)
    .where('invoiceType', isEqualTo: invoiceType)
    .where('paymentStatus', whereIn: ['unpaid', 'partial'])
    .orderBy('invoiceDate', descending: false)
    .snapshots()
    .map((snapshot) => 
      snapshot.docs.map((doc) => Invoice.fromFirestore(doc)).toList()
    );
}
```

---

## Edit and Delete Payment

### Edit Payment

**Important**: Editing a payment is complex because it affects multiple invoices.

**Approach 1 - Simple (Recommended for MVP):**
- Do NOT allow editing payments
- Only allow deletion and re-creation

**Approach 2 - Advanced:**
If you must allow editing:
1. Delete all old allocations (triggers Cloud Function to update invoices)
2. Create new payment record with new allocations
3. Mark old payment as "cancelled" or delete it
4. Cloud Functions will recalculate all affected invoices

### Delete Payment

```dart
Future<void> deletePayment(String paymentId) async {
  final db = FirebaseFirestore.instance;
  
  // 1. Get all allocations for this payment
  final allocationsSnapshot = await db
    .collection('payments')
    .doc(paymentId)
    .collection('allocations')
    .get();
  
  // 2. Delete all allocations in a batch
  final batch = db.batch();
  for (var doc in allocationsSnapshot.docs) {
    batch.delete(doc.reference);
  }
  await batch.commit();
  
  // Cloud Function will automatically update affected invoices
  
  // 3. Delete the payment document
  await db.collection('payments').doc(paymentId).delete();
}
```

**What Happens:**
1. Allocations are deleted
2. Cloud Function triggers for each deletion
3. Each affected invoice gets recalculated
4. Invoice payment statuses update automatically
5. Payment document is deleted

---

## Common Mistakes to Avoid

### ❌ Mistake 1: Updating Invoice Directly When Recording Payment
```dart
// WRONG - Don't do this
await FirebaseFirestore.instance
  .collection('invoices')
  .doc(invoiceId)
  .update({
    'paidAmount': newPaidAmount,
    'outstandingAmount': newOutstanding,
  });
```

**Why Wrong:** Invoice might have multiple payments. You need to calculate total from ALL allocations.

**✅ Correct:** Let Cloud Function handle it by querying all allocations.

### ❌ Mistake 2: Allowing Total Allocated ≠ Total Payment
```dart
// WRONG - No validation
if (totalAllocated != totalPayment) {
  // Just save anyway
}
```

**Why Wrong:** Creates data inconsistency. Where did extra money go?

**✅ Correct:** Strict validation before saving.

### ❌ Mistake 3: Not Using Transactions for Batch Operations
```dart
// WRONG - Individual writes without transaction
for (var allocation in allocations) {
  await db.collection('payments/$paymentId/allocations').add(allocation);
}
```

**Why Wrong:** If one fails, you get partial data.

**✅ Correct:** Use batch writes or transactions.

### ❌ Mistake 4: Mixing Payment Types
```dart
// WRONG - Recording receipt for supplier
if (party.partyType == 'supplier') {
  paymentType = 'receipt'; // WRONG!
}
```

**Why Wrong:** Suppliers receive payments, not receipts.

**✅ Correct:** 
- Customer → Receipt (you receive money)
- Supplier → Payment (you pay money)

---

## Testing Checklist

### Test Case 1: Full Payment Single Invoice
- [ ] Record full payment for unpaid invoice
- [ ] Verify invoice status changes to "paid"
- [ ] Verify outstanding becomes 0

### Test Case 2: Partial Payment Single Invoice
- [ ] Record partial payment (e.g., 40% of total)
- [ ] Verify invoice status changes to "partial"
- [ ] Verify outstanding is correct
- [ ] Record another partial payment
- [ ] Verify amounts accumulate correctly

### Test Case 3: Multi-Invoice Allocation
- [ ] Record payment with 3 invoice allocations
- [ ] Verify all 3 invoices update correctly
- [ ] Verify allocation details are saved

### Test Case 4: Validation Errors
- [ ] Try to save with total allocated > total payment (should fail)
- [ ] Try to save with total allocated < total payment (should fail)
- [ ] Try to allocate more than invoice outstanding (should fail)
- [ ] Try to save without selecting any invoice (should fail)

### Test Case 5: Delete Payment
- [ ] Delete a payment
- [ ] Verify allocations are deleted
- [ ] Verify affected invoices revert to previous status

### Test Case 6: Payment History
- [ ] View payment history for a party
- [ ] Verify all payments are listed
- [ ] View payment detail with allocations
- [ ] From invoice detail, view payment history for that invoice

### Test Case 7: Edge Cases
- [ ] Pay invoice with $0.01 (should work)
- [ ] Pay $10,000 invoice with multiple small payments
- [ ] Delete one payment from chain of multiple payments
- [ ] Verify calculations with floating point precision

---

## Data Model Classes (Dart)

```dart
// Payment model
class Payment {
  final String id;
  final String userId;
  final String partyId;
  final String partyName;
  final String paymentType; // 'receipt' or 'payment'
  final DateTime paymentDate;
  final double totalAmount;
  final String paymentMethod;
  final String? referenceNumber;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  Payment({
    required this.id,
    required this.userId,
    required this.partyId,
    required this.partyName,
    required this.paymentType,
    required this.paymentDate,
    required this.totalAmount,
    required this.paymentMethod,
    this.referenceNumber,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory Payment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Payment(
      id: doc.id,
      userId: data['userId'] ?? '',
      partyId: data['partyId'] ?? '',
      partyName: data['partyName'] ?? '',
      paymentType: data['paymentType'] ?? '',
      paymentDate: (data['paymentDate'] as Timestamp).toDate(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? '',
      referenceNumber: data['referenceNumber'],
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'partyId': partyId,
      'partyName': partyName,
      'paymentType': paymentType,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'referenceNumber': referenceNumber,
      'notes': notes,
    };
  }
}

// Payment allocation model
class PaymentAllocation {
  final String id;
  final String invoiceId;
  final String invoiceNumber;
  final double allocatedAmount;
  final DateTime createdAt;
  
  PaymentAllocation({
    required this.id,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.allocatedAmount,
    required this.createdAt,
  });
  
  factory PaymentAllocation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentAllocation(
      id: doc.id,
      invoiceId: data['invoiceId'] ?? '',
      invoiceNumber: data['invoiceNumber'] ?? '',
      allocatedAmount: (data['allocatedAmount'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'invoiceId': invoiceId,
      'invoiceNumber': invoiceNumber,
      'allocatedAmount': allocatedAmount,
    };
  }
}

// Combined model for display
class PaymentWithAllocations {
  final Payment payment;
  final List<PaymentAllocation> allocations;
  
  PaymentWithAllocations({
    required this.payment,
    required this.allocations,
  });
  
  double get totalAllocated => 
    allocations.fold(0.0, (sum, a) => sum + a.allocatedAmount);
}
```

---

## Implementation Summary

When implementing the payment system:

1. **Payments are separate from invoices** - They link via allocations
2. **One payment can pay multiple invoices** - Use subcollection for allocations
3. **Multiple payments can pay one invoice** - Cloud Function sums all allocations
4. **Never manually update invoice paid amounts** - Let Cloud Function handle it
5. **Always validate total allocated = total payment** - Before saving
6. **Use correct payment type** - Receipt for customers, Payment for suppliers
7. **Pre-fill intelligently** - Based on navigation source (invoice/party/new)
8. **Show unpaid/partial invoices only** - When selecting invoices to pay
9. **Denormalize party names** - For faster display without joins
10. **Use Cloud Functions for invoice updates** - Triggered by allocation changes

---

**END OF PAYMENT SYSTEM SPECIFICATION**

This document should be used as THE definitive reference for implementing payments. If anything is unclear, refer back to the examples and scenarios provided.
