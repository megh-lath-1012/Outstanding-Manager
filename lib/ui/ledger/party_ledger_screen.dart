import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/party_provider.dart';
import '../../models/party_model.dart';

class PartyLedgerScreen extends ConsumerStatefulWidget {
  final String partyType; // 'customer' or 'supplier'

  const PartyLedgerScreen({super.key, required this.partyType});

  @override
  ConsumerState<PartyLedgerScreen> createState() => _PartyLedgerScreenState();
}

class _PartyLedgerScreenState extends ConsumerState<PartyLedgerScreen> {
  Party? _selectedParty;
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '\u20b9');

  @override
  Widget build(BuildContext context) {
    final partiesAsync = ref.watch(partiesProvider(widget.partyType));

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedParty == null ? 'Access Ledger' : 'Ledger: ${_selectedParty!.name}'),
        actions: [
          if (_selectedParty != null)
            IconButton(
              icon: const Icon(Icons.person_search),
              onPressed: () => setState(() => _selectedParty = null),
              tooltip: 'Change Party',
            ),
        ],
      ),
      body: _selectedParty == null
          ? partiesAsync.when(
              data: (parties) => _buildPartyPicker(parties),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            )
          : _buildLedgerContent(),
    );
  }

  Widget _buildPartyPicker(List<Party> parties) {
    String search = '';
    return StatefulBuilder(builder: (context, setPickerState) {
      final filtered = parties.where((p) => p.name.toLowerCase().contains(search.toLowerCase())).toList();
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search ${widget.partyType}...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => setPickerState(() => search = val),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final p = filtered[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(20),
                    child: Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : '?'),
                  ),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(p.phoneNumber ?? 'No phone'),
                  onTap: () => setState(() => _selectedParty = p),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildLedgerContent() {
    final partyId = _selectedParty!.id;
    final invoiceQuery = InvoiceQuery(invoiceType: widget.partyType == 'customer' ? 'sales' : 'purchase', partyId: partyId);
    final invoicesAsync = ref.watch(invoicesProvider(invoiceQuery));
    
    final paymentType = widget.partyType == 'customer' ? 'receipt' : 'payment';
    final paymentQuery = PaymentQuery(paymentType: paymentType, partyId: partyId);
    final paymentsAsync = ref.watch(paymentsProvider(paymentQuery));

    return Consumer(builder: (context, ref, child) {
      final invoices = invoicesAsync.value ?? [];
      final payments = paymentsAsync.value ?? [];

      if (invoicesAsync.isLoading || paymentsAsync.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      // Combine into entries
      final List<_LedgerEntry> entries = [];
      for (var inv in invoices) {
        entries.add(_LedgerEntry(
          date: inv.invoiceDate,
          description: '${inv.docType} #${inv.invoiceNumber}',
          amount: inv.totalAmount,
          isDebit: widget.partyType == 'customer', // Customer Invoice = Debit (They owe us)
          id: inv.id,
        ));
      }
      for (var p in payments) {
        final method = (p.paymentMethod).toUpperCase();
        entries.add(_LedgerEntry(
          date: p.paymentDate,
          description: 'Payment ($method) ${p.referenceNumber ?? ""}',
          amount: p.totalAmount,
          isDebit: widget.partyType != 'customer', // Customer Payment = Credit (They paid us)
          id: p.id,
        ));
      }

      // Sort chronological
      entries.sort((a, b) => a.date.compareTo(b.date));

      double runningBalance = 0;
      final List<_LedgerRow> rows = entries.map((e) {
        if (e.isDebit) {
          runningBalance += e.amount;
        } else {
          runningBalance -= e.amount;
        }
        return _LedgerRow(entry: e, balance: runningBalance);
      }).toList();

      if (rows.isEmpty) {
        return const Center(child: Text('No transactions for this party.'));
      }

      return Column(
        children: [
          _buildBalanceCard(runningBalance),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: rows.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final row = rows[index];
                final e = row.entry;
                return ListTile(
                  dense: true,
                  title: Row(
                    children: [
                      Text(DateFormat('dd/MM/yy').format(e.date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(e.description, style: const TextStyle(fontWeight: FontWeight.w500))),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            if (e.isDebit)
                              Text('DR: ${currencyFormat.format(e.amount)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                            else
                              Text('CR: ${currencyFormat.format(e.amount)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Text('BAL: ${currencyFormat.format(row.balance)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildBalanceCard(double balance) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Theme.of(context).colorScheme.primaryContainer.withAlpha(30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Closing Balance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(
            currencyFormat.format(balance),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: balance > 0 ? Colors.red : (balance < 0 ? Colors.green : Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerEntry {
  final DateTime date;
  final String description;
  final double amount;
  final bool isDebit;
  final String id;

  _LedgerEntry({required this.date, required this.description, required this.amount, required this.isDebit, required this.id});
}

class _LedgerRow {
  final _LedgerEntry entry;
  final double balance;
  _LedgerRow({required this.entry, required this.balance});
}
