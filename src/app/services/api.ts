import { API_URL, supabase } from '../config/supabase';
import {
  SalesInvoice,
  PurchaseInvoice,
  PaymentReceived,
  PaymentDone,
  Party,
} from '../utils/types';

// Helper to get auth token from current session
async function getAuthToken(): Promise<string> {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session?.access_token) {
    throw new Error('Not authenticated');
  }
  return session.access_token;
}

// Helper for API calls
async function apiCall<T>(
  endpoint: string,
  method: string = 'GET',
  body?: any,
  accessToken?: string
): Promise<T> {
  const token = accessToken || await getAuthToken();
  
  const options: RequestInit = {
    method,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
    },
  };
  
  if (body) {
    options.body = JSON.stringify(body);
  }
  
  const url = `${API_URL}${endpoint}`;
  console.log(`API Call: ${method} ${url}`);
  
  const response = await fetch(url, options);
  
  console.log(`API Response: ${response.status} ${response.statusText}`);
  
  const data = await response.json();
  
  if (!response.ok) {
    console.error(`API Error for ${endpoint}:`, data);
    throw new Error(data.error || 'API call failed');
  }
  
  return data;
}

// ========== SALES INVOICES ==========

export async function getSalesInvoices(accessToken?: string): Promise<SalesInvoice[]> {
  return apiCall<SalesInvoice[]>('/sales-invoices', 'GET', undefined, accessToken);
}

export async function saveSalesInvoice(invoice: SalesInvoice, accessToken?: string): Promise<void> {
  await apiCall('/sales-invoices', 'POST', invoice, accessToken);
}

// ========== PURCHASE INVOICES ==========

export async function getPurchaseInvoices(accessToken?: string): Promise<PurchaseInvoice[]> {
  return apiCall<PurchaseInvoice[]>('/purchase-invoices', 'GET', undefined, accessToken);
}

export async function savePurchaseInvoice(invoice: PurchaseInvoice, accessToken?: string): Promise<void> {
  await apiCall('/purchase-invoices', 'POST', invoice, accessToken);
}

// ========== PAYMENTS ==========

export async function getPaymentsReceived(accessToken?: string): Promise<PaymentReceived[]> {
  return apiCall<PaymentReceived[]>('/payments-received', 'GET', undefined, accessToken);
}

export async function savePaymentReceived(payment: PaymentReceived, accessToken?: string): Promise<void> {
  await apiCall('/payments-received', 'POST', payment, accessToken);
}

export async function getPaymentsDone(accessToken?: string): Promise<PaymentDone[]> {
  return apiCall<PaymentDone[]>('/payments-done', 'GET', undefined, accessToken);
}

export async function savePaymentDone(payment: PaymentDone, accessToken?: string): Promise<void> {
  await apiCall('/payments-done', 'POST', payment, accessToken);
}

// ========== PARTIES ==========

export async function getParties(accessToken?: string): Promise<Party[]> {
  return apiCall<Party[]>('/parties', 'GET', undefined, accessToken);
}

export async function saveParty(party: Party, accessToken?: string): Promise<void> {
  await apiCall('/parties', 'POST', party, accessToken);
}