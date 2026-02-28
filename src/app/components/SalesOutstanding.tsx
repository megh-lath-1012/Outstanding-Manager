import { useState, useEffect } from "react";
import { Link } from "react-router";
import { Button } from "./ui/button";
import { ArrowLeft, Plus, Download } from "lucide-react";
import { getSalesInvoices, calculateInvoiceOutstanding } from "../utils/storage";
import { toast } from "sonner";
import * as XLSX from 'xlsx';

export default function SalesOutstanding() {
  const [showFab, setShowFab] = useState(true);
  const [lastScrollY, setLastScrollY] = useState(0);

  const allInvoices = getSalesInvoices()
    .map(inv => calculateInvoiceOutstanding(inv, 'sales'))
    .filter(inv => inv.outstanding > 0) // Only show unpaid invoices
    .sort((a, b) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime()); // Oldest first

  useEffect(() => {
    const handleScroll = () => {
      const currentScrollY = window.scrollY;
      if (currentScrollY > lastScrollY && currentScrollY > 100) {
        setShowFab(false);
      } else {
        setShowFab(true);
      }
      setLastScrollY(currentScrollY);
    };

    window.addEventListener('scroll', handleScroll, { passive: true });
    return () => window.removeEventListener('scroll', handleScroll);
  }, [lastScrollY]);

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-IN', {
      year: '2-digit',
      month: 'short',
      day: 'numeric',
    });
  };

  const exportToExcel = () => {
    const data = allInvoices.map((inv, idx) => ({
      'Sr. No.': idx + 1,
      'Invoice No.': inv.invoiceNumber,
      'Party Name': inv.partyName,
      'Date': formatDate(inv.date),
      'Total Amount': inv.totalAmount,
      'Advance': inv.advance,
      'Paid': inv.paidAmount,
      'Outstanding': inv.outstanding,
    }));

    const ws = XLSX.utils.json_to_sheet(data);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, "Sales Outstanding");
    XLSX.writeFile(wb, `Sales_Outstanding_${new Date().toISOString().split('T')[0]}.xlsx`);
    toast.success("Exported to Excel successfully!");
  };

  return (
    <div className="min-h-screen bg-gray-50 pb-24">
      <header className="bg-white border-b sticky top-0 z-10 shadow-sm">
        <div className="container mx-auto px-4 py-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <Link to="/">
                <Button variant="ghost" size="icon">
                  <ArrowLeft className="w-5 h-5" />
                </Button>
              </Link>
              <div>
                <h1 className="text-xl font-bold text-gray-900">Sales Outstanding</h1>
                <p className="text-xs text-gray-600">{allInvoices.length} pending invoices</p>
              </div>
            </div>
            <Button
              onClick={exportToExcel}
              variant="outline"
              size="sm"
              className="gap-2"
            >
              <Download className="w-4 h-4" />
              Export
            </Button>
          </div>
        </div>
      </header>

      <main className="container mx-auto px-4 py-4">
        {allInvoices.length === 0 ? (
          <div className="text-center py-12 bg-white rounded-lg border">
            <p className="text-gray-600 mb-4">No pending sales invoices</p>
            <Link to="/add-sales-invoice">
              <Button className="bg-green-600 hover:bg-green-700">
                <Plus className="w-4 h-4 mr-2" />
                Add Sales Invoice
              </Button>
            </Link>
          </div>
        ) : (
          <div className="bg-white rounded-lg border overflow-hidden">
            <table className="w-full">
              <thead className="bg-gray-50 border-b">
                <tr>
                  <th className="px-3 py-2 text-left text-xs font-semibold text-gray-700">Sr.</th>
                  <th className="px-3 py-2 text-left text-xs font-semibold text-gray-700">Invoice No.</th>
                  <th className="px-3 py-2 text-left text-xs font-semibold text-gray-700">Party Name</th>
                  <th className="px-3 py-2 text-right text-xs font-semibold text-gray-700">Amount</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {allInvoices.map((invoice, idx) => (
                  <tr key={invoice.id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-3 py-2.5 text-sm text-gray-600">{idx + 1}</td>
                    <td className="px-3 py-2.5">
                      <div className="text-sm font-medium text-gray-900">{invoice.invoiceNumber}</div>
                      <div className="text-xs text-gray-500">{formatDate(invoice.date)}</div>
                    </td>
                    <td className="px-3 py-2.5">
                      <Link
                        to={`/party/sales/${encodeURIComponent(invoice.partyName)}`}
                        className="text-sm text-blue-600 hover:underline"
                      >
                        {invoice.partyName}
                      </Link>
                    </td>
                    <td className="px-3 py-2.5 text-right">
                      <div className="text-sm font-semibold text-green-700">
                        ₹{invoice.outstanding.toLocaleString('en-IN')}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </main>

      {/* Floating Action Button */}
      <Link to="/add-sales-invoice">
        <button
          className={`fixed bottom-6 right-6 bg-green-600 hover:bg-green-700 text-white rounded-full shadow-lg transition-all duration-300 flex items-center gap-2 z-50 ${
            showFab ? 'px-6 py-4' : 'px-4 py-4 w-14 h-14'
          }`}
        >
          <Plus className="w-6 h-6" />
          {showFab && <span className="font-semibold whitespace-nowrap">Add Invoice</span>}
        </button>
      </Link>
    </div>
  );
}
