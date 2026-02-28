// New data models for invoice-based system

export interface InvoiceItem {
  id: string;
  name: string;
  quantity?: number;
  price?: number;
}

export interface SalesInvoice {
  id: string;
  invoiceNumber: string;
  partyName: string;
  items: InvoiceItem[];
  totalAmount: number;
  advance: number;
  date: string;
  createdAt: string;
}

export interface PurchaseInvoice {
  id: string;
  invoiceNumber: string;
  partyName: string;
  items: InvoiceItem[];
  totalAmount: number;
  advance: number;
  date: string;
  createdAt: string;
}

export interface PaymentAllocation {
  invoiceId: string;
  invoiceNumber: string;
  amount: number;
}

export interface PaymentReceived {
  id: string;
  partyName: string;
  totalAmount: number;
  date: string;
  allocations: PaymentAllocation[];
  createdAt: string;
}

export interface PaymentDone {
  id: string;
  partyName: string;
  totalAmount: number;
  date: string;
  allocations: PaymentAllocation[];
  createdAt: string;
}

export interface Party {
  name: string;
  type: 'sales' | 'purchase';
  addedAt: string;
}

export interface InvoiceWithOutstanding extends SalesInvoice {
  outstanding: number;
  paidAmount: number;
}

export interface PurchaseInvoiceWithOutstanding extends PurchaseInvoice {
  outstanding: number;
  paidAmount: number;
}
