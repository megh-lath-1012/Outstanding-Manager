# Outstanding Manager - Android (Jetpack Compose)

A comprehensive Android application to manage sales and purchase outstandings with full and partial payment facilities.

## 📱 Features

### Core Functionality
- **Company Management**: Add and manage multiple companies with contact details
- **Transaction Tracking**: Record sales (receivables) and purchases (payables)
- **Payment Processing**: 
  - ✅ Full Payment: One-click settlement of entire outstanding
  - ✅ Part Payment: Flexible partial payments with automatic balance calculation
- **Real-time Outstanding Calculation**: Automatic calculation of pending amounts
- **Activity History**: Complete timeline of all transactions and payments

### Technical Features
- Material Design 3 with Dynamic Colors (Android 12+)
- MVVM Architecture
- Jetpack Compose UI
- Navigation Component
- SharedPreferences for local data persistence
- Kotlin Coroutines & Flow for reactive data

## 🏗️ Project Structure

```
app/src/main/java/com/example/outstandingmanager/
├── MainActivity.kt                          # Entry point
├── data/
│   ├── models/
│   │   └── Models.kt                       # Data classes (Company, Transaction, Payment, etc.)
│   └── repository/
│       └── OutstandingRepository.kt        # Data layer with SharedPreferences
├── viewmodel/
│   └── OutstandingViewModel.kt             # Business logic & state management
├── ui/
│   ├── navigation/
│   │   └── Navigation.kt                   # Navigation setup
│   ├── screens/
│   │   ├── DashboardScreen.kt             # Company list
│   │   ├── AddCompanyScreen.kt            # Add new company
│   │   ├── CompanyDetailsScreen.kt        # Company details & activity
│   │   ├── AddTransactionScreen.kt        # Record sale/purchase
│   │   └── MakePaymentScreen.kt           # Full/Part payment
│   └── theme/
│       ├── Color.kt                        # Color definitions
│       ├── Theme.kt                        # Material Theme setup
│       └── Type.kt                         # Typography
```

## 📦 Dependencies

Add to your `build.gradle.kts`:

```kotlin
dependencies {
    // Core
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
    implementation("androidx.activity:activity-compose:1.8.2")
    
    // Compose
    implementation(platform("androidx.compose:compose-bom:2024.01.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    
    // Navigation
    implementation("androidx.navigation:navigation-compose:2.7.6")
    
    // ViewModel
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.7.0")
    
    // Serialization
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.2")
}
```

## 🚀 Setup Instructions

### 1. Create New Android Studio Project
- Open Android Studio
- Select "New Project" → "Empty Activity"
- Choose Jetpack Compose as the UI framework
- Set minimum SDK to API 24 (Android 7.0)

### 2. Copy Files
Copy all files from this repository to your Android Studio project:

```
/android/* → /app/src/main/java/com/example/outstandingmanager/
```

### 3. Update build.gradle.kts
- Add Kotlin Serialization plugin
- Add all dependencies listed above

### 4. Sync Gradle
- Click "Sync Now" to download all dependencies

### 5. Run
- Connect your Android device or start an emulator
- Click Run ▶️

## 💡 How It Works

### Data Flow
1. **User Input** → UI Screen (Composable)
2. **UI Event** → ViewModel (business logic)
3. **Data Operation** → Repository (SharedPreferences)
4. **State Update** → Flow/StateFlow
5. **UI Update** → Recompose with new state

### Payment Logic
```kotlin
// Full Payment
currentOutstanding = salesOutstanding // e.g., ₹10,000
paymentAmount = ₹10,000
remaining = ₹0 ✓

// Part Payment
currentOutstanding = salesOutstanding // e.g., ₹10,000
paymentAmount = ₹3,000
remaining = ₹7,000 ✓
```

### Outstanding Calculation
```kotlin
salesOutstanding = totalSales - totalSalesPayments
purchaseOutstanding = totalPurchases - totalPurchasePayments
```

## 🎨 UI Components

### DashboardScreen
- Displays all companies in a grid/list
- Shows sales & purchase outstandings for each
- FAB to add new company

### CompanyDetailsScreen
- Company information card
- Outstanding summary with color coding:
  - 🟢 Green: Sales Outstanding (money owed to you)
  - 🔴 Red: Purchase Outstanding (money you owe)
- Activity timeline with all transactions & payments

### MakePaymentScreen
- Payment type selector (Sales/Purchase)
- Current outstanding display
- **Full Payment** button for one-click settlement
- Amount input with validation
- Real-time remaining balance calculation

## 🔧 Customization

### Change Colors
Edit `/ui/theme/Color.kt`:
```kotlin
val CustomGreen = Color(0xFF4CAF50)
val CustomRed = Color(0xFFF44336)
```

### Change Currency
Search and replace `₹` with your currency symbol throughout the project.

### Add New Fields
1. Update data models in `Models.kt`
2. Update UI forms in screen composables
3. Update Repository save/load methods

## 📊 Data Storage

Data is stored locally using SharedPreferences in JSON format:
- **Key**: `outstanding_prefs`
- **Companies**: Serialized list of Company objects
- **Transactions**: Serialized list of Transaction objects
- **Payments**: Serialized list of Payment objects

## 🐛 Common Issues

### Issue: Build errors
**Solution**: Make sure Kotlin Serialization plugin is added in build.gradle.kts

### Issue: Navigation not working
**Solution**: Verify navigation-compose dependency version matches Compose BOM version

### Issue: Data not persisting
**Solution**: Check SharedPreferences initialization in Repository

## 📱 Screenshots

### Dashboard
- Company cards with outstanding summaries
- Floating action button to add companies

### Company Details
- Detailed outstanding breakdown
- Complete transaction and payment history
- Quick action buttons

### Payment Screen
- **Full Payment** button for complete settlement
- **Part Payment** input with real-time balance display
- Payment validation

## 🚀 Future Enhancements

- [ ] Export data to PDF/Excel
- [ ] Backup to cloud (Firebase/Room)
- [ ] Multiple currency support
- [ ] Charts and analytics
- [ ] Payment reminders
- [ ] Search and filter
- [ ] Dark mode toggle

## 📄 License

This is a sample project for educational purposes.

## 👨‍💻 Support

For issues or questions:
1. Check the code comments
2. Review the data flow diagram
3. Test with sample data first

---

**Built with ❤️ using Jetpack Compose**
