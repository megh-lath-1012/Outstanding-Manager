import { Link } from "react-router";
import { Button } from "./ui/button";
import { Card, CardContent } from "./ui/card";
import { TrendingUp, Plus, FileText, PieChart } from "lucide-react";
import { getAllSalesPartiesWithOutstanding, getAllPurchasePartiesWithOutstanding } from "../utils/storage";
import BottomNav from "./BottomNav";

export default function Dashboard() {
  const salesParties = getAllSalesPartiesWithOutstanding();
  const purchaseParties = getAllPurchasePartiesWithOutstanding();

  const totalSalesOutstanding = salesParties.reduce((sum, p) => sum + p.totalOutstanding, 0);
  const totalPurchaseOutstanding = purchaseParties.reduce((sum, p) => sum + p.totalOutstanding, 0);
  const overallProfit = totalSalesOutstanding - totalPurchaseOutstanding;

  return (
    <div className="min-h-screen bg-background pb-24">
      {/* Modern Header with Gradient */}
      <header className="bg-gradient-to-br from-primary via-primary to-accent text-white">
        <div className="container mx-auto px-4 py-8">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h1 className="text-3xl font-bold">Welcome Back</h1>
              <p className="text-white/80 text-sm mt-1">Here's your business overview</p>
            </div>
            <Link to="/add-sales-invoice">
              <Button size="icon" className="rounded-full w-12 h-12 bg-white/20 hover:bg-white/30 backdrop-blur-sm">
                <Plus className="w-6 h-6" />
              </Button>
            </Link>
          </div>
          
          {/* Overall Profit Card */}
          <Card className="bg-white/10 backdrop-blur-md border-white/20 text-white">
            <CardContent className="pt-6">
              <div className="flex items-center gap-2 mb-2">
                <div className="w-10 h-10 rounded-full bg-white/20 flex items-center justify-center">
                  <PieChart className="w-5 h-5" />
                </div>
                <div>
                  <p className="text-sm text-white/80">Net Position</p>
                  <p className="text-xs text-white/60">Sales - Purchase</p>
                </div>
              </div>
              <p className={`text-4xl font-bold ${overallProfit >= 0 ? 'text-white' : 'text-red-200'}`}>
                {overallProfit >= 0 ? '+' : ''}₹{Math.abs(overallProfit).toLocaleString('en-IN')}
              </p>
            </CardContent>
          </Card>
        </div>
      </header>

      <main className="container mx-auto px-4 -mt-4">
        {/* Quick Stats */}
        <div className="grid grid-cols-2 gap-4 mb-6">
          <Card className="border-2 border-primary/20 shadow-lg">
            <CardContent className="pt-6">
              <div className="flex items-center gap-2 mb-3">
                <div className="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center">
                  <TrendingUp className="w-4 h-4 text-primary" />
                </div>
                <p className="text-sm font-medium text-muted-foreground">Receivables</p>
              </div>
              <p className="text-2xl font-bold text-primary">₹{totalSalesOutstanding.toLocaleString('en-IN')}</p>
              <p className="text-xs text-muted-foreground mt-1">{salesParties.length} customers</p>
            </CardContent>
          </Card>

          <Card className="border-2 border-destructive/20 shadow-lg">
            <CardContent className="pt-6">
              <div className="flex items-center gap-2 mb-3">
                <div className="w-8 h-8 rounded-full bg-destructive/10 flex items-center justify-center">
                  <TrendingUp className="w-4 h-4 text-destructive rotate-180" />
                </div>
                <p className="text-sm font-medium text-muted-foreground">Payables</p>
              </div>
              <p className="text-2xl font-bold text-destructive">₹{totalPurchaseOutstanding.toLocaleString('en-IN')}</p>
              <p className="text-xs text-muted-foreground mt-1">{purchaseParties.length} suppliers</p>
            </CardContent>
          </Card>
        </div>

        {/* Quick Actions */}
        <div className="mb-6">
          <h2 className="text-lg font-bold mb-4 px-1">Quick Actions</h2>
          <div className="grid grid-cols-2 gap-3">
            <Link to="/add-sales-invoice">
              <Card className="hover:shadow-md transition-shadow cursor-pointer border-2 border-transparent hover:border-primary/20">
                <CardContent className="pt-6 text-center">
                  <div className="w-14 h-14 rounded-2xl bg-primary/10 flex items-center justify-center mx-auto mb-3">
                    <Plus className="w-7 h-7 text-primary" />
                  </div>
                  <p className="font-semibold text-sm">New Sale</p>
                  <p className="text-xs text-muted-foreground mt-1">Add invoice</p>
                </CardContent>
              </Card>
            </Link>

            <Link to="/add-purchase-invoice">
              <Card className="hover:shadow-md transition-shadow cursor-pointer border-2 border-transparent hover:border-destructive/20">
                <CardContent className="pt-6 text-center">
                  <div className="w-14 h-14 rounded-2xl bg-destructive/10 flex items-center justify-center mx-auto mb-3">
                    <Plus className="w-7 h-7 text-destructive" />
                  </div>
                  <p className="font-semibold text-sm">New Purchase</p>
                  <p className="text-xs text-muted-foreground mt-1">Add invoice</p>
                </CardContent>
              </Card>
            </Link>

            <Link to="/sales-outstanding">
              <Card className="hover:shadow-md transition-shadow cursor-pointer">
                <CardContent className="pt-6 text-center">
                  <div className="w-14 h-14 rounded-2xl bg-muted flex items-center justify-center mx-auto mb-3">
                    <FileText className="w-7 h-7 text-primary" />
                  </div>
                  <p className="font-semibold text-sm">Sales</p>
                  <p className="text-xs text-muted-foreground mt-1">Outstanding</p>
                </CardContent>
              </Card>
            </Link>

            <Link to="/purchase-outstanding">
              <Card className="hover:shadow-md transition-shadow cursor-pointer">
                <CardContent className="pt-6 text-center">
                  <div className="w-14 h-14 rounded-2xl bg-muted flex items-center justify-center mx-auto mb-3">
                    <FileText className="w-7 h-7 text-destructive" />
                  </div>
                  <p className="font-semibold text-sm">Purchase</p>
                  <p className="text-xs text-muted-foreground mt-1">Outstanding</p>
                </CardContent>
              </Card>
            </Link>
          </div>
        </div>

        {/* Recent Activity Placeholder */}
        <div className="mb-6">
          <div className="flex items-center justify-between mb-4 px-1">
            <h2 className="text-lg font-bold">Recent Activity</h2>
            <Button variant="ghost" size="sm" className="text-primary">View all</Button>
          </div>
          <Card>
            <CardContent className="py-12 text-center">
              <p className="text-muted-foreground text-sm">No recent activity</p>
              <p className="text-xs text-muted-foreground mt-1">Your transactions will appear here</p>
            </CardContent>
          </Card>
        </div>
      </main>

      <BottomNav />
    </div>
  );
}