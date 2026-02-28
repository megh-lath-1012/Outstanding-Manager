package com.example.outstandingmanager.data.repository

import android.content.Context
import android.content.SharedPreferences
import com.example.outstandingmanager.data.models.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import kotlinx.serialization.decodeFromString

class OutstandingRepository(context: Context) {
    private val prefs: SharedPreferences = context.getSharedPreferences(
        "outstanding_prefs",
        Context.MODE_PRIVATE
    )

    private val json = Json { ignoreUnknownKeys = true }

    private val _companies = MutableStateFlow<List<Company>>(emptyList())
    val companies: StateFlow<List<Company>> = _companies.asStateFlow()

    private val _transactions = MutableStateFlow<List<Transaction>>(emptyList())
    val transactions: StateFlow<List<Transaction>> = _transactions.asStateFlow()

    private val _payments = MutableStateFlow<List<Payment>>(emptyList())
    val payments: StateFlow<List<Payment>> = _payments.asStateFlow()

    init {
        loadData()
    }

    private fun loadData() {
        _companies.value = loadCompanies()
        _transactions.value = loadTransactions()
        _payments.value = loadPayments()
    }

    // Companies
    private fun loadCompanies(): List<Company> {
        val companiesJson = prefs.getString(KEY_COMPANIES, null) ?: return emptyList()
        return try {
            json.decodeFromString<List<Company>>(companiesJson)
        } catch (e: Exception) {
            emptyList()
        }
    }

    fun saveCompany(company: Company) {
        val currentList = _companies.value.toMutableList()
        currentList.add(company)
        _companies.value = currentList
        prefs.edit().putString(KEY_COMPANIES, json.encodeToString(currentList)).apply()
    }

    fun getCompanyById(id: String): Company? {
        return _companies.value.find { it.id == id }
    }

    // Transactions
    private fun loadTransactions(): List<Transaction> {
        val transactionsJson = prefs.getString(KEY_TRANSACTIONS, null) ?: return emptyList()
        return try {
            json.decodeFromString<List<Transaction>>(transactionsJson)
        } catch (e: Exception) {
            emptyList()
        }
    }

    fun saveTransaction(transaction: Transaction) {
        val currentList = _transactions.value.toMutableList()
        currentList.add(transaction)
        _transactions.value = currentList
        prefs.edit().putString(KEY_TRANSACTIONS, json.encodeToString(currentList)).apply()
    }

    fun getTransactionsByCompany(companyId: String): List<Transaction> {
        return _transactions.value.filter { it.companyId == companyId }
    }

    // Payments
    private fun loadPayments(): List<Payment> {
        val paymentsJson = prefs.getString(KEY_PAYMENTS, null) ?: return emptyList()
        return try {
            json.decodeFromString<List<Payment>>(paymentsJson)
        } catch (e: Exception) {
            emptyList()
        }
    }

    fun savePayment(payment: Payment) {
        val currentList = _payments.value.toMutableList()
        currentList.add(payment)
        _payments.value = currentList
        prefs.edit().putString(KEY_PAYMENTS, json.encodeToString(currentList)).apply()
    }

    fun getPaymentsByCompany(companyId: String): List<Payment> {
        return _payments.value.filter { it.companyId == companyId }
    }

    // Calculate Outstanding
    fun calculateOutstanding(companyId: String): OutstandingSummary {
        val transactions = getTransactionsByCompany(companyId)
        val payments = getPaymentsByCompany(companyId)

        var totalSales = 0.0
        var totalPurchases = 0.0

        transactions.forEach { transaction ->
            when (transaction.type) {
                TransactionType.SALE -> totalSales += transaction.amount
                TransactionType.PURCHASE -> totalPurchases += transaction.amount
            }
        }

        var salesPaid = 0.0
        var purchasesPaid = 0.0

        payments.forEach { payment ->
            when (payment.type) {
                TransactionType.SALE -> salesPaid += payment.amount
                TransactionType.PURCHASE -> purchasesPaid += payment.amount
            }
        }

        return OutstandingSummary(
            salesOutstanding = maxOf(0.0, totalSales - salesPaid),
            purchaseOutstanding = maxOf(0.0, totalPurchases - purchasesPaid)
        )
    }

    // Get all activity for a company
    fun getActivityByCompany(companyId: String): List<ActivityItem> {
        val transactions = getTransactionsByCompany(companyId)
        val payments = getPaymentsByCompany(companyId)

        val activities = mutableListOf<ActivityItem>()

        transactions.forEach { transaction ->
            activities.add(
                ActivityItem(
                    id = transaction.id,
                    type = ActivityType.TRANSACTION,
                    transactionType = transaction.type,
                    amount = transaction.amount,
                    description = transaction.description,
                    date = transaction.date
                )
            )
        }

        payments.forEach { payment ->
            activities.add(
                ActivityItem(
                    id = payment.id,
                    type = ActivityType.PAYMENT,
                    transactionType = payment.type,
                    amount = payment.amount,
                    description = payment.notes,
                    date = payment.date
                )
            )
        }

        return activities.sortedByDescending { it.date }
    }

    companion object {
        private const val KEY_COMPANIES = "companies"
        private const val KEY_TRANSACTIONS = "transactions"
        private const val KEY_PAYMENTS = "payments"
    }
}
