# Supabase Integration Setup Guide

Your Outstanding Manager app is now configured to work with Supabase for real authentication and cloud data storage! Follow these steps to complete the setup.

## 🚀 Quick Setup (5 minutes)

### Step 1: Create a Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Click "Start your project" and sign in (free account)
3. Click "New Project"
4. Fill in:
   - **Name**: Outstanding Manager (or any name)
   - **Database Password**: Create a strong password (save it!)
   - **Region**: Choose closest to your users
5. Click "Create new project" and wait ~2 minutes

### Step 2: Get Your API Keys

1. In your Supabase project, click **Settings** (gear icon in sidebar)
2. Click **API** in the settings menu
3. You'll see two important values:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public key**: A long string starting with `eyJ...`
4. **Copy these values** - you'll need them next!

### Step 3: Configure Your App

#### Option A: Using Environment Variables (Recommended for Production)

1. Create a `.env` file in your project root:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and add your values:
   ```
   VITE_SUPABASE_URL=https://YOUR-PROJECT-ID.supabase.co
   VITE_SUPABASE_ANON_KEY=your-anon-key-here
   ```

3. Restart your development server

#### Option B: Direct Configuration (Quick Testing)

1. Open `/src/app/config/supabase.ts`
2. Replace the empty strings:
   ```typescript
   export const SUPABASE_URL = 'https://YOUR-PROJECT-ID.supabase.co';
   export const SUPABASE_ANON_KEY = 'your-anon-key-here';
   ```

### Step 4: Test Your App! 

1. **Sign Up**: Create a new account in your app
2. **Log In**: Sign in with your credentials  
3. **Add Data**: Create invoices and payments
4. **Verify**: Check Supabase dashboard > Table Editor > `kv_store_0aae0ce7` to see your data!

---

## ✨ What's Now Connected?

### ✅ Real Authentication
- Secure user signup and login
- Password encryption
- Session management
- Multi-device sync

### ✅ Cloud Database
- All invoices saved to Supabase
- All payments tracked in the cloud
- Party/customer data synced
- Automatic backups

### ✅ User Isolation
- Each user sees only their own data
- Secure API routes with JWT tokens
- Profile management

---

## 🔧 How It Works

### Architecture

```
Frontend (React) 
    ↓
Auth Context (Login/Signup)
    ↓
Supabase Auth (JWT Tokens)
    ↓
Backend API (Hono Server)
    ↓
Supabase Database (KV Store)
```

### Data Flow

1. **Login**: User credentials → Supabase Auth → JWT Access Token
2. **Add Invoice**: Form data → DataContext → API (with token) → Supabase KV Store
3. **View Data**: Component → localStorage cache → API sync → fresh data

### Smart Caching

- Data is cached in localStorage for instant loading
- Auto-syncs from Supabase when you log in
- Updates cache immediately after adding new data
- Works offline (reads from cache)

---

## 📊 Viewing Your Data in Supabase

### Table Editor
1. Go to your Supabase project
2. Click **Table Editor** in sidebar
3. Find table: `kv_store_0aae0ce7`
4. You'll see keys like:
   - `user:abc123:sales_invoices`
   - `user:abc123:purchase_invoices`
   - `user:abc123:payments_received`
   - `user:abc123:payments_done`
   - `user:abc123:parties`

### Authentication
1. Click **Authentication** in sidebar
2. Click **Users** to see all registered users
3. You can manually verify emails, reset passwords, etc.

---

## 🚨 Troubleshooting

### "Failed to fetch" or "Network error"

**Problem**: App can't connect to Supabase

**Solutions**:
- ✅ Check your `.env` file has correct URL and key
- ✅ Restart your dev server after changing `.env`
- ✅ Verify Supabase project is running (check dashboard)
- ✅ Check browser console for CORS errors

### "Unauthorized" or "Invalid token"

**Problem**: Authentication not working

**Solutions**:
- ✅ Log out and log back in
- ✅ Clear browser localStorage
- ✅ Verify SUPABASE_ANON_KEY is correct
- ✅ Check Supabase dashboard > Authentication > Users

### "Signup failed" or "User already exists"

**Problem**: Can't create account

**Solutions**:
- ✅ Use a different email address
- ✅ Check Supabase dashboard > Authentication > Users
- ✅ Make sure email confirmation is disabled (it is by default in code)

### Data not syncing

**Problem**: Added invoice but don't see it after refresh

**Solutions**:
- ✅ Check browser network tab for failed API calls
- ✅ Look for errors in browser console
- ✅ Verify you're logged in (check for access token)
- ✅ Check Supabase logs: Dashboard > Logs > Edge Functions

---

## 🎯 Next Steps

### Optional Enhancements

1. **Email Confirmation**: Enable email verification in Supabase
2. **Password Reset**: Implement forgot password flow
3. **Social Login**: Add Google/GitHub login
4. **Real-time Updates**: Use Supabase Realtime for live sync
5. **Row Level Security**: Add RLS policies for extra security

### Production Deployment

1. **Environment Variables**: Use platform-specific env vars (Vercel, Netlify)
2. **Edge Function**: Deploy Supabase Edge Function from `/supabase/functions/server`
3. **Security**: Enable RLS, rotate keys, add rate limiting

---

## 📖 Additional Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Supabase Auth Guide](https://supabase.com/docs/guides/auth)
- [Edge Functions Guide](https://supabase.com/docs/guides/functions)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)

---

## 🆘 Need Help?

If you encounter issues:

1. Check browser console for errors
2. Check Supabase logs (Dashboard > Logs)
3. Verify your API keys are correct
4. Make sure you're logged in
5. Try clearing browser cache/localStorage

---

## 🎉 Success!

Once you see your data in the Supabase Table Editor, you're all set! Your app now has:

✅ Professional authentication  
✅ Cloud data storage  
✅ Multi-device sync  
✅ Automatic backups  
✅ User isolation  
✅ Production-ready infrastructure  

Happy invoicing! 🧾💰
