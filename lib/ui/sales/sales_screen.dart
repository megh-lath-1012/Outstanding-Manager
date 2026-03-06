import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/invoice_provider.dart';
import '../../models/invoice_model.dart';
import '../../services/export_service.dart';
import '../payments/payment_history_screen.dart';
import '../ledger/party_ledger_screen.dart';
import '../payments/record_payment_screen.dart';
import 'add_sales_record_screen.dart';
import '../../services/collections_agent_service.dart';

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  final currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '\u20b9',
  );
  String _searchTerm = '';
  final _searchController = TextEditingController();

  // Pagination
  static const int _pageSize = 20;
  int _visibleCount = _pageSize;

  String _sortBy = 'Date: Oldest';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _sortInvoices(List<Invoice> list) {
    switch (_sortBy) {
      case 'Date: Newest':
        list.sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));
        break;
      case 'Date: Oldest':
        list.sort((a, b) => a.invoiceDate.compareTo(b.invoiceDate));
        break;
      case 'Amount: High to Low':
        list.sort((a, b) => b.outstandingAmount.compareTo(a.outstandingAmount));
        break;
      case 'Amount: Low to High':
        list.sort((a, b) => a.outstandingAmount.compareTo(b.outstandingAmount));
        break;
      case 'Party: A-Z':
        list.sort(
          (a, b) =>
              a.partyName.toLowerCase().compareTo(b.partyName.toLowerCase()),
        );
        break;
      case 'Party: Z-A':
        list.sort(
          (a, b) =>
              b.partyName.toLowerCase().compareTo(a.partyName.toLowerCase()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = InvoiceQuery(invoiceType: 'sales', searchTerm: _searchTerm);
    final invoicesAsync = ref.watch(invoicesProvider(query));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Outstanding'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) async {
              if (val == 'History') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const PaymentHistoryScreen(paymentType: 'receipt'),
                  ),
                );
              } else if (val == 'Ledger') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const PartyLedgerScreen(partyType: 'customer'),
                  ),
                );
              } else if (val == 'Excel' || val == 'PDF') {
                final allInvoices = invoicesAsync.value ?? [];
                final invoices = allInvoices
                    .where((inv) => inv.paymentStatus != 'paid')
                    .toList();
                _sortInvoices(invoices);
                final total = invoices.fold(
                  0.0,
                  (s, i) => s + i.outstandingAmount,
                );
                final service = ExportService();

                if (mounted) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) =>
                        const Center(child: CircularProgressIndicator()),
                  );
                }

                try {
                  String? filePath;
                  if (val == 'Excel') {
                    filePath = await service.exportToExcel(
                      title: 'Sales Outstanding',
                      invoices: invoices,
                      totalOutstanding: total,
                    );
                  } else {
                    filePath = await service.exportToPDF(
                      title: 'Sales Outstanding',
                      invoices: invoices,
                      totalOutstanding: total,
                    );
                  }

                  if (!context.mounted) return;
                  Navigator.pop(context); // Close loader

                  if (filePath != null) {
                    await SharePlus.instance.share(
                      ShareParams(
                        files: [XFile(filePath)],
                        subject: 'Sales Outstanding',
                      ),
                    );

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Sales Outstanding exported as $val'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context); // Close loader
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Export failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'History',
                child: ListTile(
                  leading: Icon(Icons.history),
                  title: Text('Payment History'),
                ),
              ),
              const PopupMenuItem(
                value: 'Ledger',
                child: ListTile(
                  leading: Icon(Icons.menu_book),
                  title: Text('Access Ledger'),
                ),
              ),
              const PopupMenuItem(
                value: 'Excel',
                child: ListTile(
                  leading: Icon(Icons.table_chart),
                  title: Text('Export to Excel'),
                ),
              ),
              const PopupMenuItem(
                value: 'PDF',
                child: ListTile(
                  leading: Icon(Icons.picture_as_pdf),
                  title: Text('Export to PDF'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search party or invoice...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchTerm.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchTerm = '';
                                  _visibleCount = _pageSize;
                                });
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (val) => setState(() {
                      _searchTerm = val;
                      _visibleCount = _pageSize;
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort),
                  tooltip: 'Sort By',
                  onSelected: (val) => setState(() => _sortBy = val),
                  itemBuilder: (_) =>
                      [
                            'Date: Oldest',
                            'Date: Newest',
                            'Amount: High to Low',
                            'Amount: Low to High',
                            'Party: A-Z',
                            'Party: Z-A',
                          ]
                          .map(
                            (s) => PopupMenuItem(
                              value: s,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check,
                                    color: _sortBy == s
                                        ? Colors.blue
                                        : Colors.transparent,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    s,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: _sortBy == s
                                          ? FontWeight.bold
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
          ),

          // Invoices list
          Expanded(
            child: invoicesAsync.when(
              data: (allInvoices) {
                final invoices = allInvoices
                    .where((inv) => inv.paymentStatus != 'paid')
                    .toList();
                _sortInvoices(invoices);

                if (invoices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No sales records yet',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final visibleInvoices = invoices.take(_visibleCount).toList();
                final hasMore = invoices.length > _visibleCount;

                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(invoicesProvider(query)),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    itemCount: visibleInvoices.length + (hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == visibleInvoices.length) {
                        // Load more button
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: OutlinedButton(
                              onPressed: () =>
                                  setState(() => _visibleCount += _pageSize),
                              child: const Text('Load More'),
                            ),
                          ),
                        );
                      }
                      return _buildInvoiceCard(visibleInvoices[index]);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, s) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddSalesRecordScreen()),
          );
        },
      ),
    );
  }

  Widget _buildInvoiceCard(Invoice inv) {
    final isPaid = inv.paymentStatus == 'paid';
    final statusColor = isPaid
        ? Colors.green
        : (inv.paymentStatus == 'partial' ? Colors.orange : Colors.red);

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: party + status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    inv.partyName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    inv.paymentStatus.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Row 2: invoice# + date
            Row(
              children: [
                Text(
                  inv.invoiceNumber,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 12),
                Text(
                  DateFormat('dd MMM yyyy').format(inv.invoiceDate),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Row 3: amounts + actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total: ${currencyFormat.format(inv.totalAmount)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (inv.outstandingAmount > 0)
                      Text(
                        'Due: ${currencyFormat.format(inv.outstandingAmount)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isPaid)
                      IconButton(
                        icon: const Icon(Icons.payments, color: Colors.green),
                        tooltip: 'Record Payment',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RecordPaymentScreen(
                                invoiceType: 'sales',
                                initialInvoice: inv,
                              ),
                            ),
                          );
                        },
                      ),
                    if (!isPaid &&
                        inv.dueDate != null &&
                        inv.dueDate!.isBefore(DateTime.now()))
                      IconButton(
                        icon: const Icon(Icons.message, color: Colors.blue),
                        tooltip: 'Send Reminder',
                        onPressed: () => _sendReminder(inv),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Delete',
                      onPressed: () => _confirmDelete(inv),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Invoice inv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Sales Record?'),
        content: Text(
          'Are you sure you want to delete ${inv.invoiceNumber} (${inv.partyName})? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(invoiceRepositoryProvider).deleteInvoice(inv.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Record deleted.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _sendReminder(Invoice inv) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Calculate total party outstanding first
      final query = InvoiceQuery(invoiceType: 'sales', partyId: inv.partyId);
      final invoices = await ref.read(invoicesProvider(query).future);
      final totalOutstanding = invoices.fold(
        0.0,
        (s, i) => s + i.outstandingAmount,
      );

      final reminderMsg = await ref
          .read(collectionsAgentServiceProvider)
          .generateReminder(inv, totalOutstanding);

      if (!mounted) return;
      Navigator.pop(context); // Close loader

      await SharePlus.instance.share(
          ShareParams(text: reminderMsg, subject: 'Invoice Reminder'));
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate reminder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
