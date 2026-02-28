import { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router";
import { ArrowLeft } from "lucide-react";
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
import { getCompanyById, saveTransaction } from "@/app/utils/storage";
import { toast } from "sonner";

export function AddTransaction() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [company, setCompany] = useState<any>(null);
  const [formData, setFormData] = useState({
    type: "sale" as "sale" | "purchase",
    amount: "",
    description: "",
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
  }, [id, navigate]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    if (!formData.amount || parseFloat(formData.amount) <= 0) {
      toast.error("Please enter a valid amount");
      return;
    }

    if (!id) return;

    const newTransaction = {
      id: Date.now().toString(),
      companyId: id,
      type: formData.type,
      amount: parseFloat(formData.amount),
      description: formData.description,
      date: new Date(formData.date).toISOString(),
    };

    saveTransaction(newTransaction);
    toast.success(
      `${formData.type === "sale" ? "Sale" : "Purchase"} added successfully!`
    );
    navigate(`/company/${id}`);
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
            <CardTitle>Add Transaction</CardTitle>
            <CardDescription>
              Record a sale or purchase for {company.name}
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="space-y-6">
              <div className="space-y-2">
                <Label htmlFor="type">Transaction Type *</Label>
                <Select
                  value={formData.type}
                  onValueChange={(value: "sale" | "purchase") =>
                    setFormData({ ...formData, type: value })
                  }
                >
                  <SelectTrigger id="type">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="sale">
                      Sale (They owe you)
                    </SelectItem>
                    <SelectItem value="purchase">
                      Purchase (You owe them)
                    </SelectItem>
                  </SelectContent>
                </Select>
                <p className="text-xs text-gray-500">
                  {formData.type === "sale"
                    ? "This will increase their outstanding to you"
                    : "This will increase your outstanding to them"}
                </p>
              </div>

              <div className="space-y-2">
                <Label htmlFor="amount">Amount (₹) *</Label>
                <Input
                  id="amount"
                  type="number"
                  step="0.01"
                  min="0"
                  value={formData.amount}
                  onChange={(e) =>
                    setFormData({ ...formData, amount: e.target.value })
                  }
                  placeholder="0.00"
                  required
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="date">Date *</Label>
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
                <Label htmlFor="description">Description</Label>
                <Textarea
                  id="description"
                  value={formData.description}
                  onChange={(e) =>
                    setFormData({ ...formData, description: e.target.value })
                  }
                  placeholder="Optional notes about this transaction"
                  rows={3}
                />
              </div>

              <div className="flex gap-3">
                <Button type="submit" className="flex-1">
                  Add Transaction
                </Button>
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => navigate(`/company/${id}`)}
                >
                  Cancel
                </Button>
              </div>
            </form>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
