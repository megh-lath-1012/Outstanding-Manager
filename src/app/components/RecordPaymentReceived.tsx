import { useState } from "react";
import { Link, useParams, useNavigate } from "react-router";
import { Button } from "./ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";
import { Input } from "./ui/input";
import { Label } from "./ui/label";
import { ArrowLeft, AlertCircle } from "lucide-react";
import { getSalesInvoicesByParty, savePaymentReceived } from "../utils/storage";
import { PaymentReceived, PaymentAllocation } from "../utils/types";
import { toast } from "sonner";
import { Checkbox } from "./ui/checkbox";

export default function RecordPaymentReceived() {
  const { partyName } = useParams();
  const navigate = useNavigate();
  const decodedPartyName = decodeURIComponent(partyName || "");

  const invoices = getSalesInvoicesByParty(decodedPartyName).filter(inv => inv.outstanding > 0);

  const [paymentAmount, setPaymentAmount] = useState("");
  const [date, setDate] = useState(new Date().toISOString().split("T")[0]);
  const [allocations, setAllocations] = useState<Record<string, string>>({});
  const [selectedInvoices, setSelectedInvoices] = useState<Set<string>>(new Set());

  const totalAllocated = Object.values(allocations).reduce(
    (sum, val) => sum + (parseFloat(val) || 0),
    0
  );

  const handleAutoAllocate = () => {
    const amount = parseFloat(paymentAmount);
    if (isNaN(amount) || amount <= 0) {
      toast.error("Please enter a valid payment amount first");
      return;
    }

    let remaining = amount;
    const newAllocations: Record<string, string> = {};
    const newSelected = new Set<string>();

    // Allocate to invoices in order until amount is exhausted
    for (const invoice of invoices) {
      if (remaining <= 0) break;

      const toAllocate = Math.min(remaining, invoice.outstanding);
      newAllocations[invoice.id] = toAllocate.toString();
      newSelected.add(invoice.id);
      remaining -= toAllocate;
    }

    setAllocations(newAllocations);
    setSelectedInvoices(newSelected);
    toast.success("Payment auto-allocated to invoices");
  };

  const handleInvoiceToggle = (invoiceId: string, checked: boolean) => {
    const newSelected = new Set(selectedInvoices);
    if (checked) {
      newSelected.add(invoiceId);
    } else {
      newSelected.delete(invoiceId);
      const newAllocations = { ...allocations };
      delete newAllocations[invoiceId];
      setAllocations(newAllocations);
    }
    setSelectedInvoices(newSelected);
  };

  const handleAllocationChange = (invoiceId: string, value: string) => {
    setAllocations({
      ...allocations,
      [invoiceId]: value,
    });
  };

  const handleQuickFill = (invoiceId: string, invoice: any) => {
    setAllocations({
      ...allocations,
      [invoiceId]: invoice.outstanding.toString(),
    });
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    const amount = parseFloat(paymentAmount);
    if (isNaN(amount) || amount <= 0) {
      toast.error("Please enter a valid payment amount");
      return;
    }

    if (selectedInvoices.size === 0) {
      toast.error("Please select at least one invoice");
      return;
    }

    // Validate allocations
    const paymentAllocations: PaymentAllocation[] = [];
    for (const invoiceId of selectedInvoices) {
      const allocatedAmount = parseFloat(allocations[invoiceId] || "0");
      
      if (allocatedAmount <= 0) {
        toast.error("Please enter valid amounts for all selected invoices");
        return;
      }

      const invoice = invoices.find(inv => inv.id === invoiceId);
      if (!invoice) continue;

      if (allocatedAmount > invoice.outstanding) {
        toast.error(`Amount for invoice ${invoice.invoiceNumber} cannot exceed outstanding ₹${invoice.outstanding.toLocaleString('en-IN')}`);
        return;
      }

      paymentAllocations.push({
        invoiceId: invoice.id,
        invoiceNumber: invoice.invoiceNumber,
        amount: allocatedAmount,
      });
    }

    if (Math.abs(totalAllocated - amount) > 0.01) {
      toast.error(`Total allocated (₹${totalAllocated.toLocaleString('en-IN')}) must equal payment amount (₹${amount.toLocaleString('en-IN')})`);
      return;
    }

    const payment: PaymentReceived = {
      id: Date.now().toString(),
      partyName: decodedPartyName,
      totalAmount: amount,
      date,
      allocations: paymentAllocations,
      createdAt: new Date().toISOString(),
    };

    savePaymentReceived(payment);
    toast.success(`Payment of ₹${amount.toLocaleString('en-IN')} recorded successfully!`);
    navigate(`/party/sales/${encodeURIComponent(decodedPartyName)}`);
  };

  if (invoices.length === 0) {
    return (
      <div className="min-h-screen bg-gray-50">
        <header className="bg-white border-b">
          <div className="container mx-auto px-4 py-4">
            <div className="flex items-center gap-4">
              <Button variant="ghost" size="icon" onClick={() => navigate(-1)}>
                <ArrowLeft className="w-5 h-5" />
              </Button>
              <div>
                <h1 className="text-2xl font-bold text-gray-900">Record Payment Received</h1>
                <p className="text-sm text-gray-600">{decodedPartyName}</p>
              </div>
            </div>
          </div>
        </header>
        <main className="container mx-auto px-4 py-8">
          <Card>
            <CardContent className="text-center py-12">
              <AlertCircle className="w-16 h-16 mx-auto text-gray-400 mb-4" />
              <h3 className="text-xl font-semibold text-gray-700 mb-2">No Outstanding Invoices</h3>
              <p className="text-gray-600 mb-6">All invoices for this party have been fully paid</p>
              <Link to={`/party/sales/${encodeURIComponent(decodedPartyName)}`}>
                <Button>Back to Party Details</Button>
              </Link>
            </CardContent>
          </Card>
        </main>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white border-b">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center gap-4">
            <Button variant="ghost" size="icon" onClick={() => navigate(-1)}>
              <ArrowLeft className="w-5 h-5" />
            </Button>
            <div>
              <h1 className="text-2xl font-bold text-gray-900">Record Payment Received</h1>
              <p className="text-sm text-gray-600">{decodedPartyName}</p>
            </div>
          </div>
        </div>
      </header>

      <main className="container mx-auto px-4 py-8 max-w-4xl">
        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Payment Amount */}
          <Card>
            <CardHeader>
              <CardTitle>Payment Details</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="amount">Payment Amount (₹) *</Label>
                  <Input
                    id="amount"
                    type="number"
                    step="0.01"
                    value={paymentAmount}
                    onChange={(e) => setPaymentAmount(e.target.value)}
                    placeholder="70000"
                    required
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="date">Payment Date *</Label>
                  <Input
                    id="date"
                    type="date"
                    value={date}
                    onChange={(e) => setDate(e.target.value)}
                    required
                  />
                </div>
              </div>

              {paymentAmount && (
                <div className="flex justify-between items-center p-3 bg-green-50 rounded-lg border border-green-200">
                  <span className="text-sm font-semibold">Total to Allocate:</span>
                  <span className="text-lg font-bold text-green-700">
                    ₹{parseFloat(paymentAmount).toLocaleString('en-IN')}
                  </span>
                </div>
              )}

              <Button
                type="button"
                onClick={handleAutoAllocate}
                variant="outline"
                className="w-full"
              >
                Auto-Allocate to Invoices
              </Button>
            </CardContent>
          </Card>

          {/* Invoice Allocation */}
          <Card>
            <CardHeader>
              <div className="flex justify-between items-center">
                <CardTitle>Allocate to Invoices</CardTitle>
                <div className="text-sm">
                  <span className="text-gray-600">Allocated: </span>
                  <span className={`font-bold ${Math.abs(totalAllocated - parseFloat(paymentAmount || "0")) < 0.01 ? 'text-green-600' : 'text-red-600'}`}>
                    ₹{totalAllocated.toLocaleString('en-IN')}
                  </span>
                </div>
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              {invoices.map((invoice) => (
                <div
                  key={invoice.id}
                  className={`p-4 border rounded-lg ${selectedInvoices.has(invoice.id) ? 'border-green-500 bg-green-50' : 'border-gray-200'}`}
                >
                  <div className="flex items-start gap-3">
                    <Checkbox
                      checked={selectedInvoices.has(invoice.id)}
                      onCheckedChange={(checked) => handleInvoiceToggle(invoice.id, checked as boolean)}
                      className="mt-1"
                    />
                    <div className="flex-1 space-y-3">
                      <div>
                        <div className="flex justify-between items-start">
                          <div>
                            <p className="font-semibold text-lg">{invoice.invoiceNumber}</p>
                            <p className="text-sm text-gray-600">
                              Date: {new Date(invoice.date).toLocaleDateString('en-IN')}
                            </p>
                          </div>
                          <div className="text-right">
                            <p className="text-sm text-gray-600">Outstanding</p>
                            <p className="text-xl font-bold text-green-700">
                              ₹{invoice.outstanding.toLocaleString('en-IN')}
                            </p>
                          </div>
                        </div>

                        {invoice.items.length > 0 && (
                          <div className="mt-2 text-sm text-gray-600">
                            Items: {invoice.items.map(item => item.name).join(", ")}
                          </div>
                        )}
                      </div>

                      {selectedInvoices.has(invoice.id) && (
                        <div className="flex gap-2">
                          <div className="flex-1">
                            <Label htmlFor={`allocation-${invoice.id}`} className="text-sm">
                              Amount to Allocate (₹)
                            </Label>
                            <Input
                              id={`allocation-${invoice.id}`}
                              type="number"
                              step="0.01"
                              value={allocations[invoice.id] || ""}
                              onChange={(e) => handleAllocationChange(invoice.id, e.target.value)}
                              placeholder="0.00"
                              max={invoice.outstanding}
                            />
                          </div>
                          <Button
                            type="button"
                            variant="outline"
                            onClick={() => handleQuickFill(invoice.id, invoice)}
                            className="mt-6"
                          >
                            Full Amount
                          </Button>
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </CardContent>
          </Card>

          {/* Summary & Submit */}
          <Card>
            <CardContent className="pt-6">
              <div className="space-y-3 mb-6">
                <div className="flex justify-between text-sm">
                  <span className="text-gray-600">Payment Amount:</span>
                  <span className="font-semibold">₹{parseFloat(paymentAmount || "0").toLocaleString('en-IN')}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-600">Total Allocated:</span>
                  <span className="font-semibold">₹{totalAllocated.toLocaleString('en-IN')}</span>
                </div>
                <div className="flex justify-between text-sm pt-2 border-t">
                  <span className="font-semibold">Remaining:</span>
                  <span className={`font-bold ${Math.abs(totalAllocated - parseFloat(paymentAmount || "0")) < 0.01 ? 'text-green-600' : 'text-red-600'}`}>
                    ₹{Math.max(0, parseFloat(paymentAmount || "0") - totalAllocated).toLocaleString('en-IN')}
                  </span>
                </div>
              </div>

              <div className="flex gap-3">
                <Link to={`/party/sales/${encodeURIComponent(decodedPartyName)}`} className="flex-1">
                  <Button type="button" variant="outline" className="w-full">
                    Cancel
                  </Button>
                </Link>
                <Button type="submit" className="flex-1 bg-green-600 hover:bg-green-700">
                  Record Payment
                </Button>
              </div>
            </CardContent>
          </Card>
        </form>
      </main>
    </div>
  );
}