import { createClient } from '@supabase/supabase-js';
import { projectId, publicAnonKey } from '/utils/supabase/info';

// Supabase configuration - using project credentials
export const SUPABASE_URL = `https://${projectId}.supabase.co`;
export const SUPABASE_ANON_KEY = publicAnonKey;

// Create Supabase client
export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// API endpoint for server calls
export const API_URL = `${SUPABASE_URL}/functions/v1/make-server-0aae0ce7`;