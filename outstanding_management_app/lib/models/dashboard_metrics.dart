class DashboardMetrics {
  final double totalSales;
  final double totalPurchases;
  final double grossProfit;
  final double profitMargin; // percentage
  final double totalReceivables; // from customers
  final double totalPayables; // to suppliers
  final double netOutstanding; // receivables - payables

  DashboardMetrics({
    this.totalSales = 0.0,
    this.totalPurchases = 0.0,
    this.grossProfit = 0.0,
    this.profitMargin = 0.0,
    this.totalReceivables = 0.0,
    this.totalPayables = 0.0,
    this.netOutstanding = 0.0,
  });

  factory DashboardMetrics.empty() {
    return DashboardMetrics();
  }
}
