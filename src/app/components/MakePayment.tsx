import { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router";
import { ArrowLeft, AlertCircle } from "lucide-react";
import { Button } from "@/app/components/ui/button";
import { Input } from "@/app/components/ui/input";
import { Label } from "@/app/components/ui/label";
import { Textarea } from "@/app/components/ui/textarea";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/app/components/ui/card";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/app/components/ui/select";
import { Alert, AlertDescription } from "@/app/components/ui/alert";
import {
  getCompanyById,
  calculateOutstanding,
  savePayment,
} from "@/app/utils/storage";
import { toast } from "sonner";

export function MakePayment() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [company, setCompany] = useState<any>(null);
  const [outstanding, setOutstanding] = useState({
    salesOutstanding: 0,
    purchaseOutstanding: 0,
  });
  const [formData, setFormData] = useState({
    type: "sale" as "sale" | "purchase",
    amount: "",
    notes: "",
    date: new Date().toISOString().split("T")[0],
  });

  useEffect(() => {
    if (!id) return;
    const companyData = getCompanyById(id);
    if (!companyData) {
      navigate("/");
      return;
    }
    setCompany(companyData);
    setOutstanding(calculateOutstanding(id));
  }, [id, navigate]);

  const currentOutstanding =
    formData.type === "sale"
      ? outstanding.salesOutstanding
      : outstanding.purchaseOutstanding;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    const paymentAmount = parseFloat(formData.amount);

    if (!paymentAmount || paymentAmount <= 0) {
      toast.error("Please enter a valid amount");
      return;
    }

    if (paymentAmount > currentOutstanding) {
      toast.error(
        `Payment amount cannot exceed outstanding amount of ₹${currentOutstanding.toLocaleString()}`
      );
      return;
    }

    if (!id) return;

    const newPayment = {
      id: Date.now().toString(),
      companyId: id,
      type: formData.type,
      amount: paymentAmount,
      notes: formData.notes,
      date: new Date(formData.date).toISOString(),
    };

    savePayment(newPayment);
    
    const isFullPayment = paymentAmount === currentOutstanding;
    toast.success(
      isFullPayment 
        ? `Full payment of ₹${paymentAmount.toLocaleString()} recorded!` 
        : `Part payment of ₹${paymentAmount.toLocaleString()} recorded!`
    );
    navigate(`/company/${id}`);
  };

  const handleFullPayment = () => {
    setFormData({ ...formData, amount: currentOutstanding.toString() });
  };

  if (!company) return null;

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="max-w-2xl mx-auto">
        <Button
          variant="ghost"
          className="mb-6 gap-2"
          onClick={() => navigate(`/company/${id}`)}
        >
          <ArrowLeft className="w-4 h-4" />
          Back to {company.name}
        </Button>

        <Card>
          <CardHeader>
            <CardTitle>Make Payment</CardTitle>
            <CardDescription>
              Record a full or partial payment for {company.name}
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="space-y-6">
              <div className="space-y-2">
                <Label htmlFor="type">Payment For *</Label>
                <Select
                  value={formData.type}
                  onValueChange={(value: "sale" | "purchase") =>
                    setFormData({ ...formData, type: value, amount: "" })
                  }
                >
                  <SelectTrigger id="type">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="sale">
                      Sales Outstanding (They pay you)
                    </SelectItem>
                    <SelectItem value="purchase">
                      Purchase Outstanding (You pay them)
                    </SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <Alert>
                <AlertCircle className="h-4 w-4" />
                <AlertDescription>
                  Current {formData.type === "sale" ? "Sales" : "Purchase"}{" "}
                  Outstanding: <strong>₹{currentOutstanding.toLocaleString()}</strong>
                </AlertDescription>
              </Alert>

              {currentOutstanding === 0 ? (
                <Alert>
                  <AlertDescription>
                    No outstanding balance for{" "}
                    {formData.type === "sale" ? "sales" : "purchases"}. Please
                    select a different payment type or add transactions first.
                  </AlertDescription>
                </Alert>
              ) : (
                <>
                  <div className="space-y-2">
                    <Label htmlFor="amount">Payment Amount (₹) *</Label>
                    <div className="flex gap-2">
                      <Input
                        id="amount"
                        type="number"
                        step="0.01"
                        min="0"
                        max={currentOutstanding}
                        value={formData.amount}
                        onChange={(e) =>
                          setFormData({ ...formData, amount: e.target.value })
                        }
                        placeholder="0.00"
                        required
                      />
                      <Button
                        type="button"
                        variant="outline"
                        onClick={handleFullPayment}
                      >
                        Full Payment
                      </Button>
                    </div>
                    <p className="text-xs text-gray-500">
                      {formData.amount &&
                        parseFloat(formData.amount) > 0 &&
                        parseFloat(formData.amount) < currentOutstanding &&
                        `Part payment: ₹${(
                          currentOutstanding - parseFloat(formData.amount)
                        ).toLocaleString()} will remain outstanding`}
                      {formData.amount &&
                        parseFloat(formData.amount) === currentOutstanding &&
                        "This will clear the full outstanding amount"}
                    </p>
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="date">Payment Date *</Label>
                    <Input
                      id="date"
                      type="date"
                      value={formData.date}
                      onChange={(e) =>
                        setFormData({ ...formData, date: e.target.value })
                      }
                      required
                    />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="notes">Notes</Label>
                    <Textarea
                      id="notes"
                      value={formData.notes}
                      onChange={(e) =>
                        setFormData({ ...formData, notes: e.target.value })
                      }
                      placeholder="Optional notes about this payment"
                      rows={3}
                    />
                  </div>

                  <div className="flex gap-3">
                    <Button type="submit" className="flex-1">
                      Record Payment
                    </Button>
                    <Button
                      type="button"
                      variant="outline"
                      onClick={() => navigate(`/company/${id}`)}
                    >
                      Cancel
                    </Button>
                  </div>
                </>
              )}
            </form>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
