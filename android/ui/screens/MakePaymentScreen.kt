package com.example.outstandingmanager.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Info
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.example.outstandingmanager.data.models.TransactionType
import com.example.outstandingmanager.viewmodel.OutstandingViewModel
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MakePaymentScreen(
    viewModel: OutstandingViewModel,
    companyId: String,
    onNavigateBack: () -> Unit
) {
    LaunchedEffect(companyId) {
        viewModel.selectCompany(companyId)
    }

    val company by viewModel.selectedCompany.collectAsState()
    val outstanding by viewModel.outstandingSummary.collectAsState()

    var paymentType by remember { mutableStateOf(TransactionType.SALE) }
    var amount by remember { mutableStateOf("") }
    var notes by remember { mutableStateOf("") }
    var selectedDate by remember { mutableStateOf(System.currentTimeMillis()) }
    var showError by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf("") }
    var expanded by remember { mutableStateOf(false) }

    val currentOutstanding = if (paymentType == TransactionType.SALE)
        outstanding.salesOutstanding
    else
        outstanding.purchaseOutstanding

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(
                            "Make Payment",
                            style = MaterialTheme.typography.headlineSmall,
                            fontWeight = FontWeight.Bold
                        )
                        company?.let {
                            Text(
                                "Record a full or partial payment for ${it.name}",
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
            // Payment Type Dropdown
            ExposedDropdownMenuBox(
                expanded = expanded,
                onExpandedChange = { expanded = !expanded }
            ) {
                OutlinedTextField(
                    value = if (paymentType == TransactionType.SALE)
                        "Sales Outstanding (They pay you)"
                    else
                        "Purchase Outstanding (You pay them)",
                    onValueChange = {},
                    readOnly = true,
                    label = { Text("Payment For *") },
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
                        text = { Text("Sales Outstanding (They pay you)") },
                        onClick = {
                            paymentType = TransactionType.SALE
                            amount = ""
                            expanded = false
                        }
                    )
                    DropdownMenuItem(
                        text = { Text("Purchase Outstanding (You pay them)") },
                        onClick = {
                            paymentType = TransactionType.PURCHASE
                            amount = ""
                            expanded = false
                        }
                    )
                }
            }

            // Outstanding Alert
            Card(
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer
                )
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.Default.Info,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onPrimaryContainer
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    Column {
                        Text(
                            "Current ${if (paymentType == TransactionType.SALE) "Sales" else "Purchase"} Outstanding:",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onPrimaryContainer
                        )
                        Text(
                            "₹${String.format("%,.2f", currentOutstanding)}",
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onPrimaryContainer
                        )
                    }
                }
            }

            if (currentOutstanding == 0.0) {
                Card(
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.errorContainer
                    )
                ) {
                    Text(
                        "No outstanding balance for ${if (paymentType == TransactionType.SALE) "sales" else "purchases"}. " +
                                "Please select a different payment type or add transactions first.",
                        modifier = Modifier.padding(16.dp),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onErrorContainer
                    )
                }
            } else {
                // Amount Input with Full Payment Button
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedTextField(
                        value = amount,
                        onValueChange = {
                            amount = it
                            showError = false
                        },
                        label = { Text("Payment Amount (₹) *") },
                        modifier = Modifier.weight(1f),
                        isError = showError,
                        supportingText = if (showError) {
                            { Text(errorMessage) }
                        } else null,
                        singleLine = true,
                        prefix = { Text("₹") }
                    )
                    Button(
                        onClick = {
                            amount = currentOutstanding.toString()
                        },
                        modifier = Modifier.height(56.dp)
                    ) {
                        Text("Full Payment")
                    }
                }

                // Payment Info
                if (amount.isNotEmpty()) {
                    val amountValue = amount.toDoubleOrNull() ?: 0.0
                    if (amountValue > 0 && amountValue <= currentOutstanding) {
                        Text(
                            text = when {
                                amountValue < currentOutstanding ->
                                    "Part payment: ₹${String.format("%,.2f", currentOutstanding - amountValue)} will remain outstanding"
                                else ->
                                    "This will clear the full outstanding amount"
                            },
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                OutlinedTextField(
                    value = notes,
                    onValueChange = { notes = it },
                    label = { Text("Notes") },
                    modifier = Modifier.fillMaxWidth(),
                    minLines = 3,
                    maxLines = 5,
                    placeholder = { Text("Optional notes about this payment") }
                )

                Text(
                    "Payment Date: ${SimpleDateFormat("dd MMM yyyy", Locale.getDefault()).format(Date(selectedDate))}",
                    style = MaterialTheme.typography.bodyMedium
                )
            }

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
                        when {
                            amountValue <= 0 -> {
                                showError = true
                                errorMessage = "Please enter a valid amount"
                            }
                            amountValue > currentOutstanding -> {
                                showError = true
                                errorMessage = "Amount cannot exceed outstanding of ₹${String.format("%,.2f", currentOutstanding)}"
                            }
                            currentOutstanding == 0.0 -> {
                                showError = true
                                errorMessage = "No outstanding balance"
                            }
                            else -> {
                                viewModel.addPayment(
                                    companyId = companyId,
                                    amount = amountValue,
                                    type = paymentType,
                                    notes = notes,
                                    date = selectedDate
                                )
                                onNavigateBack()
                            }
                        }
                    },
                    modifier = Modifier.weight(1f),
                    enabled = currentOutstanding > 0
                ) {
                    Text("Record Payment")
                }
            }
        }
    }
}
