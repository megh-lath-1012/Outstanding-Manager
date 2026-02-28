import { Hono } from "npm:hono";
import { cors } from "npm:hono/cors";
import { logger } from "npm:hono/logger";
import { createClient } from "jsr:@supabase/supabase-js@2";
import * as kv from "./kv_store.tsx";

const app = new Hono();

// Log environment check
const supabaseUrl = Deno.env.get('SUPABASE_URL');
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
const anonKey = Deno.env.get('SUPABASE_ANON_KEY');

console.log('Environment check:', {
  hasUrl: !!supabaseUrl,
  hasServiceKey: !!serviceRoleKey,
  hasAnonKey: !!anonKey,
  urlLength: supabaseUrl?.length || 0,
  keyLength: serviceRoleKey?.length || 0,
});

// Create Supabase client for admin operations
const supabaseAdmin = createClient(
  supabaseUrl ?? '',
  serviceRoleKey ?? '',
);

// Create Supabase client for JWT verification (uses anon key)
const supabaseAuth = createClient(
  supabaseUrl ?? '',
  anonKey ?? '',
);

// Enable logger
app.use('*', logger(console.log));

// Enable CORS for all routes and methods
app.use(
  "/*",
  cors({
    origin: "*",
    allowHeaders: ["Content-Type", "Authorization"],
    allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    exposeHeaders: ["Content-Length"],
    maxAge: 600,
  }),
);

// Middleware to verify user authentication
async function verifyUser(authHeader: string | null) {
  console.log('=== VERIFY USER ===');
  console.log('Auth header present:', !!authHeader);
  
  if (!authHeader?.startsWith('Bearer ')) {
    console.log('ERROR: Missing or invalid authorization header');
    const error: any = new Error('Missing or invalid authorization header');
    error.code = 401;
    error.message = 'Missing authorization header';
    throw error;
  }
  
  const token = authHeader.split(' ')[1];
  console.log('Token length:', token?.length);
  console.log('Token preview:', token?.substring(0, 50) + '...');
  
  // Use the service role client to verify the JWT
  // This is the correct way to verify user JWTs on the server
  const { data: { user }, error } = await supabaseAdmin.auth.getUser(token);
  
  console.log('getUser result:', {
    hasUser: !!user,
    userId: user?.id,
    hasError: !!error,
    errorMessage: error?.message,
    errorCode: error?.code,
    errorStatus: error?.status,
    fullError: error ? JSON.stringify(error) : null,
  });
  
  if (error || !user) {
    console.log('ERROR: JWT verification failed');
    console.log('Full error object:', error);
    
    // Return Supabase error details
    const authError: any = new Error(error?.message || 'Unauthorized');
    authError.code = error?.code || 401;
    authError.message = error?.message || 'Invalid JWT';
    throw authError;
  }
  
  console.log('User verified successfully:', user.id);
  return user.id;
}

// Health check endpoint
app.get("/make-server-0aae0ce7/health", (c) => {
  return c.json({ status: "ok" });
});

// Debug endpoint to check environment
app.get("/make-server-0aae0ce7/debug", (c) => {
  return c.json({
    hasUrl: !!supabaseUrl,
    hasServiceKey: !!serviceRoleKey,
    hasAnonKey: !!anonKey,
    urlPreview: supabaseUrl?.substring(0, 30) + '...',
    serviceKeyPreview: serviceRoleKey?.substring(0, 20) + '...',
    anonKeyPreview: anonKey?.substring(0, 20) + '...',
  });
});

// Test endpoint with manual JWT decode (TEMPORARY - for debugging only)
app.get("/make-server-0aae0ce7/test-auth", async (c) => {
  const authHeader = c.req.header('Authorization');
  console.log('Test auth - header present:', !!authHeader);
  
  if (!authHeader) {
    return c.json({ error: 'No auth header' }, 401);
  }
  
  const token = authHeader.split(' ')[1];
  console.log('Token length:', token?.length);
  
  // Try both clients
  const adminResult = await supabaseAdmin.auth.getUser(token);
  const authResult = await supabaseAuth.auth.getUser(token);
  
  return c.json({
    adminClient: {
      hasUser: !!adminResult.data.user,
      userId: adminResult.data.user?.id,
      hasError: !!adminResult.error,
      error: adminResult.error,
    },
    authClient: {
      hasUser: !!authResult.data.user,
      userId: authResult.data.user?.id,
      hasError: !!authResult.error,
      error: authResult.error,
    },
  });
});

// ========== AUTH ROUTES ==========

// Sign up new user
app.post("/make-server-0aae0ce7/auth/signup", async (c) => {
  try {
    const { name, email, password } = await c.req.json();
    
    console.log('=== SIGNUP REQUEST ===');
    console.log('Creating user with email:', email, 'password length:', password?.length);
    console.log('Has service role key:', !!serviceRoleKey);
    
    if (!email || !password || !name) {
      return c.json({ error: 'Missing required fields: name, email, password' }, 400);
    }
    
    // Check if user already exists
    console.log('Checking for existing users...');
    const { data: existingUsers, error: listError } = await supabaseAdmin.auth.admin.listUsers();
    
    if (listError) {
      console.error('Error listing users:', listError);
      return c.json({ 
        error: `Failed to check existing users: ${listError.message}`,
        code: listError.status,
        message: listError.message,
      }, 500);
    }
    
    const existingUser = existingUsers?.users?.find(u => u.email === email);
    
    if (existingUser) {
      console.log('User already exists:', email, 'confirmed:', existingUser.email_confirmed_at);
      
      // If user exists but email is not confirmed, confirm it
      if (!existingUser.email_confirmed_at) {
        console.log('Confirming existing user email...');
        const { data: updatedUser, error: updateError } = await supabaseAdmin.auth.admin.updateUserById(
          existingUser.id,
          { email_confirm: true }
        );
        
        if (updateError) {
          console.log('Error confirming email:', updateError);
          return c.json({ error: 'User exists but email confirmation failed. Please try logging in.' }, 400);
        }
        
        console.log('Email confirmed for existing user');
        return c.json({ 
          user: {
            id: updatedUser.user.id,
            email: updatedUser.user.email,
            name: updatedUser.user.user_metadata.name || name,
            createdAt: updatedUser.user.created_at,
          }
        });
      }
      
      return c.json({ error: 'User with this email already exists. Please login instead.' }, 400);
    }
    
    // Create new user with email auto-confirmed
    console.log('Creating new user...');
    const { data, error } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      user_metadata: { name },
      email_confirm: true, // Automatically confirm the user's email since an email server hasn't been configured.
    });
    
    if (error) {
      console.error('Signup error from Supabase:', error);
      return c.json({ 
        error: error.message,
        code: error.status,
        message: error.message,
      }, error.status || 400);
    }
    
    console.log('User created successfully:', data.user.id, 'email confirmed:', data.user.email_confirmed_at);
    
    return c.json({ 
      user: {
        id: data.user.id,
        email: data.user.email,
        name: data.user.user_metadata.name,
        createdAt: data.user.created_at,
      }
    });
  } catch (error) {
    console.error('Signup exception:', error);
    return c.json({ error: 'Signup failed: ' + (error as Error).message }, 500);
  }
});

// Sign in user
app.post("/make-server-0aae0ce7/auth/signin", async (c) => {
  try {
    const { email, password } = await c.req.json();
    
    const { data, error } = await supabaseAuth.auth.signInWithPassword({
      email,
      password,
    });
    
    if (error) {
      console.log('Sign in error:', error);
      return c.json({ error: error.message }, 401);
    }
    
    return c.json({ 
      session: data.session,
      user: {
        id: data.user.id,
        email: data.user.email,
        name: data.user.user_metadata?.name,
        phone: data.user.user_metadata?.phone,
        company: data.user.user_metadata?.company,
        avatar: data.user.user_metadata?.avatar,
        createdAt: data.user.created_at,
      }
    });
  } catch (error) {
    console.log('Sign in error:', error);
    return c.json({ error: 'Sign in failed: ' + (error as Error).message }, 500);
  }
});

// Update user profile
app.put("/make-server-0aae0ce7/auth/profile", async (c) => {
  try {
    const userId = await verifyUser(c.req.header('Authorization'));
    const updates = await c.req.json();
    
    const { data, error } = await supabaseAdmin.auth.admin.updateUserById(
      userId,
      { user_metadata: updates }
    );
    
    if (error) {
      console.log('Profile update error:', error);
      return c.json({ error: error.message }, 400);
    }
    
    return c.json({ success: true, user: data.user });
  } catch (error) {
    console.log('Profile update error:', error);
    return c.json({ error: (error as Error).message }, 401);
  }
});

// ========== SALES INVOICE ROUTES ==========

// Get all sales invoices for user
app.get("/make-server-0aae0ce7/sales-invoices", async (c) => {
  try {
    console.log('>>> sales-invoices endpoint called');
    console.log('>>> Authorization header:', c.req.header('Authorization')?.substring(0, 40) + '...');
    
    const userId = await verifyUser(c.req.header('Authorization'));
    
    console.log('>>> User verified, userId:', userId);
    
    const key = `user:${userId}:sales_invoices`;
    const invoices = await kv.get(key) || [];
    
    console.log('>>> Retrieved invoices:', invoices.length);
    
    return c.json(invoices);
  } catch (error) {
    console.error('>>> Get sales invoices error:', error);
    console.error('>>> Error stack:', (error as Error).stack);
    
    // Return the full error details for debugging
    return c.json({ 
      error: (error as Error).message,
      code: 401,
      message: (error as Error).message,
      details: String(error),
      stack: (error as Error).stack,
    }, 401);
  }
});

// Add sales invoice
app.post("/make-server-0aae0ce7/sales-invoices", async (c) => {
  try {
    const userId = await verifyUser(c.req.header('Authorization'));
    const invoice = await c.req.json();
    
    const key = `user:${userId}:sales_invoices`;
    const invoices = await kv.get(key) || [];
    invoices.push(invoice);
    await kv.set(key, invoices);
    
    return c.json({ success: true, invoice });
  } catch (error) {
    console.log('Add sales invoice error:', error);
    return c.json({ error: (error as Error).message }, 401);
  }
});

// ========== PURCHASE INVOICE ROUTES ==========

// Get all purchase invoices for user
app.get("/make-server-0aae0ce7/purchase-invoices", async (c) => {
  try {
    const userId = await verifyUser(c.req.header('Authorization'));
    const key = `user:${userId}:purchase_invoices`;
    const invoices = await kv.get(key) || [];
    return c.json(invoices);
  } catch (error) {
    console.log('Get purchase invoices error:', error);
    return c.json({ error: (error as Error).message }, 401);
  }
});

// Add purchase invoice
app.post("/make-server-0aae0ce7/purchase-invoices", async (c) => {
  try {
    const userId = await verifyUser(c.req.header('Authorization'));
    const invoice = await c.req.json();
    
    const key = `user:${userId}:purchase_invoices`;
    const invoices = await kv.get(key) || [];
    invoices.push(invoice);
    await kv.set(key, invoices);
    
    return c.json({ success: true, invoice });
  } catch (error) {
    console.log('Add purchase invoice error:', error);
    return c.json({ error: (error as Error).message }, 401);
  }
});

// ========== PAYMENT ROUTES ==========

// Get all payments received for user
app.get("/make-server-0aae0ce7/payments-received", async (c) => {
  try {
    const userId = await verifyUser(c.req.header('Authorization'));
    const key = `user:${userId}:payments_received`;
    const payments = await kv.get(key) || [];
    return c.json(payments);
  } catch (error) {
    console.log('Get payments received error:', error);
    return c.json({ error: (error as Error).message }, 401);
  }
});

// Add payment received
app.post("/make-server-0aae0ce7/payments-received", async (c) => {
  try {
    const userId = await verifyUser(c.req.header('Authorization'));
    const payment = await c.req.json();
    
    const key = `user:${userId}:payments_received`;
    const payments = await kv.get(key) || [];
    payments.push(payment);
    await kv.set(key, payments);
    
    return c.json({ success: true, payment });
  } catch (error) {
    console.log('Add payment received error:', error);
    return c.json({ error: (error as Error).message }, 401);
  }
});

// Get all payments done for user
app.get("/make-server-0aae0ce7/payments-done", async (c) => {
  try {
    const userId = await verifyUser(c.req.header('Authorization'));
    const key = `user:${userId}:payments_done`;
    const payments = await kv.get(key) || [];
    return c.json(payments);
  } catch (error) {
    console.log('Get payments done error:', error);
    return c.json({ error: (error as Error).message }, 401);
  }
});

// Add payment done
app.post("/make-server-0aae0ce7/payments-done", async (c) => {
  try {
    const userId = await verifyUser(c.req.header('Authorization'));
    const payment = await c.req.json();
    
    const key = `user:${userId}:payments_done`;
    const payments = await kv.get(key) || [];
    payments.push(payment);
    await kv.set(key, payments);
    
    return c.json({ success: true, payment });
  } catch (error) {
    console.log('Add payment done error:', error);
    return c.json({ error: (error as Error).message }, 401);
  }
});

// ========== PARTY ROUTES ==========

// Get all parties for user
app.get("/make-server-0aae0ce7/parties", async (c) => {
  try {
    const userId = await verifyUser(c.req.header('Authorization'));
    const key = `user:${userId}:parties`;
    const parties = await kv.get(key) || [];
    return c.json(parties);
  } catch (error) {
    console.log('Get parties error:', error);
    return c.json({ error: (error as Error).message }, 401);
  }
});

// Add or update party
app.post("/make-server-0aae0ce7/parties", async (c) => {
  try {
    const userId = await verifyUser(c.req.header('Authorization'));
    const party = await c.req.json();
    
    const key = `user:${userId}:parties`;
    const parties = await kv.get(key) || [];
    
    // Check if party already exists
    const existingIndex = parties.findIndex((p: any) => p.name === party.name && p.type === party.type);
    if (existingIndex === -1) {
      parties.push(party);
    } else {
      parties[existingIndex] = party;
    }
    
    await kv.set(key, parties);
    
    return c.json({ success: true, party });
  } catch (error) {
    console.log('Add party error:', error);
    return c.json({ error: (error as Error).message }, 401);
  }
});

Deno.serve(app.fetch);