import { useState } from "react";
import { Link } from "react-router";
import { Button } from "./ui/button";
import { ArrowLeft, Download } from "lucide-react";
import { getPurchaseInvoices, calculateInvoiceOutstanding } from "../utils/storage";
import { toast } from "sonner";
import * as XLSX from 'xlsx';

export default function PurchaseHistory() {
  const allInvoices = getPurchaseInvoices()
    .map(inv => calculateInvoiceOutstanding(inv, 'purchase'))
    .filter(inv => inv.outstanding === 0) // Only cleared invoices
    .sort((a, b) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime()); // Oldest first

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
      'Status': 'CLEARED',
    }));

    const ws = XLSX.utils.json_to_sheet(data);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, "Purchase History");
    XLSX.writeFile(wb, `Purchase_History_${new Date().toISOString().split('T')[0]}.xlsx`);
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
                <h1 className="text-xl font-bold text-gray-900">Purchase History</h1>
                <p className="text-xs text-gray-600">{allInvoices.length} cleared invoices</p>
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
            <p className="text-gray-600 mb-4">No cleared purchase invoices</p>
            <Link to="/">
              <Button className="bg-red-600 hover:bg-red-700">
                Go to Dashboard
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
                  <th className="px-3 py-2 text-center text-xs font-semibold text-gray-700">Status</th>
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
                      <div className="text-sm text-gray-900">{invoice.partyName}</div>
                    </td>
                    <td className="px-3 py-2.5 text-right">
                      <div className="text-sm font-semibold text-gray-900">
                        ₹{invoice.totalAmount.toLocaleString('en-IN')}
                      </div>
                    </td>
                    <td className="px-3 py-2.5 text-center">
                      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                        ✓ PAID
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </main>
    </div>
  );
}
