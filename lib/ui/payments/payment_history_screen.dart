import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/payment_provider.dart';
import '../../models/payment_model.dart';

class PaymentHistoryScreen extends ConsumerStatefulWidget {
  final String paymentType; // 'receipt' or 'payment'

  const PaymentHistoryScreen({super.key, required this.paymentType});

  @override
  ConsumerState<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '\u20b9');
  String _searchTerm = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.paymentType == 'receipt' ? 'Receipt History' : 'Payment History';
    final query = PaymentQuery(paymentType: widget.paymentType);
    final paymentsAsync = ref.watch(paymentsProvider(query));

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by party name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchTerm.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); setState(() => _searchTerm = ''); })
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => setState(() => _searchTerm = val),
            ),
          ),
          Expanded(
            child: paymentsAsync.when(
              data: (payments) {
                final filtered = payments.where((p) => p.partyName.toLowerCase().contains(_searchTerm.toLowerCase())).toList();
                
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('No records found', style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final p = filtered[index];
                    return Card(
                      elevation: 0.5,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(p.partyName, style: const TextStyle(fontWeight: FontWeight.bold))),
                            Text(currencyFormat.format(p.totalAmount), style: TextStyle(fontWeight: FontWeight.bold, color: widget.paymentType == 'receipt' ? Colors.green : Colors.red)),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(DateFormat('dd MMM yyyy').format(p.paymentDate), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(color: Colors.blue.withAlpha(20), borderRadius: BorderRadius.circular(4)),
                                  child: Text(p.paymentMethod.toUpperCase(), style: const TextStyle(fontSize: 9, color: Colors.blue, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            if (p.notes != null) ...[
                              const SizedBox(height: 4),
                              Text(p.notes!, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.grey),
                          onPressed: () => _confirmDelete(p),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, s) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Payment p) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Delete Payment Record?'),
      content: const Text('This will delete the payment and update the outstanding amount on related invoices. This action cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              await ref.read(paymentRepositoryProvider).deletePayment(p.id);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment deleted.')));
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
            }
          },
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ));
  }
}
