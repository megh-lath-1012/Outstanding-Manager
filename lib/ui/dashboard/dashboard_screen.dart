import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/dashboard_metrics.dart';
import '../../models/invoice_model.dart';
import '../../models/payment_model.dart';
import '../../services/cashflow_service.dart';
import 'widgets/cashflow_summary_widget.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final recentAsync = ref.watch(recentActivityProvider);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardMetricsProvider);
          ref.invalidate(recentActivityProvider);
          // ignore: unused_result
          ref.refresh(cashflowForecastProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Metrics cards
              metricsAsync.when(
                data: (metrics) =>
                    _buildMetrics(context, metrics, currencyFormat),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('Error: $e'),
              ),
              const SizedBox(height: 24),

              // Smart Forecasting
              const CashflowSummaryWidget(),
              const SizedBox(height: 24),

              // Recent Activity
              Text(
                'Recent Activity',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              recentAsync.when(
                data: (activities) {
                  if (activities.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      child: Text(
                        'No activity yet',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    );
                  }
                  return Column(
                    children: activities
                        .map(
                          (activity) => _buildActivityTile(
                            context,
                            activity,
                            currencyFormat,
                          ),
                        )
                        .toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('Error: $e'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetrics(
    BuildContext context,
    DashboardMetrics m,
    NumberFormat fmt,
  ) {
    return Column(
      children: [
        // Top row: Net Outstanding
        Card(
          color: m.netOutstanding >= 0
              ? Colors.green.shade50
              : Colors.red.shade50,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  m.netOutstanding >= 0
                      ? Icons.trending_up
                      : Icons.trending_down,
                  color: m.netOutstanding >= 0 ? Colors.green : Colors.red,
                  size: 36,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Net Outstanding',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fmt.format(m.netOutstanding),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: m.netOutstanding >= 0
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                      Text(
                        m.netOutstanding >= 0
                            ? 'You will receive this'
                            : 'You owe this',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Sales vs Purchases row
        Row(
          children: [
            Expanded(
              child: _metricCard(
                context,
                'Sales Outstanding',
                fmt.format(m.salesOutstanding),
                Icons.arrow_downward,
                Colors.green,
                () => context.go('/sales'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                context,
                'Purchase Outstanding',
                fmt.format(m.purchaseOutstanding),
                Icons.arrow_upward,
                Colors.red,
                () => context.go('/purchases'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _metricCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityTile(
    BuildContext context,
    Map<String, dynamic> activity,
    NumberFormat fmt,
  ) {
    final type = activity['type'] as String;
    String title = '';
    String subtitle = '';
    IconData icon = Icons.circle;
    Color color = Colors.grey;

    if (type == 'sale' || type == 'purchase') {
      final inv = activity['data'] as Invoice;
      title = '${type == 'sale' ? 'Sale' : 'Purchase'}: ${inv.partyName}';
      subtitle = '${inv.invoiceNumber} • ${fmt.format(inv.totalAmount)}';
      icon = type == 'sale' ? Icons.trending_up : Icons.trending_down;
      color = type == 'sale' ? Colors.green : Colors.orange;
    } else {
      final pay = activity['data'] as Payment;
      title =
          '${type == 'receipt' ? 'Received from' : 'Paid to'}: ${pay.partyName}';
      subtitle = fmt.format(pay.totalAmount);
      icon = type == 'receipt' ? Icons.download : Icons.upload;
      color = type == 'receipt' ? Colors.green : Colors.red;
    }

    final date = activity['date'] as DateTime;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withAlpha(25),
        foregroundColor: color,
        child: Icon(icon, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      trailing: Text(
        DateFormat('dd MMM').format(date),
        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
      ),
      dense: true,
    );
  }
}
