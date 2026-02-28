import { Link } from 'react-router';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { TrendingUp, TrendingDown, Plus, History as HistoryIcon } from 'lucide-react';
import { getAllSalesPartiesWithOutstanding, getAllPurchasePartiesWithOutstanding } from '../utils/storage';
import BottomNav from './BottomNav';

export default function Outstanding() {
  const salesParties = getAllSalesPartiesWithOutstanding();
  const purchaseParties = getAllPurchasePartiesWithOutstanding();

  const totalSalesOutstanding = salesParties.reduce((sum, p) => sum + p.totalOutstanding, 0);
  const totalPurchaseOutstanding = purchaseParties.reduce((sum, p) => sum + p.totalOutstanding, 0);

  return (
    <div className="min-h-screen bg-background pb-24">
      {/* Header */}
      <header className="bg-gradient-to-br from-primary via-primary to-accent text-white">
        <div className="container mx-auto px-4 py-6">
          <h1 className="text-2xl font-bold">Outstanding</h1>
          <p className="text-white/80 text-sm mt-1">Manage your receivables and payables</p>
        </div>
      </header>

      <main className="container mx-auto px-4 py-6 space-y-6">
        {/* Summary Cards */}
        <div className="grid grid-cols-2 gap-4">
          <Card className="border-2 border-primary/20">
            <CardContent className="pt-6">
              <div className="flex items-center gap-2 mb-2">
                <div className="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center">
                  <TrendingUp className="w-4 h-4 text-primary" />
                </div>
              </div>
              <p className="text-sm text-muted-foreground">Sales</p>
              <p className="text-2xl font-bold text-primary">
                ₹{totalSalesOutstanding.toLocaleString('en-IN')}
              </p>
              <p className="text-xs text-muted-foreground mt-1">
                {salesParties.length} {salesParties.length === 1 ? 'party' : 'parties'}
              </p>
            </CardContent>
          </Card>

          <Card className="border-2 border-destructive/20">
            <CardContent className="pt-6">
              <div className="flex items-center gap-2 mb-2">
                <div className="w-8 h-8 rounded-full bg-destructive/10 flex items-center justify-center">
                  <TrendingDown className="w-4 h-4 text-destructive" />
                </div>
              </div>
              <p className="text-sm text-muted-foreground">Purchase</p>
              <p className="text-2xl font-bold text-destructive">
                ₹{totalPurchaseOutstanding.toLocaleString('en-IN')}
              </p>
              <p className="text-xs text-muted-foreground mt-1">
                {purchaseParties.length} {purchaseParties.length === 1 ? 'party' : 'parties'}
              </p>
            </CardContent>
          </Card>
        </div>

        {/* Sales Section */}
        <Card>
          <CardHeader className="pb-3">
            <div className="flex items-center justify-between">
              <CardTitle className="text-lg flex items-center gap-2">
                <TrendingUp className="w-5 h-5 text-primary" />
                Sales Outstanding
              </CardTitle>
              <Link to="/add-sales-invoice">
                <Button size="sm" className="gap-2 bg-primary hover:bg-primary/90 h-8">
                  <Plus className="w-4 h-4" />
                  Add
                </Button>
              </Link>
            </div>
          </CardHeader>
          <CardContent className="space-y-2">
            <Link to="/sales-outstanding">
              <Button variant="outline" className="w-full justify-between h-12">
                <span>View All Sales Invoices</span>
                <span className="text-primary font-semibold">{salesParties.length}</span>
              </Button>
            </Link>
            <Link to="/sales-history">
              <Button variant="ghost" className="w-full justify-start h-12 gap-2">
                <HistoryIcon className="w-4 h-4" />
                Sales History (Cleared)
              </Button>
            </Link>
          </CardContent>
        </Card>

        {/* Purchase Section */}
        <Card>
          <CardHeader className="pb-3">
            <div className="flex items-center justify-between">
              <CardTitle className="text-lg flex items-center gap-2">
                <TrendingDown className="w-5 h-5 text-destructive" />
                Purchase Outstanding
              </CardTitle>
              <Link to="/add-purchase-invoice">
                <Button size="sm" className="gap-2 bg-destructive hover:bg-destructive/90 h-8">
                  <Plus className="w-4 h-4" />
                  Add
                </Button>
              </Link>
            </div>
          </CardHeader>
          <CardContent className="space-y-2">
            <Link to="/purchase-outstanding">
              <Button variant="outline" className="w-full justify-between h-12">
                <span>View All Purchase Invoices</span>
                <span className="text-destructive font-semibold">{purchaseParties.length}</span>
              </Button>
            </Link>
            <Link to="/purchase-history">
              <Button variant="ghost" className="w-full justify-start h-12 gap-2">
                <HistoryIcon className="w-4 h-4" />
                Purchase History (Cleared)
              </Button>
            </Link>
          </CardContent>
        </Card>
      </main>

      <BottomNav />
    </div>
  );
}
