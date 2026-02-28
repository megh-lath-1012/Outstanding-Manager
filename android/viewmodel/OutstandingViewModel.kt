package com.example.outstandingmanager.viewmodel

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.outstandingmanager.data.models.*
import com.example.outstandingmanager.data.repository.OutstandingRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.util.UUID

class OutstandingViewModel(
    private val repository: OutstandingRepository
) : ViewModel() {

    val companies: StateFlow<List<Company>> = repository.companies
    val transactions: StateFlow<List<Transaction>> = repository.transactions
    val payments: StateFlow<List<Payment>> = repository.payments

    private val _selectedCompany = MutableStateFlow<Company?>(null)
    val selectedCompany: StateFlow<Company?> = _selectedCompany.asStateFlow()

    private val _outstandingSummary = MutableStateFlow(OutstandingSummary())
    val outstandingSummary: StateFlow<OutstandingSummary> = _outstandingSummary.asStateFlow()

    private val _companyActivities = MutableStateFlow<List<ActivityItem>>(emptyList())
    val companyActivities: StateFlow<List<ActivityItem>> = _companyActivities.asStateFlow()

    fun addCompany(
        name: String,
        email: String,
        phone: String,
        address: String
    ) {
        val company = Company(
            id = UUID.randomUUID().toString(),
            name = name,
            email = email,
            phone = phone,
            address = address
        )
        viewModelScope.launch {
            repository.saveCompany(company)
        }
    }

    fun selectCompany(companyId: String) {
        viewModelScope.launch {
            _selectedCompany.value = repository.getCompanyById(companyId)
            _outstandingSummary.value = repository.calculateOutstanding(companyId)
            _companyActivities.value = repository.getActivityByCompany(companyId)
        }
    }

    fun clearSelectedCompany() {
        _selectedCompany.value = null
        _outstandingSummary.value = OutstandingSummary()
        _companyActivities.value = emptyList()
    }

    fun addTransaction(
        companyId: String,
        type: TransactionType,
        amount: Double,
        description: String,
        date: Long = System.currentTimeMillis()
    ) {
        val transaction = Transaction(
            id = UUID.randomUUID().toString(),
            companyId = companyId,
            type = type,
            amount = amount,
            description = description,
            date = date
        )
        viewModelScope.launch {
            repository.saveTransaction(transaction)
            // Refresh data
            _outstandingSummary.value = repository.calculateOutstanding(companyId)
            _companyActivities.value = repository.getActivityByCompany(companyId)
        }
    }

    fun addPayment(
        companyId: String,
        amount: Double,
        type: TransactionType,
        notes: String,
        date: Long = System.currentTimeMillis()
    ) {
        val payment = Payment(
            id = UUID.randomUUID().toString(),
            companyId = companyId,
            amount = amount,
            type = type,
            notes = notes,
            date = date
        )
        viewModelScope.launch {
            repository.savePayment(payment)
            // Refresh data
            _outstandingSummary.value = repository.calculateOutstanding(companyId)
            _companyActivities.value = repository.getActivityByCompany(companyId)
        }
    }

    fun getOutstandingForCompany(companyId: String): OutstandingSummary {
        return repository.calculateOutstanding(companyId)
    }

    class Factory(private val context: Context) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            if (modelClass.isAssignableFrom(OutstandingViewModel::class.java)) {
                return OutstandingViewModel(OutstandingRepository(context)) as T
            }
            throw IllegalArgumentException("Unknown ViewModel class")
        }
    }
}
