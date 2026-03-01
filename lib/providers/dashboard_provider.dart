import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_metrics.dart';
import 'invoice_provider.dart';
import 'payment_provider.dart';

/// Dashboard metrics computed from invoices and payments
final dashboardMetricsProvider = Provider<AsyncValue<DashboardMetrics>>((ref) {
  final salesAsync = ref.watch(
    invoicesProvider(InvoiceQuery(invoiceType: 'sales')),
  );
  final purchasesAsync = ref.watch(
    invoicesProvider(InvoiceQuery(invoiceType: 'purchase')),
  );

  return salesAsync.when(
    data: (sales) {
      return purchasesAsync.when(
        data: (purchases) {
          double totalSales = 0, salesOutstanding = 0, salesReceived = 0;
          for (var inv in sales) {
            totalSales += inv.totalAmount;
            salesOutstanding += inv.outstandingAmount;
            salesReceived += inv.paidAmount;
          }

          double totalPurchases = 0, purchaseOutstanding = 0, purchasePaid = 0;
          for (var inv in purchases) {
            totalPurchases += inv.totalAmount;
            purchaseOutstanding += inv.outstandingAmount;
            purchasePaid += inv.paidAmount;
          }

          return AsyncValue.data(
            DashboardMetrics(
              totalSales: totalSales,
              salesOutstanding: salesOutstanding,
              salesReceived: salesReceived,
              totalPurchases: totalPurchases,
              purchaseOutstanding: purchaseOutstanding,
              purchasePaid: purchasePaid,
            ),
          );
        },
        loading: () => const AsyncValue.loading(),
        error: (e, s) => AsyncValue.error(e, s),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});

/// Recent activity (last 10 invoices + payments combined)
final recentActivityProvider = Provider<AsyncValue<List<Map<String, dynamic>>>>(
  (ref) {
    final salesAsync = ref.watch(
      invoicesProvider(InvoiceQuery(invoiceType: 'sales')),
    );
    final purchasesAsync = ref.watch(
      invoicesProvider(InvoiceQuery(invoiceType: 'purchase')),
    );
    final receiptsAsync = ref.watch(
      paymentsProvider(PaymentQuery(paymentType: 'receipt')),
    );
    final paymentsOutAsync = ref.watch(
      paymentsProvider(PaymentQuery(paymentType: 'payment')),
    );

    return salesAsync.when(
      data: (sales) => purchasesAsync.when(
        data: (purchases) => receiptsAsync.when(
          data: (receipts) => paymentsOutAsync.when(
            data: (paymentsOut) {
              final List<Map<String, dynamic>> activities = [];

              for (var inv in sales) {
                activities.add({
                  'type': 'sale',
                  'date': inv.invoiceDate,
                  'data': inv,
                });
              }
              for (var inv in purchases) {
                activities.add({
                  'type': 'purchase',
                  'date': inv.invoiceDate,
                  'data': inv,
                });
              }
              for (var pay in receipts) {
                activities.add({
                  'type': 'receipt',
                  'date': pay.paymentDate,
                  'data': pay,
                });
              }
              for (var pay in paymentsOut) {
                activities.add({
                  'type': 'payment',
                  'date': pay.paymentDate,
                  'data': pay,
                });
              }

              activities.sort(
                (a, b) =>
                    (b['date'] as DateTime).compareTo(a['date'] as DateTime),
              );
              return AsyncValue.data(activities.take(10).toList());
            },
            loading: () => const AsyncValue.loading(),
            error: (e, s) => AsyncValue.error(e, s),
          ),
          loading: () => const AsyncValue.loading(),
          error: (e, s) => AsyncValue.error(e, s),
        ),
        loading: () => const AsyncValue.loading(),
        error: (e, s) => AsyncValue.error(e, s),
      ),
      loading: () => const AsyncValue.loading(),
      error: (e, s) => AsyncValue.error(e, s),
    );
  },
);
