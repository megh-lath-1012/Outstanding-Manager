# Outstanding Manager - Architecture & Flow Diagrams

## 🏗️ System Architecture

### Web Application Architecture
```
┌─────────────────────────────────────────────────────────┐
│                      Browser                             │
│  ┌───────────────────────────────────────────────────┐  │
│  │              React Application                     │  │
│  │                                                    │  │
│  │  ┌──────────────┐      ┌──────────────┐          │  │
│  │  │   Router     │──────│   App.tsx    │          │  │
│  │  │  (routes.ts) │      │              │          │  │
│  │  └──────────────┘      └──────────────┘          │  │
│  │         │                                         │  │
│  │         ├──Dashboard────────────┐                 │  │
│  │         ├──AddCompany──────────┐│                 │  │
│  │         ├──CompanyDetails─────┐││                 │  │
│  │         ├──AddTransaction────┐│││                 │  │
│  │         └──MakePayment ⭐───┐││││                 │  │
│  │                             ││││                  │  │
│  │                             ││││                  │  │
│  │  ┌──────────────────────────┘│││                  │  │
│  │  │        Components          │││                 │  │
│  │  │  (UI + Business Logic)     │││                 │  │
│  │  └────────────┬───────────────┘││                 │  │
│  │               │                 ││                 │  │
│  │               ▼                 ││                 │  │
│  │  ┌──────────────────────────────┘│                 │  │
│  │  │    Storage Layer (utils)      │                 │  │
│  │  │  ┌────────────────────────┐   │                 │  │
│  │  │  │ getCompanies()         │   │                 │  │
│  │  │  │ saveCompany()          │   │                 │  │
│  │  │  │ getTransactions()      │   │                 │  │
│  │  │  │ saveTransaction()      │   │                 │  │
│  │  │  │ getPayments()          │   │                 │  │
│  │  │  │ savePayment() ⭐       │   │                 │  │
│  │  │  │ calculateOutstanding() │   │                 │  │
│  │  │  └────────────────────────┘   │                 │  │
│  │  └────────────┬──────────────────┘                 │  │
│  │               │                                    │  │
│  │               ▼                                    │  │
│  │  ┌──────────────────────────────┐                 │  │
│  │  │      localStorage API         │                 │  │
│  │  │  {                            │                 │  │
│  │  │    companies: [...],          │                 │  │
│  │  │    transactions: [...],       │                 │  │
│  │  │    payments: [...]            │                 │  │
│  │  │  }                            │                 │  │
│  │  └──────────────────────────────┘                 │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Android Application Architecture
```
┌─────────────────────────────────────────────────────────┐
│                  Android Device                          │
│  ┌───────────────────────────────────────────────────┐  │
│  │           Jetpack Compose UI Layer                 │  │
│  │                                                    │  │
│  │  ┌──────────────┐      ┌──────────────┐          │  │
│  │  │ MainActivity │──────│   NavHost    │          │  │
│  │  │              │      │ (Navigation) │          │  │
│  │  └──────────────┘      └──────────────┘          │  │
│  │                               │                   │  │
│  │         ┌─────────────────────┼─────────────┐     │  │
│  │         │                     │             │     │  │
│  │         ▼                     ▼             ▼     │  │
│  │  DashboardScreen    CompanyDetailsScreen   ...    │  │
│  │  AddCompanyScreen   AddTransactionScreen          │  │
│  │  MakePaymentScreen ⭐                             │  │
│  │         │                     │             │     │  │
│  │         └─────────────────────┼─────────────┘     │  │
│  │                               │                   │  │
│  └───────────────────────────────┼───────────────────┘  │
│                                  │                      │
│  ┌───────────────────────────────▼───────────────────┐  │
│  │              ViewModel Layer                       │  │
│  │  ┌─────────────────────────────────────────────┐  │  │
│  │  │       OutstandingViewModel                   │  │  │
│  │  │  ┌───────────────────────────────────────┐  │  │  │
│  │  │  │ - StateFlow<Companies>                │  │  │  │
│  │  │  │ - StateFlow<Transactions>             │  │  │  │
│  │  │  │ - StateFlow<Payments>                 │  │  │  │
│  │  │  │ - StateFlow<OutstandingSummary>       │  │  │  │
│  │  │  │                                       │  │  │  │
│  │  │  │ + addCompany()                        │  │  │  │
│  │  │  │ + addTransaction()                    │  │  │  │
│  │  │  │ + addPayment() ⭐                     │  │  │  │
│  │  │  │ + calculateOutstanding()              │  │  │  │
│  │  │  └───────────────────────────────────────┘  │  │  │
│  │  └─────────────────────────────────────────────┘  │  │
│  └───────────────────────────────┬───────────────────┘  │
│                                  │                      │
│  ┌───────────────────────────────▼───────────────────┐  │
│  │             Repository Layer                       │  │
│  │  ┌─────────────────────────────────────────────┐  │  │
│  │  │      OutstandingRepository                   │  │  │
│  │  │  ┌───────────────────────────────────────┐  │  │  │
│  │  │  │ - SharedPreferences                   │  │  │  │
│  │  │  │ - Kotlin Serialization                │  │  │  │
│  │  │  │                                       │  │  │  │
│  │  │  │ + loadCompanies()                     │  │  │  │
│  │  │  │ + saveCompany()                       │  │  │  │
│  │  │  │ + loadTransactions()                  │  │  │  │
│  │  │  │ + saveTransaction()                   │  │  │  │
│  │  │  │ + loadPayments()                      │  │  │  │
│  │  │  │ + savePayment() ⭐                    │  │  │  │
│  │  │  │ + calculateOutstanding()              │  │  │  │
│  │  │  └───────────────────────────────────────┘  │  │  │
│  │  └─────────────────────────────────────────────┘  │  │
│  └───────────────────────────────┬───────────────────┘  │
│                                  │                      │
│  ┌───────────────────────────────▼───────────────────┐  │
│  │           Data Storage Layer                       │  │
│  │  ┌─────────────────────────────────────────────┐  │  │
│  │  │        SharedPreferences                     │  │  │
│  │  │  {                                           │  │  │
│  │  │    "companies": "[{...}, {...}]",           │  │  │
│  │  │    "transactions": "[{...}, {...}]",        │  │  │
│  │  │    "payments": "[{...}, {...}]"             │  │  │
│  │  │  }                                           │  │  │
│  │  └─────────────────────────────────────────────┘  │  │
│  └─────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## 🔄 Payment Flow Diagram

### Full Payment Flow
```
┌────────────────────────────────────────────────────────┐
│                  USER INITIATES PAYMENT                 │
└────────────────────┬───────────────────────────────────┘
                     │
                     ▼
         ┌───────────────────────┐
         │  Select Company       │
         │  (e.g., ABC Corp)     │
         └───────────┬───────────┘
                     │
                     ▼
         ┌───────────────────────┐
         │  Navigate to          │
         │  "Make Payment"       │
         └───────────┬───────────┘
                     │
                     ▼
         ┌───────────────────────────────────┐
         │  Select Payment Type              │
         │  ○ Sales Outstanding (They pay)   │
         │  ○ Purchase Outstanding (You pay) │
         └───────────┬───────────────────────┘
                     │
                     ▼
         ┌───────────────────────────────────┐
         │  System Shows Current Outstanding │
         │  "Sales Outstanding: ₹50,000"     │
         └───────────┬───────────────────────┘
                     │
                     ▼
         ┌───────────────────────────────────┐
         │  USER CLICKS "FULL PAYMENT" ⭐    │
         └───────────┬───────────────────────┘
                     │
                     ▼
         ┌───────────────────────────────────┐
         │  Amount Auto-fills: ₹50,000       │
         │  Remaining: ₹0                     │
         └───────────┬───────────────────────┘
                     │
                     ▼
         ┌───────────────────────────────────┐
         │  User Confirms Payment             │
         │  [Record Payment] Button           │
         └───────────┬───────────────────────┘
                     │
                     ▼
         ┌───────────────────────────────────┐
         │  VALIDATION                        │
         │  ✓ Amount > 0                      │
         │  ✓ Amount ≤ Outstanding            │
         │  ✓ Outstanding exists              │
         └───────────┬───────────────────────┘
                     │
                     ▼
         ┌───────────────────────────────────┐
         │  CREATE PAYMENT OBJECT             │
         │  {                                 │
         │    id: "123456",                   │
         │    companyId: "ABC",               │
         │    amount: 50000,                  │
         │    type: "sale",                   │
         │    date: timestamp                 │
         │  }                                 │
         └───────────┬───────────────────────┘
                     │
                     ▼
         ┌───────────────────────────────────┐
         │  SAVE TO STORAGE                   │
         │  Web: localStorage                 │
         │  Android: SharedPreferences        │
         └───────────┬───────────────────────┘
                     │
                     ▼
         ┌───────────────────────────────────┐
         │  RECALCULATE OUTSTANDING           │
         │  New Outstanding = ₹50,000 - ₹50,000│
         │  = ₹0 ✓                            │
         └───────────┬───────────────────────┘
                     │
                     ▼
         ┌───────────────────────────────────┐
         │  UPDATE UI                         │
         │  Sales Outstanding: ₹0             │
         │  Show Success Notification         │
         └───────────┬───────────────────────┘
                     │
                     ▼
         ┌───────────────────────────────────┐
         │  NAVIGATE BACK                     │
         │  to Company Details                │
         └───────────────────────────────────┘
```

### Part Payment Flow
```
┌────────────────────────────────────────────────────────┐
│                  USER INITIATES PAYMENT                 │
└────────────────────┬───────────────────────────────────┘
                     │
                     ▼
         ┌───────────────────────┐
         │  Select Company       │
         │  (e.g., XYZ Ltd)      │
         └───────────┬───────────┘
                     │
                     ▼
         ┌───────────────────────┐
         │  Navigate to          │
         │  "Make Payment"       │
         └───────────┬───────────┘
                     │
                     ▼
         ┌───────────────────────────────────┐
         │  Select Payment Type              │
         │  ● Sales Outstanding (They pay)   │
         │  ○ Purchase Outstanding (You pay) │
         └───────────┬───────────────────────┘
                     │
                     ▼
         ┌───────────────────────────────────┐
         │  System Shows Current Outstanding │
         │  "Sales Outstanding: ₹100,000"    │
         └───────────┬───────────────────────┘
                     │
                     ▼
         ┌───────────────────────────────────┐
         │  USER ENTERS CUSTOM AMOUNT ⭐     │
         │  Input: ₹35,000                   │
         └───────────┬───────────────────────┘
                     │
                     ▼
         ┌───────────────────────────────────┐
         │  REAL-TIME VALIDATION & FEEDBACK  │
         │  ✓ Amount: ₹35,000                │
         │  ✓ Remaining: ₹65,000             │
         │  ℹ "Part payment: ₹65,000 will    │
         │     remain outstanding"           │
         └───────────┬───────────────────────┘
                     │
                     ▼
         ┌───────────────────────────────────┐
         │  User Confirms Payment             │
         │  [Record Payment] Button           │
         └───────────┬───────────────────────┘
                     │
                     ▼
         ┌───────────────────────────────────┐
         │  VALIDATION                        │
         │  ✓ Amount: 35000 > 0               │
         │  ✓ Amount: 35000 ≤ 100000          │
         │  ✓ Outstanding: 100000 exists      │
         └───────────┬───────────────────────┘
                     │
                     ▼
         ┌───────────────────────────────────┐
         │  CREATE PAYMENT OBJECT             │
         │  {                                 │
         │    id: "789012",                   │
         │    companyId: "XYZ",               │
         │    amount: 35000,                  │
         │    type: "sale",                   │
         │    date: timestamp                 │
         │  }                                 │
         └───────────┬───────────────────────┘
                     │
                     ▼
         ┌───────────────────────────────────┐
         │  SAVE TO STORAGE                   │
         │  Append to payments array          │
         └───────────┬───────────────────────┘
                     │
                     ▼
         ┌───────────────────────────────────┐
         │  RECALCULATE OUTSTANDING           │
         │  New = ₹100,000 - ₹35,000          │
         │  = ₹65,000 ✓                       │
         └───────────┬───────────────────────┘
                     │
                     ▼
         ┌───────────────────────────────────┐
         │  UPDATE UI                         │
         │  Sales Outstanding: ₹65,000        │
         │  Show Success Notification         │
         │  "Part payment of ₹35,000 recorded"│
         └───────────┬───────────────────────┘
                     │
                     ▼
         ┌───────────────────────────────────┐
         │  NAVIGATE BACK                     │
         │  User can make another payment     │
         └───────────────────────────────────┘
```

---

## 💾 Data Flow Diagram

### Creating a Transaction
```
┌──────────┐       ┌──────────┐       ┌──────────┐       ┌──────────┐
│   UI     │──────▶│ViewModel │──────▶│Repository│──────▶│ Storage  │
│  Screen  │       │          │       │          │       │          │
└──────────┘       └──────────┘       └──────────┘       └──────────┘
     │                   │                   │                  │
     │ User enters       │                   │                  │
     │ transaction       │                   │                  │
     │ data              │                   │                  │
     │                   │                   │                  │
     │ addTransaction()  │                   │                  │
     ├──────────────────▶│                   │                  │
     │                   │                   │                  │
     │                   │ saveTransaction() │                  │
     │                   ├──────────────────▶│                  │
     │                   │                   │                  │
     │                   │                   │ JSON.stringify() │
     │                   │                   ├─────────────────▶│
     │                   │                   │                  │
     │                   │                   │ localStorage.set()│
     │                   │                   │◀─────────────────│
     │                   │                   │                  │
     │                   │ Update StateFlow  │                  │
     │                   │◀──────────────────│                  │
     │                   │                   │                  │
     │ UI re-renders     │                   │                  │
     │◀──────────────────│                   │                  │
     │                   │                   │                  │
     │ Show success      │                   │                  │
     │ notification      │                   │                  │
     └───────────────────┴───────────────────┴──────────────────┘
```

### Making a Payment
```
┌──────────┐       ┌──────────┐       ┌──────────┐       ┌──────────┐
│   UI     │──────▶│ViewModel │──────▶│Repository│──────▶│ Storage  │
│  Screen  │       │          │       │          │       │          │
└──────────┘       └──────────┘       └──────────┘       └──────────┘
     │                   │                   │                  │
     │ 1. User clicks    │                   │                  │
     │    "Full Payment" │                   │                  │
     ├──────────────────▶│                   │                  │
     │                   │                   │                  │
     │ 2. Get current    │                   │                  │
     │    outstanding    │                   │                  │
     │◀──────────────────│                   │                  │
     │                   │                   │                  │
     │ 3. Auto-fill      │                   │                  │
     │    amount field   │                   │                  │
     │                   │                   │                  │
     │ 4. User confirms  │                   │                  │
     │    payment        │                   │                  │
     ├──────────────────▶│                   │                  │
     │                   │                   │                  │
     │                   │ 5. addPayment()   │                  │
     │                   ├──────────────────▶│                  │
     │                   │                   │                  │
     │                   │                   │ 6. Save payment  │
     │                   │                   ├─────────────────▶│
     │                   │                   │                  │
     │                   │                   │ 7. Recalculate   │
     │                   │                   │    outstanding   │
     │                   │                   │                  │
     │                   │ 8. Update State   │                  │
     │                   │◀──────────────────│                  │
     │                   │                   │                  │
     │ 9. UI updates     │                   │                  │
     │    Outstanding:₹0 │                   │                  │
     │◀──────────────────│                   │                  │
     │                   │                   │                  │
     │ 10. Success msg   │                   │                  │
     │     displayed     │                   │                  │
     └───────────────────┴───────────────────┴──────────────────┘
```

---

## 📊 State Management

### Web (React Hooks)
```
Component State (useState)
         │
         ├── Local UI state (form inputs)
         │
         ▼
   useEffect Hook
         │
         ├── Load data from localStorage
         │
         ▼
   Storage Functions (utils/storage.ts)
         │
         ├── getCompanies()
         ├── getTransactions()
         ├── getPayments()
         ├── calculateOutstanding()
         │
         ▼
   localStorage API
         │
         └── Browser storage
```

### Android (StateFlow + ViewModel)
```
UI Screen (Composable)
         │
         ├── Observes StateFlow
         │
         ▼
   ViewModel
         │
         ├── Business Logic
         ├── StateFlow<Companies>
         ├── StateFlow<Transactions>
         ├── StateFlow<Payments>
         ├── StateFlow<Outstanding>
         │
         ▼
   Repository
         │
         ├── Data operations
         ├── Kotlin Serialization
         │
         ▼
   SharedPreferences
         │
         └── Android storage
```

---

## 🎯 Outstanding Calculation Algorithm

```
INPUT:
  - companyId: string

FETCH DATA:
  - transactions = getAllTransactions(companyId)
  - payments = getAllPayments(companyId)

INITIALIZE:
  - totalSales = 0
  - totalPurchases = 0
  - salesPaid = 0
  - purchasesPaid = 0

FOR EACH transaction IN transactions:
  IF transaction.type == "sale":
    totalSales += transaction.amount
  ELSE IF transaction.type == "purchase":
    totalPurchases += transaction.amount

FOR EACH payment IN payments:
  IF payment.type == "sale":
    salesPaid += payment.amount
  ELSE IF payment.type == "purchase":
    purchasesPaid += payment.amount

CALCULATE:
  salesOutstanding = MAX(0, totalSales - salesPaid)
  purchaseOutstanding = MAX(0, totalPurchases - purchasesPaid)

RETURN:
  {
    salesOutstanding,
    purchaseOutstanding
  }
```

---

## 🔐 Security Flow

```
┌─────────────────────────────────────────┐
│           User Data Input                │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│        Client-Side Validation            │
│  • Amount > 0                            │
│  • Amount ≤ Outstanding                  │
│  • Required fields present               │
└──────────────┬──────────────────────────┘
               │
               ├── INVALID ──▶ Show Error ──▶ Return
               │
               ▼ VALID
┌─────────────────────────────────────────┐
│         Business Logic Layer             │
│  • Create data object                    │
│  • Generate unique ID                    │
│  • Add timestamp                         │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│          Storage Layer                   │
│  Web: localStorage (browser sandbox)    │
│  Android: SharedPreferences (app-private)│
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│         Data Persisted                   │
│  • No network transmission               │
│  • No cloud storage                      │
│  • 100% local to device                  │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│           UI Update                      │
│  • Show success message                  │
│  • Update outstanding display            │
│  • Navigate to previous screen           │
└─────────────────────────────────────────┘
```

---

**All diagrams show the complete flow from user interaction to data persistence!** 📊
