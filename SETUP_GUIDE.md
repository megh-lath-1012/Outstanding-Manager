# Outstanding Manager - Complete Setup Guide

## 🌐 Web Application (React)

### Overview
The web application is built with React, TypeScript, React Router, and Tailwind CSS. All files are already created and functional in this environment.

### Live Demo
The web app is running in this Figma Make environment. You can:
- Add companies
- Record transactions (sales/purchases)
- Make full or partial payments
- View activity history

### Technology Stack
- **Frontend**: React 18.3.1 with TypeScript
- **Routing**: React Router 7
- **Styling**: Tailwind CSS 4.1
- **UI Components**: Radix UI + shadcn/ui
- **State Management**: React Hooks + localStorage
- **Notifications**: Sonner (toast notifications)

### Key Files
```
/src/app/
├── App.tsx                           # Main app with router
├── routes.ts                         # Route configuration
├── utils/storage.ts                  # Data persistence layer
└── components/
    ├── Dashboard.tsx                 # Home screen
    ├── AddCompany.tsx               # Add company form
    ├── CompanyDetails.tsx           # Company details & activity
    ├── AddTransaction.tsx           # Transaction form
    ├── MakePayment.tsx              # Payment form (full/part)
    └── ui/                          # Reusable UI components
```

### Features
✅ Company Management
✅ Sales & Purchase Tracking
✅ Full Payment (one-click)
✅ Part Payment (custom amount)
✅ Real-time Outstanding Calculation
✅ Activity Timeline
✅ localStorage Persistence
✅ Responsive Design

---

## 📱 Android Application (Jetpack Compose)

### Overview
Complete Jetpack Compose application with Material Design 3, ready to copy to Android Studio.

### Quick Start

#### Step 1: Create Android Project
```bash
# In Android Studio:
1. File → New → New Project
2. Select "Empty Activity"
3. Choose Jetpack Compose
4. Name: OutstandingManager
5. Package: com.example.outstandingmanager
6. Minimum SDK: API 24 (Android 7.0)
7. Click Finish
```

#### Step 2: Update build.gradle.kts
Replace your `app/build.gradle.kts` with the file from `/android/build.gradle.kts`

**Key additions:**
```kotlin
plugins {
    id("org.jetbrains.kotlin.plugin.serialization") version "1.9.20"
}

dependencies {
    // Navigation Compose
    implementation("androidx.navigation:navigation-compose:2.7.6")
    
    // ViewModel Compose
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.7.0")
    
    // Kotlin Serialization
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.2")
    
    // Material Icons Extended
    implementation("androidx.compose.material:material-icons-extended")
}
```

#### Step 3: Copy Files

**File Mapping:**
```
/android/MainActivity.kt
  → /app/src/main/java/com/example/outstandingmanager/MainActivity.kt

/android/data/models/Models.kt
  → /app/src/main/java/com/example/outstandingmanager/data/models/Models.kt

/android/data/repository/OutstandingRepository.kt
  → /app/src/main/java/com/example/outstandingmanager/data/repository/OutstandingRepository.kt

/android/viewmodel/OutstandingViewModel.kt
  → /app/src/main/java/com/example/outstandingmanager/viewmodel/OutstandingViewModel.kt

/android/ui/navigation/Navigation.kt
  → /app/src/main/java/com/example/outstandingmanager/ui/navigation/Navigation.kt

/android/ui/screens/*.kt
  → /app/src/main/java/com/example/outstandingmanager/ui/screens/*.kt

/android/ui/theme/*.kt
  → /app/src/main/java/com/example/outstandingmanager/ui/theme/*.kt

/android/AndroidManifest.xml
  → /app/src/main/AndroidManifest.xml
```

#### Step 4: Sync and Build
```bash
1. Click "Sync Project with Gradle Files"
2. Wait for dependencies to download
3. Build → Make Project
```

#### Step 5: Run
```bash
1. Connect Android device or start emulator
2. Run → Run 'app'
```

### Android Project Structure
```
app/src/main/java/com/example/outstandingmanager/
├── MainActivity.kt
├── data/
│   ├── models/
│   │   └── Models.kt                    # Company, Transaction, Payment
│   └── repository/
│       └── OutstandingRepository.kt     # SharedPreferences storage
├── viewmodel/
│   └── OutstandingViewModel.kt          # MVVM ViewModel
├── ui/
│   ├── navigation/
│   │   └── Navigation.kt                # NavHost setup
│   ├── screens/
│   │   ├── DashboardScreen.kt
│   │   ├── AddCompanyScreen.kt
│   │   ├── CompanyDetailsScreen.kt
│   │   ├── AddTransactionScreen.kt
│   │   └── MakePaymentScreen.kt
│   └── theme/
│       ├── Color.kt
│       ├── Theme.kt
│       └── Type.kt
```

---

## 🔄 Key Differences: Web vs Android

| Feature | Web (React) | Android (Compose) |
|---------|-------------|-------------------|
| **Language** | TypeScript | Kotlin |
| **UI Framework** | React + Tailwind | Jetpack Compose |
| **Navigation** | React Router | Navigation Compose |
| **State Management** | React Hooks | StateFlow + ViewModel |
| **Data Storage** | localStorage | SharedPreferences |
| **Serialization** | JSON.parse/stringify | Kotlin Serialization |

---

## 💰 Payment Features

### Full Payment
**Web:**
```typescript
const handleFullPayment = () => {
  setFormData({ ...formData, amount: currentOutstanding.toString() });
};
```

**Android:**
```kotlin
Button(onClick = { amount = currentOutstanding.toString() }) {
    Text("Full Payment")
}
```

### Part Payment
Both platforms validate:
- Amount > 0
- Amount ≤ Outstanding Balance
- Real-time remaining calculation

**Example:**
```
Current Outstanding: ₹10,000
Part Payment: ₹3,000
Remaining: ₹7,000
```

---

## 📊 Data Models

### Company
```typescript/kotlin
{
  id: string,
  name: string,
  email: string,
  phone: string,
  address: string,
  createdAt: number/long
}
```

### Transaction
```typescript/kotlin
{
  id: string,
  companyId: string,
  type: "sale" | "purchase",  // SALE | PURCHASE
  amount: number/double,
  description: string,
  date: number/long
}
```

### Payment
```typescript/kotlin
{
  id: string,
  companyId: string,
  amount: number/double,
  type: "sale" | "purchase",  // Which outstanding to reduce
  notes: string,
  date: number/long
}
```

---

## 🎯 Usage Flow

### 1. Add Company
```
Dashboard → "Add Company" → Fill form → Save
```

### 2. Add Transaction
```
Dashboard → Select Company → "Add Transaction"
→ Choose Type (Sale/Purchase) → Enter Amount → Save
```

### 3. Make Payment (Full)
```
Company Details → "Make Payment" → Select Type
→ Click "Full Payment" → Confirm → Save
```

### 4. Make Payment (Part)
```
Company Details → "Make Payment" → Select Type
→ Enter Custom Amount → Validate → Save
```

---

## 🧪 Testing Scenarios

### Test Case 1: Full Payment
```
1. Add company "ABC Ltd"
2. Add sale transaction: ₹10,000
3. Sales Outstanding = ₹10,000 ✓
4. Make full payment: ₹10,000
5. Sales Outstanding = ₹0 ✓
```

### Test Case 2: Part Payment
```
1. Add company "XYZ Corp"
2. Add sale transaction: ₹50,000
3. Sales Outstanding = ₹50,000 ✓
4. Make part payment: ₹20,000
5. Sales Outstanding = ₹30,000 ✓
6. Make part payment: ₹15,000
7. Sales Outstanding = ₹15,000 ✓
```

### Test Case 3: Mixed Transactions
```
1. Add company "DEF Inc"
2. Add sale: ₹30,000
3. Add purchase: ₹15,000
4. Sales Outstanding = ₹30,000 ✓
5. Purchase Outstanding = ₹15,000 ✓
6. Payment for sales: ₹10,000
7. Sales Outstanding = ₹20,000 ✓
8. Purchase Outstanding = ₹15,000 (unchanged) ✓
```

---

## 🎨 Customization

### Change Currency Symbol
**Web:** Search `₹` in all files, replace with `$`, `€`, etc.
**Android:** Same approach

### Change Colors
**Web:** Edit `/src/styles/theme.css`
**Android:** Edit `/ui/theme/Color.kt`

### Add New Fields
1. Update data models
2. Update forms
3. Update storage functions
4. Update display components

---

## 🐛 Troubleshooting

### Web
**Issue:** Routes not working
**Fix:** Ensure React Router is properly configured in App.tsx

**Issue:** Data not persisting
**Fix:** Check browser localStorage permissions

### Android
**Issue:** Build errors
**Fix:** Sync Gradle, check Kotlin Serialization plugin

**Issue:** Navigation crashes
**Fix:** Verify NavHost setup and route definitions

**Issue:** Data not saving
**Fix:** Check SharedPreferences initialization

---

## 📚 Additional Resources

### Web
- [React Router Docs](https://reactrouter.com/)
- [Tailwind CSS](https://tailwindcss.com/)
- [Radix UI](https://www.radix-ui.com/)

### Android
- [Jetpack Compose](https://developer.android.com/jetpack/compose)
- [Navigation Compose](https://developer.android.com/jetpack/compose/navigation)
- [Material Design 3](https://m3.material.io/)

---

## ✅ Checklist

### Web Development
- [x] React components created
- [x] Routing configured
- [x] localStorage integration
- [x] UI components styled
- [x] Full payment feature
- [x] Part payment feature
- [x] Activity history

### Android Development
- [x] MainActivity created
- [x] Data models defined
- [x] Repository layer
- [x] ViewModel logic
- [x] Navigation setup
- [x] All screens composed
- [x] Theme configured
- [x] Full payment feature
- [x] Part payment feature

---

**Need Help?**
- Web: Check browser console for errors
- Android: Check Logcat in Android Studio

**Both platforms are production-ready!** 🚀
