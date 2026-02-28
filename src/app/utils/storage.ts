import {
  SalesInvoice,
  PurchaseInvoice,
  PaymentReceived,
  PaymentDone,
  Party,
  InvoiceWithOutstanding,
  PurchaseInvoiceWithOutstanding,
} from "./types";

const STORAGE_KEYS = {
  SALES_INVOICES: "outstandings_sales_invoices",
  PURCHASE_INVOICES: "outstandings_purchase_invoices",
  PAYMENTS_RECEIVED: "outstandings_payments_received",
  PAYMENTS_DONE: "outstandings_payments_done",
  PARTIES: "outstandings_parties",
};

// ========== SALES INVOICES ==========

export const getSalesInvoices = (): SalesInvoice[] => {
  const data = localStorage.getItem(STORAGE_KEYS.SALES_INVOICES);
  return data ? JSON.parse(data) : [];
};

export const saveSalesInvoice = (invoice: SalesInvoice): void => {
  const invoices = getSalesInvoices();
  invoices.push(invoice);
  localStorage.setItem(STORAGE_KEYS.SALES_INVOICES, JSON.stringify(invoices));
  
  // Add party to records
  saveParty({ name: invoice.partyName, type: 'sales', addedAt: new Date().toISOString() });
};

export const getSalesInvoicesByParty = (partyName: string): InvoiceWithOutstanding[] => {
  const invoices = getSalesInvoices().filter(inv => inv.partyName === partyName);
  return invoices.map(invoice => calculateInvoiceOutstanding(invoice, 'sales'));
};

// ========== PURCHASE INVOICES ==========

export const getPurchaseInvoices = (): PurchaseInvoice[] => {
  const data = localStorage.getItem(STORAGE_KEYS.PURCHASE_INVOICES);
  return data ? JSON.parse(data) : [];
};

export const savePurchaseInvoice = (invoice: PurchaseInvoice): void => {
  const invoices = getPurchaseInvoices();
  invoices.push(invoice);
  localStorage.setItem(STORAGE_KEYS.PURCHASE_INVOICES, JSON.stringify(invoices));
  
  // Add party to records
  saveParty({ name: invoice.partyName, type: 'purchase', addedAt: new Date().toISOString() });
};

export const getPurchaseInvoicesByParty = (partyName: string): PurchaseInvoiceWithOutstanding[] => {
  const invoices = getPurchaseInvoices().filter(inv => inv.partyName === partyName);
  return invoices.map(invoice => calculateInvoiceOutstanding(invoice, 'purchase'));
};

// ========== PAYMENTS RECEIVED ==========

export const getPaymentsReceived = (): PaymentReceived[] => {
  const data = localStorage.getItem(STORAGE_KEYS.PAYMENTS_RECEIVED);
  return data ? JSON.parse(data) : [];
};

export const savePaymentReceived = (payment: PaymentReceived): void => {
  const payments = getPaymentsReceived();
  payments.push(payment);
  localStorage.setItem(STORAGE_KEYS.PAYMENTS_RECEIVED, JSON.stringify(payments));
};

export const updatePaymentReceived = (paymentId: string, updatedPayment: PaymentReceived): void => {
  const payments = getPaymentsReceived();
  const index = payments.findIndex(p => p.id === paymentId);
  if (index !== -1) {
    payments[index] = updatedPayment;
    localStorage.setItem(STORAGE_KEYS.PAYMENTS_RECEIVED, JSON.stringify(payments));
  }
};

export const deletePaymentReceived = (paymentId: string): void => {
  const payments = getPaymentsReceived().filter(p => p.id !== paymentId);
  localStorage.setItem(STORAGE_KEYS.PAYMENTS_RECEIVED, JSON.stringify(payments));
};

export const getPaymentsReceivedByParty = (partyName: string): PaymentReceived[] => {
  return getPaymentsReceived().filter(p => p.partyName === partyName);
};

// ========== PAYMENTS DONE ==========

export const getPaymentsDone = (): PaymentDone[] => {
  const data = localStorage.getItem(STORAGE_KEYS.PAYMENTS_DONE);
  return data ? JSON.parse(data) : [];
};

export const savePaymentDone = (payment: PaymentDone): void => {
  const payments = getPaymentsDone();
  payments.push(payment);
  localStorage.setItem(STORAGE_KEYS.PAYMENTS_DONE, JSON.stringify(payments));
};

export const updatePaymentDone = (paymentId: string, updatedPayment: PaymentDone): void => {
  const payments = getPaymentsDone();
  const index = payments.findIndex(p => p.id === paymentId);
  if (index !== -1) {
    payments[index] = updatedPayment;
    localStorage.setItem(STORAGE_KEYS.PAYMENTS_DONE, JSON.stringify(payments));
  }
};

export const deletePaymentDone = (paymentId: string): void => {
  const payments = getPaymentsDone().filter(p => p.id !== paymentId);
  localStorage.setItem(STORAGE_KEYS.PAYMENTS_DONE, JSON.stringify(payments));
};

export const getPaymentsDoneByParty = (partyName: string): PaymentDone[] => {
  return getPaymentsDone().filter(p => p.partyName === partyName);
};

// ========== PARTIES ==========

export const getParties = (): Party[] => {
  const data = localStorage.getItem(STORAGE_KEYS.PARTIES);
  return data ? JSON.parse(data) : [];
};

export const saveParty = (party: Party): void => {
  const parties = getParties();
  
  // Check if party already exists
  const exists = parties.find(p => p.name.toLowerCase() === party.name.toLowerCase() && p.type === party.type);
  if (!exists) {
    parties.push(party);
    localStorage.setItem(STORAGE_KEYS.PARTIES, JSON.stringify(parties));
  }
};

export const getSalesParties = (): Party[] => {
  return getParties().filter(p => p.type === 'sales');
};

export const getPurchaseParties = (): Party[] => {
  return getParties().filter(p => p.type === 'purchase');
};

// ========== CALCULATIONS ==========

export const calculateInvoiceOutstanding = (
  invoice: SalesInvoice | PurchaseInvoice,
  type: 'sales' | 'purchase'
): InvoiceWithOutstanding | PurchaseInvoiceWithOutstanding => {
  const payments = type === 'sales' ? getPaymentsReceived() : getPaymentsDone();
  
  // Calculate total paid for this invoice
  let paidAmount = 0;
  payments.forEach(payment => {
    const allocation = payment.allocations.find(a => a.invoiceId === invoice.id);
    if (allocation) {
      paidAmount += allocation.amount;
    }
  });
  
  const outstanding = invoice.totalAmount - invoice.advance - paidAmount;
  
  return {
    ...invoice,
    paidAmount,
    outstanding: Math.max(0, outstanding),
  };
};

export const getPartyOutstandingSummary = (partyName: string, type: 'sales' | 'purchase') => {
  const invoices = type === 'sales' 
    ? getSalesInvoicesByParty(partyName)
    : getPurchaseInvoicesByParty(partyName);
  
  const totalInvoiced = invoices.reduce((sum, inv) => sum + inv.totalAmount, 0);
  const totalAdvance = invoices.reduce((sum, inv) => sum + inv.advance, 0);
  const totalPaid = invoices.reduce((sum, inv) => sum + inv.paidAmount, 0);
  const totalOutstanding = invoices.reduce((sum, inv) => sum + inv.outstanding, 0);
  
  return {
    totalInvoiced,
    totalAdvance,
    totalPaid,
    totalOutstanding,
    invoiceCount: invoices.length,
  };
};

// Get all parties with their outstanding summaries
export const getAllSalesPartiesWithOutstanding = () => {
  const salesInvoices = getSalesInvoices();
  const uniqueParties = [...new Set(salesInvoices.map(inv => inv.partyName))];
  
  return uniqueParties.map(partyName => ({
    partyName,
    ...getPartyOutstandingSummary(partyName, 'sales'),
  }));
};

export const getAllPurchasePartiesWithOutstanding = () => {
  const purchaseInvoices = getPurchaseInvoices();
  const uniqueParties = [...new Set(purchaseInvoices.map(inv => inv.partyName))];
  
  return uniqueParties.map(partyName => ({
    partyName,
    ...getPartyOutstandingSummary(partyName, 'purchase'),
  }));
};