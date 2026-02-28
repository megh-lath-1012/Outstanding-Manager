package com.example.outstandingmanager.data.models

import kotlinx.serialization.Serializable

@Serializable
data class Company(
    val id: String,
    val name: String,
    val email: String = "",
    val phone: String = "",
    val address: String = "",
    val createdAt: Long = System.currentTimeMillis()
)

@Serializable
data class Transaction(
    val id: String,
    val companyId: String,
    val type: TransactionType,
    val amount: Double,
    val description: String = "",
    val date: Long = System.currentTimeMillis()
)

enum class TransactionType {
    SALE,      // They owe you
    PURCHASE   // You owe them
}

@Serializable
data class Payment(
    val id: String,
    val companyId: String,
    val amount: Double,
    val type: TransactionType, // Which outstanding type this payment is for
    val notes: String = "",
    val date: Long = System.currentTimeMillis()
)

data class OutstandingSummary(
    val salesOutstanding: Double = 0.0,
    val purchaseOutstanding: Double = 0.0
)

data class ActivityItem(
    val id: String,
    val type: ActivityType,
    val transactionType: TransactionType,
    val amount: Double,
    val description: String,
    val date: Long
)

enum class ActivityType {
    TRANSACTION,
    PAYMENT
}
