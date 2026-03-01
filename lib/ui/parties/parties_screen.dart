import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/party_provider.dart';
import '../../models/party_model.dart';
import 'add_party_screen.dart'; // We'll build next

class PartiesScreen extends ConsumerStatefulWidget {
  const PartiesScreen({super.key});

  @override
  ConsumerState<PartiesScreen> createState() => _PartiesScreenState();
}

class _PartiesScreenState extends ConsumerState<PartiesScreen>
    with SingleTickerProviderStateMixin {
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
        title: const Text('Parties'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(text: 'Customers'),
            Tab(text: 'Suppliers'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement search
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildPartyList('customer'), _buildPartyList('supplier')],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.person_add),
        onPressed: () {
          // Navigate to add party screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddPartyScreen(
                initialType: _tabController.index == 0
                    ? 'customer'
                    : 'supplier',
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPartyList(String partyType) {
    final partiesAsync = ref.watch(partiesProvider(partyType));

    return partiesAsync.when(
      data: (parties) {
        if (parties.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_alt_outlined,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${partyType}s yet',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(partiesProvider(partyType)),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: parties.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final party = parties[index];
              return _buildPartyCard(party);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildPartyCard(Party party) {
    // In a real app we'd fetch actual calculated outstanding from the provider
    // Using openingBalance as a placeholder for UI mockup
    final isNegative = party.openingBalance < 0;
    final color = isNegative ? Colors.red : Colors.green;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddPartyScreen(
                initialType: party.partyType,
                partyToEdit: party,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.1),
                foregroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  party.name.isNotEmpty ? party.name[0].toUpperCase() : '?',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      party.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (party.phoneNumber != null &&
                        party.phoneNumber!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          party.phoneNumber!,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(party.openingBalance.abs()),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    isNegative ? 'To Pay' : 'To Collect',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
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
