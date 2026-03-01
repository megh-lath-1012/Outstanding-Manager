class DashboardMetrics {
  final double totalSales;
  final double salesOutstanding;
  final double salesReceived;
  final double totalPurchases;
  final double purchaseOutstanding;
  final double purchasePaid;

  DashboardMetrics({
    this.totalSales = 0.0,
    this.salesOutstanding = 0.0,
    this.salesReceived = 0.0,
    this.totalPurchases = 0.0,
    this.purchaseOutstanding = 0.0,
    this.purchasePaid = 0.0,
  });

  double get netOutstanding => salesOutstanding - purchaseOutstanding;
  double get grossProfit => totalSales - totalPurchases;

  factory DashboardMetrics.empty() => DashboardMetrics();
}
