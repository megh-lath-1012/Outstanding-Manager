import { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { useAuth } from './AuthContext';
import * as api from '../services/api';
import {
  SalesInvoice,
  PurchaseInvoice,
  PaymentReceived,
  PaymentDone,
  Party,
} from '../utils/types';

interface DataContextType {
  isLoading: boolean;
  syncData: () => Promise<void>;
  addSalesInvoice: (invoice: SalesInvoice) => Promise<void>;
  addPurchaseInvoice: (invoice: PurchaseInvoice) => Promise<void>;
  addPaymentReceived: (payment: PaymentReceived) => Promise<void>;
  addPaymentDone: (payment: PaymentDone) => Promise<void>;
  addParty: (party: Party) => Promise<void>;
}

const DataContext = createContext<DataContextType | undefined>(undefined);

// Storage keys for localStorage cache
const CACHE_KEYS = {
  SALES_INVOICES: "outstandings_sales_invoices",
  PURCHASE_INVOICES: "outstandings_purchase_invoices",
  PAYMENTS_RECEIVED: "outstandings_payments_received",
  PAYMENTS_DONE: "outstandings_payments_done",
  PARTIES: "outstandings_parties",
  LAST_SYNC: "outstandings_last_sync",
};

export function DataProvider({ children }: { children: ReactNode }) {
  const { isAuthenticated, accessToken } = useAuth();
  const [isLoading, setIsLoading] = useState(false);

  // Sync data from Supabase to localStorage cache
  const syncData = async () => {
    if (!isAuthenticated || !accessToken) return;
    
    setIsLoading(true);
    try {
      console.log('Starting data sync from Supabase...');
      
      // TEST: Try the test-auth endpoint to diagnose JWT issue
      try {
        const { projectId } = await import('/utils/supabase/info');
        const testUrl = `https://${projectId}.supabase.co/functions/v1/make-server-0aae0ce7/test-auth`;
        const testResponse = await fetch(testUrl, {
          headers: { 'Authorization': `Bearer ${accessToken}` }
        });
        const testData = await testResponse.json();
        console.log('🔍 JWT TEST RESULT:', testData);
      } catch (testError) {
        console.error('JWT test failed:', testError);
      }
      
      // Fetch all data from API
      const [salesInvoices, purchaseInvoices, paymentsReceived, paymentsDone, parties] = await Promise.all([
        api.getSalesInvoices(accessToken).catch(err => { console.error('Error fetching sales invoices:', err); return []; }),
        api.getPurchaseInvoices(accessToken).catch(err => { console.error('Error fetching purchase invoices:', err); return []; }),
        api.getPaymentsReceived(accessToken).catch(err => { console.error('Error fetching payments received:', err); return []; }),
        api.getPaymentsDone(accessToken).catch(err => { console.error('Error fetching payments done:', err); return []; }),
        api.getParties(accessToken).catch(err => { console.error('Error fetching parties:', err); return []; }),
      ]);

      // Store in localStorage cache for synchronous access
      localStorage.setItem(CACHE_KEYS.SALES_INVOICES, JSON.stringify(salesInvoices));
      localStorage.setItem(CACHE_KEYS.PURCHASE_INVOICES, JSON.stringify(purchaseInvoices));
      localStorage.setItem(CACHE_KEYS.PAYMENTS_RECEIVED, JSON.stringify(paymentsReceived));
      localStorage.setItem(CACHE_KEYS.PAYMENTS_DONE, JSON.stringify(paymentsDone));
      localStorage.setItem(CACHE_KEYS.PARTIES, JSON.stringify(parties));
      localStorage.setItem(CACHE_KEYS.LAST_SYNC, new Date().toISOString());

      console.log('Data synced successfully from Supabase');
    } catch (error) {
      console.error('Error syncing data:', error);
      // Don't throw - the app should continue working with cached data
    } finally {
      setIsLoading(false);
    }
  };

  // Sync data when user logs in
  useEffect(() => {
    if (isAuthenticated && accessToken) {
      syncData();
    }
  }, [isAuthenticated, accessToken]);

  // Add sales invoice (save to API and update cache)
  const addSalesInvoice = async (invoice: SalesInvoice) => {
    if (!accessToken) throw new Error('Not authenticated');
    
    try {
      await api.saveSalesInvoice(invoice, accessToken);
      
      // Update local cache
      const invoices = JSON.parse(localStorage.getItem(CACHE_KEYS.SALES_INVOICES) || '[]');
      invoices.push(invoice);
      localStorage.setItem(CACHE_KEYS.SALES_INVOICES, JSON.stringify(invoices));
      
      // Add party
      await addParty({ name: invoice.partyName, type: 'sales', addedAt: new Date().toISOString() });
    } catch (error) {
      console.error('Error adding sales invoice:', error);
      throw error;
    }
  };

  // Add purchase invoice
  const addPurchaseInvoice = async (invoice: PurchaseInvoice) => {
    if (!accessToken) throw new Error('Not authenticated');
    
    try {
      await api.savePurchaseInvoice(invoice, accessToken);
      
      // Update local cache
      const invoices = JSON.parse(localStorage.getItem(CACHE_KEYS.PURCHASE_INVOICES) || '[]');
      invoices.push(invoice);
      localStorage.setItem(CACHE_KEYS.PURCHASE_INVOICES, JSON.stringify(invoices));
      
      // Add party
      await addParty({ name: invoice.partyName, type: 'purchase', addedAt: new Date().toISOString() });
    } catch (error) {
      console.error('Error adding purchase invoice:', error);
      throw error;
    }
  };

  // Add payment received
  const addPaymentReceived = async (payment: PaymentReceived) => {
    if (!accessToken) throw new Error('Not authenticated');
    
    try {
      await api.savePaymentReceived(payment, accessToken);
      
      // Update local cache
      const payments = JSON.parse(localStorage.getItem(CACHE_KEYS.PAYMENTS_RECEIVED) || '[]');
      payments.push(payment);
      localStorage.setItem(CACHE_KEYS.PAYMENTS_RECEIVED, JSON.stringify(payments));
    } catch (error) {
      console.error('Error adding payment received:', error);
      throw error;
    }
  };

  // Add payment done
  const addPaymentDone = async (payment: PaymentDone) => {
    if (!accessToken) throw new Error('Not authenticated');
    
    try {
      await api.savePaymentDone(payment, accessToken);
      
      // Update local cache
      const payments = JSON.parse(localStorage.getItem(CACHE_KEYS.PAYMENTS_DONE) || '[]');
      payments.push(payment);
      localStorage.setItem(CACHE_KEYS.PAYMENTS_DONE, JSON.stringify(payments));
    } catch (error) {
      console.error('Error adding payment done:', error);
      throw error;
    }
  };

  // Add party
  const addParty = async (party: Party) => {
    if (!accessToken) return;
    
    try {
      // Check if party already exists in cache
      const parties: Party[] = JSON.parse(localStorage.getItem(CACHE_KEYS.PARTIES) || '[]');
      const exists = parties.find(p => p.name.toLowerCase() === party.name.toLowerCase() && p.type === party.type);
      
      if (!exists) {
        await api.saveParty(party, accessToken);
        
        // Update local cache
        parties.push(party);
        localStorage.setItem(CACHE_KEYS.PARTIES, JSON.stringify(parties));
      }
    } catch (error) {
      console.error('Error adding party:', error);
      // Don't throw error for party addition failures
    }
  };

  return (
    <DataContext.Provider
      value={{
        isLoading,
        syncData,
        addSalesInvoice,
        addPurchaseInvoice,
        addPaymentReceived,
        addPaymentDone,
        addParty,
      }}
    >
      {children}
    </DataContext.Provider>
  );
}

export function useData() {
  const context = useContext(DataContext);
  if (context === undefined) {
    throw new Error('useData must be used within a DataProvider');
  }
  return context;
}