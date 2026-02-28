import { useState } from "react";
import { Link, useNavigate } from "react-router";
import { Button } from "./ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";
import { Input } from "./ui/input";
import { Label } from "./ui/label";
import { ArrowLeft, Plus, Trash2 } from "lucide-react";
import { getPurchaseParties } from "../utils/storage";
import { useData } from "../contexts/DataContext";
import { PurchaseInvoice, InvoiceItem } from "../utils/types";
import { toast } from "sonner";
import { Command, CommandEmpty, CommandGroup, CommandInput, CommandItem, CommandList } from "./ui/command";
import { Popover, PopoverContent, PopoverTrigger } from "./ui/popover";

export default function AddPurchaseInvoice() {
  const navigate = useNavigate();
  const { addPurchaseInvoice } = useData();
  const [invoiceNumber, setInvoiceNumber] = useState("");
  const [partyName, setPartyName] = useState("");
  const [totalAmount, setTotalAmount] = useState("");
  const [advance, setAdvance] = useState("");
  const [date, setDate] = useState(new Date().toISOString().split("T")[0]);
  const [items, setItems] = useState<InvoiceItem[]>([]);
  const [showPartyDropdown, setShowPartyDropdown] = useState(false);
  
  const [newItemName, setNewItemName] = useState("");
  const [newItemQuantity, setNewItemQuantity] = useState("");
  const [newItemPrice, setNewItemPrice] = useState("");

  const purchaseParties = getPurchaseParties();

  const handleAddItem = () => {
    if (!newItemName.trim()) {
      toast.error("Please enter item name");
      return;
    }

    const item: InvoiceItem = {
      id: Date.now().toString(),
      name: newItemName,
      quantity: newItemQuantity ? parseFloat(newItemQuantity) : undefined,
      price: newItemPrice ? parseFloat(newItemPrice) : undefined,
    };

    setItems([...items, item]);
    setNewItemName("");
    setNewItemQuantity("");
    setNewItemPrice("");
    toast.success("Item added");
  };

  const handleRemoveItem = (itemId: string) => {
    setItems(items.filter((item) => item.id !== itemId));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    if (!invoiceNumber.trim()) {
      toast.error("Please enter invoice number");
      return;
    }

    if (!partyName.trim()) {
      toast.error("Please enter party name");
      return;
    }

    const amount = parseFloat(totalAmount);
    if (isNaN(amount) || amount <= 0) {
      toast.error("Please enter valid total amount");
      return;
    }

    const advanceAmount = advance ? parseFloat(advance) : 0;
    if (isNaN(advanceAmount) || advanceAmount < 0) {
      toast.error("Please enter valid advance amount");
      return;
    }

    if (advanceAmount > amount) {
      toast.error("Advance cannot be greater than total amount");
      return;
    }

    const invoice: PurchaseInvoice = {
      id: Date.now().toString(),
      invoiceNumber: invoiceNumber.trim(),
      partyName: partyName.trim(),
      items,
      totalAmount: amount,
      advance: advanceAmount,
      date,
      createdAt: new Date().toISOString(),
    };

    // Use async function from DataContext
    const saveInvoice = async () => {
      try {
        await addPurchaseInvoice(invoice);
        toast.success(`Purchase invoice ${invoiceNumber} added successfully!`);
        navigate("/purchase-outstanding");
      } catch (error) {
        toast.error("Failed to add invoice. Please try again.");
        console.error("Error saving invoice:", error);
      }
    };
    
    saveInvoice();
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white border-b">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center gap-4">
            <Button variant="ghost" size="icon" onClick={() => navigate(-1)}>
              <ArrowLeft className="w-5 h-5" />
            </Button>
            <div>
              <h1 className="text-2xl font-bold text-gray-900">Add Purchase Invoice</h1>
              <p className="text-sm text-gray-600">Create a new purchase invoice</p>
            </div>
          </div>
        </div>
      </header>

      <main className="container mx-auto px-4 py-8 max-w-3xl">
        <form onSubmit={handleSubmit}>
          <Card>
            <CardHeader>
              <CardTitle>Invoice Details</CardTitle>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="space-y-2">
                <Label htmlFor="invoiceNumber">Invoice Number *</Label>
                <Input
                  id="invoiceNumber"
                  value={invoiceNumber}
                  onChange={(e) => setInvoiceNumber(e.target.value)}
                  placeholder="PUR-001"
                  required
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="partyName">Party Name *</Label>
                <Popover open={showPartyDropdown} onOpenChange={setShowPartyDropdown}>
                  <PopoverTrigger asChild>
                    <Button
                      variant="outline"
                      role="combobox"
                      type="button"
                      className="w-full justify-between"
                    >
                      {partyName || "Select or enter party name..."}
                    </Button>
                  </PopoverTrigger>
                  <PopoverContent className="w-[400px] p-0" align="start">
                    <Command shouldFilter={false}>
                      <CommandInput
                        placeholder="Search or type new party name..."
                        value={partyName}
                        onValueChange={setPartyName}
                      />
                      <CommandList>
                        {purchaseParties.length === 0 && !partyName && (
                          <CommandEmpty>Type to add a new party</CommandEmpty>
                        )}
                        {partyName && !purchaseParties.find(p => p.name.toLowerCase() === partyName.toLowerCase()) && (
                          <CommandGroup heading="New Party">
                            <CommandItem
                              onSelect={() => {
                                setShowPartyDropdown(false);
                              }}
                            >
                              Add "{partyName}" as new party
                            </CommandItem>
                          </CommandGroup>
                        )}
                        {purchaseParties.filter(party => 
                          party.name.toLowerCase().includes(partyName.toLowerCase())
                        ).length > 0 && (
                          <CommandGroup heading="Existing Parties">
                            {purchaseParties
                              .filter(party => 
                                party.name.toLowerCase().includes(partyName.toLowerCase())
                              )
                              .map((party) => (
                                <CommandItem
                                  key={party.name}
                                  value={party.name}
                                  onSelect={(value) => {
                                    setPartyName(value);
                                    setShowPartyDropdown(false);
                                  }}
                                >
                                  {party.name}
                                </CommandItem>
                              ))}
                          </CommandGroup>
                        )}
                      </CommandList>
                    </Command>
                  </PopoverContent>
                </Popover>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="totalAmount">Total Amount (₹) *</Label>
                  <Input
                    id="totalAmount"
                    type="number"
                    step="0.01"
                    value={totalAmount}
                    onChange={(e) => setTotalAmount(e.target.value)}
                    placeholder="50000"
                    required
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="advance">Advance Paid (₹)</Label>
                  <Input
                    id="advance"
                    type="number"
                    step="0.01"
                    value={advance}
                    onChange={(e) => setAdvance(e.target.value)}
                    placeholder="0"
                  />
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="date">Invoice Date *</Label>
                <Input
                  id="date"
                  type="date"
                  value={date}
                  onChange={(e) => setDate(e.target.value)}
                  required
                />
              </div>

              <div className="space-y-4 pt-4 border-t">
                <h3 className="font-semibold text-lg">Items (Optional)</h3>
                
                {items.length > 0 && (
                  <div className="space-y-2">
                    {items.map((item) => (
                      <div
                        key={item.id}
                        className="flex items-center justify-between p-3 bg-gray-50 rounded-lg"
                      >
                        <div>
                          <p className="font-medium">{item.name}</p>
                          {(item.quantity || item.price) && (
                            <p className="text-sm text-gray-600">
                              {item.quantity && `Qty: ${item.quantity}`}
                              {item.quantity && item.price && " • "}
                              {item.price && `Price: ₹${item.price.toLocaleString('en-IN')}`}
                            </p>
                          )}
                        </div>
                        <Button
                          type="button"
                          variant="ghost"
                          size="sm"
                          onClick={() => handleRemoveItem(item.id)}
                        >
                          <Trash2 className="w-4 h-4 text-red-600" />
                        </Button>
                      </div>
                    ))}
                  </div>
                )}

                <div className="space-y-3 p-4 bg-gray-50 rounded-lg">
                  <Label>Add Item</Label>
                  <div className="space-y-2">
                    <Input
                      value={newItemName}
                      onChange={(e) => setNewItemName(e.target.value)}
                      placeholder="Item name (e.g., Raw Material XYZ)"
                    />
                    <div className="grid grid-cols-2 gap-2">
                      <Input
                        type="number"
                        step="0.01"
                        value={newItemQuantity}
                        onChange={(e) => setNewItemQuantity(e.target.value)}
                        placeholder="Quantity (optional)"
                      />
                      <Input
                        type="number"
                        step="0.01"
                        value={newItemPrice}
                        onChange={(e) => setNewItemPrice(e.target.value)}
                        placeholder="Price (optional)"
                      />
                    </div>
                    <Button
                      type="button"
                      variant="outline"
                      className="w-full"
                      onClick={handleAddItem}
                    >
                      <Plus className="w-4 h-4 mr-2" />
                      Add Item
                    </Button>
                  </div>
                </div>
              </div>

              {totalAmount && (
                <div className="p-4 bg-red-50 rounded-lg border border-red-200">
                  <div className="flex justify-between items-center">
                    <span className="font-semibold text-gray-700">Initial Outstanding:</span>
                    <span className="text-xl font-bold text-red-700">
                      ₹{(parseFloat(totalAmount) - (parseFloat(advance) || 0)).toLocaleString('en-IN')}
                    </span>
                  </div>
                  <p className="text-xs text-gray-600 mt-1">
                    Total: ₹{parseFloat(totalAmount).toLocaleString('en-IN')} - Advance: ₹{(parseFloat(advance) || 0).toLocaleString('en-IN')}
                  </p>
                </div>
              )}

              <div className="flex gap-3 pt-4">
                <Link to="/purchase-outstanding" className="flex-1">
                  <Button type="button" variant="outline" className="w-full">
                    Cancel
                  </Button>
                </Link>
                <Button type="submit" className="flex-1 bg-red-600 hover:bg-red-700">
                  Create Purchase Invoice
                </Button>
              </div>
            </CardContent>
          </Card>
        </form>
      </main>
    </div>
  );
}