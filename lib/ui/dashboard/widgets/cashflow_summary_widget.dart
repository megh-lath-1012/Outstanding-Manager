import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../services/cashflow_service.dart';

class CashflowSummaryWidget extends ConsumerWidget {
  const CashflowSummaryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecastAsync = ref.watch(cashflowForecastProvider);
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return forecastAsync.when(
      data: (forecast) => _buildSummary(context, forecast, currencyFormat),
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, s) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(height: 8),
              Text('Forecast Error: $e', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummary(
    BuildContext context,
    CashflowForecast forecast,
    NumberFormat fmt,
  ) {
    final theme = themeOf(context);
    final isHealthy = forecast.coveragePercent >= 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Smart Forecasting',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Net Position (30 Days)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fmt.format(
                            forecast.totalUpcomingReceivables -
                                forecast.totalUpcomingPayables,
                          ),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isHealthy ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    _buildCoverageBadge(forecast.coveragePercent),
                  ],
                ),
                const Divider(height: 32),
                _buildInsightRow(
                  context,
                  Icons.arrow_downward,
                  'Expected Receipts',
                  fmt.format(forecast.totalUpcomingReceivables),
                  Colors.green,
                ),
                const SizedBox(height: 12),
                _buildInsightRow(
                  context,
                  Icons.arrow_upward,
                  'Upcoming Payables',
                  fmt.format(forecast.totalUpcomingPayables),
                  Colors.red,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          forecast.summaryMessage,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.blue.shade800,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (forecast.highRiskParties.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildRiskSection(context, forecast.highRiskParties),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoverageBadge(int percent) {
    Color color = Colors.green;
    if (percent < 50) {
      color = Colors.red;
    } else if (percent < 100) {
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$percent% Covered',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildInsightRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Text(
          label,
          style: themeOf(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
        ),
        const Spacer(),
        Text(
          value,
          style: themeOf(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildRiskSection(BuildContext context, List<HighRiskParty> risks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'High Risk Payers',
              style: themeOf(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...risks.map(
          (risk) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• ${risk.partyName}: ${risk.reason}',
              style: themeOf(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
          ),
        ),
      ],
    );
  }

  ThemeData themeOf(BuildContext context) => Theme.of(context);
}
