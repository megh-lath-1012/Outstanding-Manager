import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/payment_provider.dart';
import '../../models/payment_model.dart';
import '../../models/party_model.dart';
import 'add_payment_screen.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '\u20b9',
  );

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
        title: const Text('Payments'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(text: 'Received (IN)'),
            Tab(text: 'Paid (OUT)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildPaymentList('receipt'), _buildPaymentList('payment')],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_card),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddPaymentScreen(
                paymentType: _tabController.index == 0 ? 'receipt' : 'payment',
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentList(String paymentType) {
    final query = PaymentQuery(paymentType: paymentType);
    final paymentsAsync = ref.watch(paymentsProvider(query));

    return paymentsAsync.when(
      data: (payments) {
        if (payments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.payments_outlined,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  paymentType == 'receipt'
                      ? 'No receipts yet'
                      : 'No payments yet',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(paymentsProvider(query)),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final payment = payments[index];
              return _buildPaymentCard(payment);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildPaymentCard(Payment payment) {
    final isReceipt = payment.paymentType == 'receipt';
    final amountColor = isReceipt ? Colors.green : Colors.red;
    final prefix = isReceipt ? '+' : '-';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showPaymentActions(context, payment),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat(
                      'dd MMM yyyy, hh:mm a',
                    ).format(payment.paymentDate),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      payment.paymentMethod.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment.partyName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (payment.referenceNumber != null &&
                            payment.referenceNumber!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Ref: ${payment.referenceNumber}',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '$prefix ${currencyFormat.format(payment.totalAmount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: amountColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── PAYMENT DETAIL + ACTIONS BOTTOM SHEET ───
  void _showPaymentActions(BuildContext context, Payment payment) {
    final isReceipt = payment.paymentType == 'receipt';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isReceipt ? 'Receipt Details' : 'Payment Details',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),

                // Payment info
                _detailRow(Icons.person, 'Party', payment.partyName),
                _detailRow(
                  Icons.calendar_today,
                  'Date',
                  DateFormat('dd MMM yyyy').format(payment.paymentDate),
                ),
                _detailRow(
                  Icons.account_balance_wallet,
                  'Method',
                  payment.paymentMethod.replaceAll('_', ' ').toUpperCase(),
                ),
                _detailRow(
                  Icons.currency_rupee,
                  'Amount',
                  currencyFormat.format(payment.totalAmount),
                ),
                if (payment.referenceNumber != null &&
                    payment.referenceNumber!.isNotEmpty)
                  _detailRow(Icons.tag, 'Reference', payment.referenceNumber!),
                if (payment.notes != null && payment.notes!.isNotEmpty)
                  _detailRow(Icons.notes, 'Notes', payment.notes!),

                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _editPayment(payment);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _confirmDeletePayment(payment);
                        },
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ─── EDIT PAYMENT ───
  // Per spec: delete old payment, then open AddPaymentScreen pre-filled with old data
  void _editPayment(Payment payment) {
    // Create a synthetic Party to pre-fill the form
    final party = Party(
      id: payment.partyId,
      userId: '',
      partyType: payment.paymentType == 'receipt' ? 'customer' : 'supplier',
      name: payment.partyName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Navigate to the Add Payment screen with the party pre-filled
    // The user can then re-enter the allocation details
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddPaymentScreen(
          initialParty: party,
          paymentType: payment.paymentType,
        ),
      ),
    );

    // Show a hint that they should delete the old one if they want to replace it
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Creating a new entry. Delete the old one after saving if needed.',
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Delete Old',
          textColor: Colors.orange,
          onPressed: () => _deletePayment(payment),
        ),
      ),
    );
  }

  // ─── DELETE PAYMENT ───
  void _confirmDeletePayment(Payment payment) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Payment?'),
          content: Text(
            'This will permanently delete this ${payment.paymentType == 'receipt' ? 'receipt' : 'payment'} '
            'of ${currencyFormat.format(payment.totalAmount)} to ${payment.partyName} '
            'and reverse all invoice allocations.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _deletePayment(payment);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePayment(Payment payment) async {
    try {
      await ref.read(paymentRepositoryProvider).deletePayment(payment.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment deleted and invoice statuses reverted.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
