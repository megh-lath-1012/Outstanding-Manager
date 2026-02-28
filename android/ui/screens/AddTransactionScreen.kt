package com.example.outstandingmanager.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.example.outstandingmanager.data.models.TransactionType
import com.example.outstandingmanager.viewmodel.OutstandingViewModel
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddTransactionScreen(
    viewModel: OutstandingViewModel,
    companyId: String,
    onNavigateBack: () -> Unit
) {
    LaunchedEffect(companyId) {
        viewModel.selectCompany(companyId)
    }

    val company by viewModel.selectedCompany.collectAsState()

    var transactionType by remember { mutableStateOf(TransactionType.SALE) }
    var amount by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    var selectedDate by remember { mutableStateOf(System.currentTimeMillis()) }
    var showError by remember { mutableStateOf(false) }
    var expanded by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(
                            "Add Transaction",
                            style = MaterialTheme.typography.headlineSmall,
                            fontWeight = FontWeight.Bold
                        )
                        company?.let {
                            Text(
                                "Record a sale or purchase for ${it.name}",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, "Back")
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Transaction Type Dropdown
            ExposedDropdownMenuBox(
                expanded = expanded,
                onExpandedChange = { expanded = !expanded }
            ) {
                OutlinedTextField(
                    value = if (transactionType == TransactionType.SALE) "Sale (They owe you)" else "Purchase (You owe them)",
                    onValueChange = {},
                    readOnly = true,
                    label = { Text("Transaction Type *") },
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
                    modifier = Modifier
                        .fillMaxWidth()
                        .menuAnchor(),
                    colors = ExposedDropdownMenuDefaults.outlinedTextFieldColors()
                )
                ExposedDropdownMenu(
                    expanded = expanded,
                    onDismissRequest = { expanded = false }
                ) {
                    DropdownMenuItem(
                        text = { Text("Sale (They owe you)") },
                        onClick = {
                            transactionType = TransactionType.SALE
                            expanded = false
                        }
                    )
                    DropdownMenuItem(
                        text = { Text("Purchase (You owe them)") },
                        onClick = {
                            transactionType = TransactionType.PURCHASE
                            expanded = false
                        }
                    )
                }
            }

            Text(
                text = if (transactionType == TransactionType.SALE)
                    "This will increase their outstanding to you"
                else
                    "This will increase your outstanding to them",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            OutlinedTextField(
                value = amount,
                onValueChange = {
                    amount = it
                    showError = false
                },
                label = { Text("Amount (₹) *") },
                modifier = Modifier.fillMaxWidth(),
                isError = showError && (amount.toDoubleOrNull() ?: 0.0) <= 0,
                supportingText = if (showError && (amount.toDoubleOrNull() ?: 0.0) <= 0) {
                    { Text("Please enter a valid amount") }
                } else null,
                singleLine = true,
                prefix = { Text("₹") }
            )

            OutlinedTextField(
                value = description,
                onValueChange = { description = it },
                label = { Text("Description") },
                modifier = Modifier.fillMaxWidth(),
                minLines = 3,
                maxLines = 5,
                placeholder = { Text("Optional notes about this transaction") }
            )

            Text(
                "Date: ${SimpleDateFormat("dd MMM yyyy", Locale.getDefault()).format(Date(selectedDate))}",
                style = MaterialTheme.typography.bodyMedium
            )

            Spacer(modifier = Modifier.weight(1f))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OutlinedButton(
                    onClick = onNavigateBack,
                    modifier = Modifier.weight(1f)
                ) {
                    Text("Cancel")
                }
                Button(
                    onClick = {
                        val amountValue = amount.toDoubleOrNull() ?: 0.0
                        if (amountValue <= 0) {
                            showError = true
                        } else {
                            viewModel.addTransaction(
                                companyId = companyId,
                                type = transactionType,
                                amount = amountValue,
                                description = description,
                                date = selectedDate
                            )
                            onNavigateBack()
                        }
                    },
                    modifier = Modifier.weight(1f)
                ) {
                    Text("Add Transaction")
                }
            }
        }
    }
}
