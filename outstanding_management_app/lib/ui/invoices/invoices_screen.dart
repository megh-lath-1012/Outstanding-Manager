import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/invoice_provider.dart';
import '../../models/invoice_model.dart';
import 'add_invoice_screen.dart'; // We'll build next

class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(text: 'Sales'),
            Tab(text: 'Purchases'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
               // Implement filter
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInvoiceList('sales'),
          _buildInvoiceList('purchase'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_shopping_cart),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
               builder: (_) => AddInvoiceScreen(
                  invoiceType: _tabController.index == 0 ? 'sales' : 'purchase',
               )
            ),
          );
        },
      ),
    );
  }

  Widget _buildInvoiceList(String invoiceType) {
    final query = InvoiceQuery(invoiceType: invoiceType);
    final invoicesAsync = ref.watch(invoicesProvider(query));

    return invoicesAsync.when(
      data: (invoices) {
        if (invoices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description_outlined, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'No $invoiceType invoices yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(invoicesProvider(query)),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: invoices.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final invoice = invoices[index];
              return _buildInvoiceCard(invoice);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice) {
    Color statusColor;
    switch (invoice.paymentStatus) {
      case 'paid':
        statusColor = Colors.green;
        break;
      case 'partial':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = invoice.isOverdue ? Colors.red : Colors.grey;
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: invoice.isOverdue 
            ? const BorderSide(color: Colors.redAccent, width: 1) 
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
           // Navigate to detail
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    invoice.invoiceNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      invoice.isOverdue ? 'OVERDUE' : invoice.paymentStatus.toUpperCase(),
                      style: TextStyle(
                        color: statusColor, 
                        fontSize: 10, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                invoice.partyName,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         'Total',
                         style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                       ),
                       Text(
                          currencyFormat.format(invoice.totalAmount),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                       ),
                     ],
                   ),
                   if (invoice.outstandingAmount > 0)
                     Column(
                       crossAxisAlignment: CrossAxisAlignment.end,
                       children: [
                         Text(
                           'Due',
                           style: TextStyle(color: Colors.red.shade400, fontSize: 12),
                         ),
                         Text(
                            currencyFormat.format(invoice.outstandingAmount),
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade600),
                         ),
                       ],
                     ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
