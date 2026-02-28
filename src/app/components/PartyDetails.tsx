import { Link, useParams } from "react-router";
import { Button } from "./ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";
import { Badge } from "./ui/badge";
import { ArrowLeft, FileText, Wallet, Calendar } from "lucide-react";
import {
  getSalesInvoicesByParty,
  getPurchaseInvoicesByParty,
  getPaymentsReceivedByParty,
  getPaymentsDoneByParty,
  getPartyOutstandingSummary,
} from "../utils/storage";

export default function PartyDetails() {
  const { type, partyName } = useParams();
  const decodedPartyName = decodeURIComponent(partyName || "");
  const isSales = type === "sales";

  const invoices = isSales
    ? getSalesInvoicesByParty(decodedPartyName)
    : getPurchaseInvoicesByParty(decodedPartyName);

  const payments = isSales
    ? getPaymentsReceivedByParty(decodedPartyName)
    : getPaymentsDoneByParty(decodedPartyName);

  const summary = getPartyOutstandingSummary(decodedPartyName, isSales ? 'sales' : 'purchase');

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-IN', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white border-b">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <Link to={isSales ? "/sales-outstanding" : "/purchase-outstanding"}>
                <Button variant="ghost" size="icon">
                  <ArrowLeft className="w-5 h-5" />
                </Button>
              </Link>
              <div>
                <h1 className="text-2xl font-bold text-gray-900">{decodedPartyName}</h1>
                <p className="text-sm text-gray-600">
                  {isSales ? "Sales Party" : "Purchase Party"}
                </p>
              </div>
            </div>
            <Link
              to={
                isSales
                  ? `/record-payment-received/${encodeURIComponent(decodedPartyName)}`
                  : `/record-payment-done/${encodeURIComponent(decodedPartyName)}`
              }
            >
              <Button className={isSales ? "bg-green-600 hover:bg-green-700" : "bg-red-600 hover:bg-red-700"}>
                <Wallet className="w-4 h-4 mr-2" />
                Record Payment {isSales ? "Received" : "Done"}
              </Button>
            </Link>
          </div>
        </div>
      </header>

      <main className="container mx-auto px-4 py-8">
        {/* Summary Card */}
        <Card className={`mb-8 border-l-4 ${isSales ? 'border-l-green-500 bg-green-50' : 'border-l-red-500 bg-red-50'}`}>
          <CardHeader>
            <CardTitle>Outstanding Summary</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              <div>
                <p className="text-sm text-gray-600">Total Invoiced</p>
                <p className="text-xl font-bold">₹{summary.totalInvoiced.toLocaleString('en-IN')}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Advance</p>
                <p className="text-xl font-bold text-blue-600">₹{summary.totalAdvance.toLocaleString('en-IN')}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Paid</p>
                <p className="text-xl font-bold text-green-600">₹{summary.totalPaid.toLocaleString('en-IN')}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Outstanding</p>
                <p className={`text-2xl font-bold ${isSales ? 'text-green-700' : 'text-red-700'}`}>
                  ₹{summary.totalOutstanding.toLocaleString('en-IN')}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {/* Invoices */}
          <div>
            <h2 className="text-xl font-bold mb-4 flex items-center gap-2">
              <FileText className="w-5 h-5" />
              Invoices ({invoices.length})
            </h2>
            <div className="space-y-4">
              {invoices.length === 0 ? (
                <Card>
                  <CardContent className="text-center py-8 text-gray-500">
                    No invoices yet
                  </CardContent>
                </Card>
              ) : (
                invoices.map((invoice) => (
                  <Card key={invoice.id} className="hover:shadow-md transition-shadow">
                    <CardHeader>
                      <div className="flex justify-between items-start">
                        <div>
                          <CardTitle className="text-lg">{invoice.invoiceNumber}</CardTitle>
                          <p className="text-sm text-gray-600 flex items-center gap-1 mt-1">
                            <Calendar className="w-3 h-3" />
                            {formatDate(invoice.date)}
                          </p>
                        </div>
                        <Badge
                          variant={invoice.outstanding === 0 ? "default" : "secondary"}
                          className={invoice.outstanding === 0 ? "bg-green-600" : ""}
                        >
                          {invoice.outstanding === 0 ? "Paid" : "Pending"}
                        </Badge>
                      </div>
                    </CardHeader>
                    <CardContent className="space-y-3">
                      {/* Items */}
                      {invoice.items.length > 0 && (
                        <div className="space-y-1">
                          <p className="text-xs font-semibold text-gray-700">Items:</p>
                          {invoice.items.map((item) => (
                            <div key={item.id} className="text-sm text-gray-600 ml-2">
                              • {item.name}
                              {item.quantity && ` (Qty: ${item.quantity})`}
                              {item.price && ` - ₹${item.price.toLocaleString('en-IN')}`}
                            </div>
                          ))}
                        </div>
                      )}

                      {/* Amounts */}
                      <div className="space-y-1 text-sm">
                        <div className="flex justify-between">
                          <span className="text-gray-600">Total Amount:</span>
                          <span className="font-semibold">₹{invoice.totalAmount.toLocaleString('en-IN')}</span>
                        </div>
                        {invoice.advance > 0 && (
                          <div className="flex justify-between">
                            <span className="text-gray-600">Advance:</span>
                            <span className="font-semibold text-blue-600">-₹{invoice.advance.toLocaleString('en-IN')}</span>
                          </div>
                        )}
                        {invoice.paidAmount > 0 && (
                          <div className="flex justify-between">
                            <span className="text-gray-600">Paid:</span>
                            <span className="font-semibold text-green-600">-₹{invoice.paidAmount.toLocaleString('en-IN')}</span>
                          </div>
                        )}
                        <div className="flex justify-between pt-2 border-t">
                          <span className="font-semibold">Outstanding:</span>
                          <span className={`font-bold ${invoice.outstanding === 0 ? 'text-green-600' : isSales ? 'text-green-700' : 'text-red-700'}`}>
                            ₹{invoice.outstanding.toLocaleString('en-IN')}
                          </span>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                ))
              )}
            </div>
          </div>

          {/* Payment History */}
          <div>
            <h2 className="text-xl font-bold mb-4 flex items-center gap-2">
              <Wallet className="w-5 h-5" />
              Payment History ({payments.length})
            </h2>
            <div className="space-y-4">
              {payments.length === 0 ? (
                <Card>
                  <CardContent className="text-center py-8 text-gray-500">
                    No payments yet
                  </CardContent>
                </Card>
              ) : (
                payments.map((payment) => (
                  <Card key={payment.id} className="hover:shadow-md transition-shadow">
                    <CardHeader>
                      <div className="flex justify-between items-start">
                        <div>
                          <CardTitle className="text-lg">
                            Payment {isSales ? "Received" : "Done"}
                          </CardTitle>
                          <p className="text-sm text-gray-600 flex items-center gap-1 mt-1">
                            <Calendar className="w-3 h-3" />
                            {formatDate(payment.date)}
                          </p>
                        </div>
                        <div className="text-right">
                          <p className="text-2xl font-bold text-green-600">
                            ₹{payment.totalAmount.toLocaleString('en-IN')}
                          </p>
                        </div>
                      </div>
                    </CardHeader>
                    <CardContent>
                      <div className="space-y-2">
                        <p className="text-sm font-semibold text-gray-700">Applied to invoices:</p>
                        {payment.allocations.map((allocation, idx) => (
                          <div
                            key={idx}
                            className="flex justify-between items-center text-sm p-2 bg-gray-50 rounded"
                          >
                            <span className="text-gray-700">{allocation.invoiceNumber}</span>
                            <span className="font-semibold">₹{allocation.amount.toLocaleString('en-IN')}</span>
                          </div>
                        ))}
                      </div>
                    </CardContent>
                  </Card>
                ))
              )}
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
