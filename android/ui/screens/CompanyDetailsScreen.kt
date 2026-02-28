package com.example.outstandingmanager.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.example.outstandingmanager.data.models.ActivityType
import com.example.outstandingmanager.data.models.TransactionType
import com.example.outstandingmanager.viewmodel.OutstandingViewModel
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CompanyDetailsScreen(
    viewModel: OutstandingViewModel,
    companyId: String,
    onNavigateBack: () -> Unit,
    onNavigateToAddTransaction: () -> Unit,
    onNavigateToMakePayment: () -> Unit
) {
    LaunchedEffect(companyId) {
        viewModel.selectCompany(companyId)
    }

    DisposableEffect(Unit) {
        onDispose {
            viewModel.clearSelectedCompany()
        }
    }

    val company by viewModel.selectedCompany.collectAsState()
    val outstanding by viewModel.outstandingSummary.collectAsState()
    val activities by viewModel.companyActivities.collectAsState()

    company?.let { comp ->
        Scaffold(
            topBar = {
                TopAppBar(
                    title = { Text(comp.name) },
                    navigationIcon = {
                        IconButton(onClick = onNavigateBack) {
                            Icon(Icons.AutoMirrored.Filled.ArrowBack, "Back")
                        }
                    }
                )
            }
        ) { paddingValues ->
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Company Info Card
                item {
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.primaryContainer
                        )
                    ) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            Text(
                                "Company Details",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold
                            )
                            Spacer(modifier = Modifier.height(12.dp))
                            if (comp.email.isNotEmpty()) {
                                CompanyDetailRow("Email", comp.email)
                                Spacer(modifier = Modifier.height(8.dp))
                            }
                            if (comp.phone.isNotEmpty()) {
                                CompanyDetailRow("Phone", comp.phone)
                                Spacer(modifier = Modifier.height(8.dp))
                            }
                            if (comp.address.isNotEmpty()) {
                                CompanyDetailRow("Address", comp.address)
                            }
                        }
                    }
                }

                // Outstanding Summary Card
                item {
                    Card(modifier = Modifier.fillMaxWidth()) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            Text(
                                "Outstanding Summary",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold
                            )
                            Spacer(modifier = Modifier.height(16.dp))

                            // Sales Outstanding
                            Surface(
                                modifier = Modifier.fillMaxWidth(),
                                shape = MaterialTheme.shapes.medium,
                                color = MaterialTheme.colorScheme.tertiaryContainer
                            ) {
                                Column(modifier = Modifier.padding(16.dp)) {
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Icon(
                                            Icons.Default.TrendingUp,
                                            contentDescription = null,
                                            tint = MaterialTheme.colorScheme.onTertiaryContainer
                                        )
                                        Spacer(modifier = Modifier.width(8.dp))
                                        Text(
                                            "Sales Outstanding",
                                            style = MaterialTheme.typography.labelMedium,
                                            color = MaterialTheme.colorScheme.onTertiaryContainer
                                        )
                                    }
                                    Text(
                                        "₹${String.format("%,.2f", outstanding.salesOutstanding)}",
                                        style = MaterialTheme.typography.headlineMedium,
                                        fontWeight = FontWeight.Bold,
                                        color = MaterialTheme.colorScheme.onTertiaryContainer
                                    )
                                    Text(
                                        "Amount they owe you",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onTertiaryContainer
                                    )
                                }
                            }

                            Spacer(modifier = Modifier.height(12.dp))

                            // Purchase Outstanding
                            Surface(
                                modifier = Modifier.fillMaxWidth(),
                                shape = MaterialTheme.shapes.medium,
                                color = MaterialTheme.colorScheme.errorContainer
                            ) {
                                Column(modifier = Modifier.padding(16.dp)) {
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Icon(
                                            Icons.Default.TrendingDown,
                                            contentDescription = null,
                                            tint = MaterialTheme.colorScheme.onErrorContainer
                                        )
                                        Spacer(modifier = Modifier.width(8.dp))
                                        Text(
                                            "Purchase Outstanding",
                                            style = MaterialTheme.typography.labelMedium,
                                            color = MaterialTheme.colorScheme.onErrorContainer
                                        )
                                    }
                                    Text(
                                        "₹${String.format("%,.2f", outstanding.purchaseOutstanding)}",
                                        style = MaterialTheme.typography.headlineMedium,
                                        fontWeight = FontWeight.Bold,
                                        color = MaterialTheme.colorScheme.onErrorContainer
                                    )
                                    Text(
                                        "Amount you owe them",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onErrorContainer
                                    )
                                }
                            }

                            Spacer(modifier = Modifier.height(16.dp))

                            // Action Buttons
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                Button(
                                    onClick = onNavigateToAddTransaction,
                                    modifier = Modifier.weight(1f)
                                ) {
                                    Icon(Icons.Default.Add, contentDescription = null)
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text("Add Transaction")
                                }
                                OutlinedButton(
                                    onClick = onNavigateToMakePayment,
                                    modifier = Modifier.weight(1f)
                                ) {
                                    Icon(Icons.Default.AccountBalanceWallet, contentDescription = null)
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text("Make Payment")
                                }
                            }
                        }
                    }
                }

                // Activity History
                item {
                    Text(
                        "Activity History",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                }

                if (activities.isEmpty()) {
                    item {
                        Card(modifier = Modifier.fillMaxWidth()) {
                            Column(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(48.dp),
                                horizontalAlignment = Alignment.CenterHorizontally
                            ) {
                                Icon(
                                    Icons.Default.Receipt,
                                    contentDescription = null,
                                    modifier = Modifier.size(48.dp),
                                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                                Spacer(modifier = Modifier.height(16.dp))
                                Text(
                                    "No activity yet",
                                    style = MaterialTheme.typography.titleMedium,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                                Text(
                                    "Add a transaction or payment to get started",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }
                    }
                } else {
                    items(activities) { activity ->
                        ActivityItemCard(activity = activity)
                    }
                }
            }
        }
    }
}

@Composable
private fun CompanyDetailRow(label: String, value: String) {
    Column {
        Text(
            label,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(
            value,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.Medium
        )
    }
}

@Composable
private fun ActivityItemCard(
    activity: com.example.outstandingmanager.data.models.ActivityItem
) {
    val dateFormat = SimpleDateFormat("dd MMM yyyy", Locale.getDefault())
    val isTransaction = activity.type == ActivityType.TRANSACTION

    Card(modifier = Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Surface(
                shape = MaterialTheme.shapes.small,
                color = when {
                    isTransaction && activity.transactionType == TransactionType.SALE ->
                        MaterialTheme.colorScheme.tertiaryContainer
                    isTransaction && activity.transactionType == TransactionType.PURCHASE ->
                        MaterialTheme.colorScheme.errorContainer
                    else -> MaterialTheme.colorScheme.primaryContainer
                },
                modifier = Modifier.size(40.dp)
            ) {
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier.fillMaxSize()
                ) {
                    Icon(
                        imageVector = when {
                            isTransaction && activity.transactionType == TransactionType.SALE ->
                                Icons.Default.TrendingUp
                            isTransaction && activity.transactionType == TransactionType.PURCHASE ->
                                Icons.Default.TrendingDown
                            else -> Icons.Default.AccountBalanceWallet
                        },
                        contentDescription = null,
                        tint = when {
                            isTransaction && activity.transactionType == TransactionType.SALE ->
                                MaterialTheme.colorScheme.onTertiaryContainer
                            isTransaction && activity.transactionType == TransactionType.PURCHASE ->
                                MaterialTheme.colorScheme.onErrorContainer
                            else -> MaterialTheme.colorScheme.onPrimaryContainer
                        }
                    )
                }
            }

            Spacer(modifier = Modifier.width(12.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = if (isTransaction) {
                        val type = if (activity.transactionType == TransactionType.SALE) "Sale" else "Purchase"
                        if (activity.description.isNotEmpty()) "$type: ${activity.description}"
                        else type
                    } else {
                        if (activity.description.isNotEmpty()) "Payment: ${activity.description}"
                        else "Payment"
                    },
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium
                )
                Text(
                    dateFormat.format(Date(activity.date)),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                if (!isTransaction) {
                    AssistChip(
                        onClick = { },
                        label = {
                            Text(
                                if (activity.transactionType == TransactionType.SALE) "For Sales" else "For Purchases",
                                style = MaterialTheme.typography.labelSmall
                            )
                        },
                        modifier = Modifier.padding(top = 4.dp)
                    )
                }
            }

            Column(horizontalAlignment = Alignment.End) {
                Text(
                    "${if (!isTransaction) "-" else ""}₹${String.format("%,.2f", activity.amount)}",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = when {
                        isTransaction && activity.transactionType == TransactionType.SALE ->
                            MaterialTheme.colorScheme.tertiary
                        isTransaction && activity.transactionType == TransactionType.PURCHASE ->
                            MaterialTheme.colorScheme.error
                        else -> MaterialTheme.colorScheme.primary
                    }
                )
            }
        }
    }
}
