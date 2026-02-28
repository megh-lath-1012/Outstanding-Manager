import { useState, useEffect } from "react";
import { useParams, useNavigate, Link } from "react-router";
import {
  ArrowLeft,
  Plus,
  Receipt,
  Wallet,
  TrendingUp,
  TrendingDown,
} from "lucide-react";
import { Button } from "@/app/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/app/components/ui/card";
import { Badge } from "@/app/components/ui/badge";
import {
  getCompanyById,
  getTransactionsByCompany,
  getPaymentsByCompany,
  calculateOutstanding,
  type Transaction,
  type Payment,
} from "@/app/utils/storage";

export function CompanyDetails() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [company, setCompany] = useState<any>(null);
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [payments, setPayments] = useState<Payment[]>([]);
  const [outstanding, setOutstanding] = useState({
    salesOutstanding: 0,
    purchaseOutstanding: 0,
  });

  useEffect(() => {
    if (!id) return;

    const companyData = getCompanyById(id);
    if (!companyData) {
      navigate("/");
      return;
    }

    setCompany(companyData);
    setTransactions(getTransactionsByCompany(id));
    setPayments(getPaymentsByCompany(id));
    setOutstanding(calculateOutstanding(id));
  }, [id, navigate]);

  if (!company) return null;

  const allActivity = [
    ...transactions.map((t) => ({ ...t, activityType: "transaction" as const })),
    ...payments.map((p) => ({ ...p, activityType: "payment" as const })),
  ].sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="max-w-7xl mx-auto">
        <Button
          variant="ghost"
          className="mb-6 gap-2"
          onClick={() => navigate("/")}
        >
          <ArrowLeft className="w-4 h-4" />
          Back to Dashboard
        </Button>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-1">
            <Card>
              <CardHeader>
                <CardTitle>{company.name}</CardTitle>
                <CardDescription>Company Details</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                {company.email && (
                  <div>
                    <p className="text-sm text-gray-500">Email</p>
                    <p className="font-medium">{company.email}</p>
                  </div>
                )}
                {company.phone && (
                  <div>
                    <p className="text-sm text-gray-500">Phone</p>
                    <p className="font-medium">{company.phone}</p>
                  </div>
                )}
                {company.address && (
                  <div>
                    <p className="text-sm text-gray-500">Address</p>
                    <p className="font-medium">{company.address}</p>
                  </div>
                )}
              </CardContent>
            </Card>

            <Card className="mt-6">
              <CardHeader>
                <CardTitle>Outstanding Summary</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="p-4 bg-green-50 rounded-lg">
                  <div className="flex items-center gap-2 mb-2">
                    <TrendingUp className="w-4 h-4 text-green-600" />
                    <span className="text-sm font-medium text-green-900">
                      Sales Outstanding
                    </span>
                  </div>
                  <p className="text-2xl font-bold text-green-700">
                    ₹{outstanding.salesOutstanding.toLocaleString()}
                  </p>
                  <p className="text-xs text-green-600 mt-1">
                    Amount they owe you
                  </p>
                </div>

                <div className="p-4 bg-red-50 rounded-lg">
                  <div className="flex items-center gap-2 mb-2">
                    <TrendingDown className="w-4 h-4 text-red-600" />
                    <span className="text-sm font-medium text-red-900">
                      Purchase Outstanding
                    </span>
                  </div>
                  <p className="text-2xl font-bold text-red-700">
                    ₹{outstanding.purchaseOutstanding.toLocaleString()}
                  </p>
                  <p className="text-xs text-red-600 mt-1">
                    Amount you owe them
                  </p>
                </div>

                <div className="pt-4 space-y-2">
                  <Link to={`/company/${id}/add-transaction`}>
                    <Button className="w-full gap-2">
                      <Plus className="w-4 h-4" />
                      Add Transaction
                    </Button>
                  </Link>
                  <Link to={`/company/${id}/make-payment`}>
                    <Button variant="outline" className="w-full gap-2">
                      <Wallet className="w-4 h-4" />
                      Make Payment
                    </Button>
                  </Link>
                </div>
              </CardContent>
            </Card>
          </div>

          <div className="lg:col-span-2">
            <Card>
              <CardHeader>
                <CardTitle>Activity History</CardTitle>
                <CardDescription>
                  All transactions and payments
                </CardDescription>
              </CardHeader>
              <CardContent>
                {allActivity.length === 0 ? (
                  <div className="text-center py-12">
                    <Receipt className="w-12 h-12 mx-auto text-gray-400 mb-4" />
                    <p className="text-gray-600">No activity yet</p>
                    <p className="text-sm text-gray-500 mt-2">
                      Add a transaction or payment to get started
                    </p>
                  </div>
                ) : (
                  <div className="space-y-3">
                    {allActivity.map((item) => {
                      const isTransaction = item.activityType === "transaction";
                      const transaction = isTransaction ? (item as Transaction) : null;
                      const payment = !isTransaction ? (item as Payment) : null;

                      return (
                        <div
                          key={item.id}
                          className="flex items-center justify-between p-4 border rounded-lg hover:bg-gray-50 transition-colors"
                        >
                          <div className="flex items-center gap-3">
                            <div
                              className={`w-10 h-10 rounded-full flex items-center justify-center ${
                                isTransaction
                                  ? transaction?.type === "sale"
                                    ? "bg-green-100"
                                    : "bg-red-100"
                                  : "bg-blue-100"
                              }`}
                            >
                              {isTransaction ? (
                                transaction?.type === "sale" ? (
                                  <TrendingUp className="w-5 h-5 text-green-600" />
                                ) : (
                                  <TrendingDown className="w-5 h-5 text-red-600" />
                                )
                              ) : (
                                <Wallet className="w-5 h-5 text-blue-600" />
                              )}
                            </div>
                            <div>
                              <p className="font-medium">
                                {isTransaction ? (
                                  <>
                                    {transaction?.type === "sale"
                                      ? "Sale"
                                      : "Purchase"}
                                    {transaction?.description &&
                                      `: ${transaction.description}`}
                                  </>
                                ) : (
                                  <>
                                    Payment
                                    {payment?.notes && `: ${payment.notes}`}
                                  </>
                                )}
                              </p>
                              <p className="text-sm text-gray-500">
                                {new Date(item.date).toLocaleDateString("en-IN", {
                                  day: "numeric",
                                  month: "short",
                                  year: "numeric",
                                })}
                              </p>
                            </div>
                          </div>
                          <div className="text-right">
                            <p
                              className={`font-bold ${
                                isTransaction
                                  ? transaction?.type === "sale"
                                    ? "text-green-600"
                                    : "text-red-600"
                                  : "text-blue-600"
                              }`}
                            >
                              {isTransaction ? "" : "-"}₹
                              {item.amount.toLocaleString()}
                            </p>
                            {!isTransaction && (
                              <Badge variant="outline" className="text-xs mt-1">
                                {payment?.type === "sale" ? "For Sales" : "For Purchases"}
                              </Badge>
                            )}
                          </div>
                        </div>
                      );
                    })}
                  </div>
                )}
              </CardContent>
            </Card>
          </div>
        </div>
      </div>
    </div>
  );
}
