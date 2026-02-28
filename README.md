# 🧾 Outstanding Manager - Invoice & Payment Tracking App

A modern, production-ready invoice management application for tracking sales and purchase outstandings with real-time payment allocation, built with React, Tailwind CSS, and Supabase.

![Airbnb-style Modern UI](https://img.shields.io/badge/UI-Airbnb%20Style-FF385C)
![Supabase](https://img.shields.io/badge/Backend-Supabase-3ECF8E)
![React](https://img.shields.io/badge/React-18.3.1-61DAFB)
![TypeScript](https://img.shields.io/badge/TypeScript-Ready-3178C6)

---

## ✨ Features

### 💼 Business Management
- **Sales Invoicing**: Create and track sales invoices with customer details
- **Purchase Management**: Record purchase invoices and supplier information
- **Payment Tracking**: Allocate payments across multiple invoices intelligently
- **Outstanding Calculations**: Automatic calculation of receivables and payables
- **Party Management**: Organize customers and suppliers with search

### 🎨 Modern UI/UX
- **Airbnb-Inspired Design**: Coral primary color (#FF385C), modern shadows, gradients
- **Glassmorphic Cards**: Beautiful translucent cards with backdrop blur
- **Bottom Navigation**: Mobile-friendly navigation with active states
- **Dark Mode**: Complete theme toggle with persistent preference
- **Smooth Animations**: Motion transitions throughout the interface
- **Responsive Design**: Works perfectly on mobile, tablet, and desktop

### 🔐 Authentication & Security
- **Supabase Auth**: Professional authentication with JWT tokens
- **Protected Routes**: Secure pages requiring authentication
- **User Profiles**: Editable profiles with avatar support
- **Session Management**: Auto-logout, session persistence
- **User Isolation**: Each user sees only their own data

### ☁️ Cloud Features
- **Real-time Sync**: Data synced across devices via Supabase
- **Automatic Backups**: Cloud storage with Supabase infrastructure
- **Offline Support**: Smart caching for offline access
- **Multi-device**: Access from any device with your account

### 📊 Dashboard & Analytics
- **Net Position**: Calculate overall profit (receivables - payables)
- **Quick Stats**: Total receivables, payables, party counts
- **Recent Activity**: Track latest invoices and payments
- **Party Details**: Detailed view with invoice history and payment records

---

## 🚀 Quick Start

### Prerequisites
- Node.js 18+ or Bun
- A Supabase account (free tier works great!)

### Installation

1. **Clone and Install**
   ```bash
   git clone <your-repo>
   cd outstanding-manager
   npm install  # or: bun install
   ```

2. **Set Up Supabase** (5 minutes)
   
   Follow the detailed guide: [SUPABASE_SETUP.md](./SUPABASE_SETUP.md)
   
   Quick version:
   - Create project at [supabase.com](https://supabase.com)
   - Copy your Project URL and anon key
   - Create `.env` file:
     ```
     VITE_SUPABASE_URL=https://xxxxx.supabase.co
     VITE_SUPABASE_ANON_KEY=your-anon-key
     ```

3. **Run the App**
   ```bash
   npm run dev  # or: bun dev
   ```
   
   Open [http://localhost:5173](http://localhost:5173)

4. **Create an Account**
   - Click "Sign Up"
   - Enter your details
   - Start managing invoices!

---

## 📱 Screenshots

### Dashboard
Modern glassmorphic cards showing net position, receivables, and payables with quick action buttons.

### Invoice Management
Clean forms with autocomplete party selection, item tracking, and real-time outstanding calculations.

### Payment Allocation
Intelligent payment allocation across multiple invoices with auto-distribute feature.

### Profile & Settings
User profile management with avatar upload, theme toggle, and app preferences.

---

## 🏗️ Architecture

```
Frontend (React + Tailwind)
    ├── Contexts
    │   ├── AuthContext (Supabase Auth)
    │   ├── DataContext (API + Cache Management)
    │   └── ThemeContext (Dark Mode)
    │
    ├── Components (15+ UI Components)
    │   ├── Dashboard
    │   ├── Invoice Forms
    │   ├── Payment Recording
    │   ├── Party Details
    │   └── Settings & Profile
    │
    └── Routes (Protected with Auth)

Backend (Supabase Edge Functions - Hono)
    ├── Authentication Routes
    │   ├── POST /auth/signup
    │   ├── POST /auth/signin
    │   └── PUT /auth/profile
    │
    ├── Data Routes (JWT Protected)
    │   ├── Sales Invoices (GET, POST)
    │   ├── Purchase Invoices (GET, POST)
    │   ├── Payments Received (GET, POST)
    │   ├── Payments Done (GET, POST)
    │   └── Parties (GET, POST)
    │
    └── Supabase KV Store (Database)
```

---

## 📂 Project Structure

```
outstanding-manager/
├── src/
│   ├── app/
│   │   ├── components/          # UI Components
│   │   │   ├── Dashboard.tsx
│   │   │   ├── AddSalesInvoice.tsx
│   │   │   ├── RecordPaymentReceived.tsx
│   │   │   ├── Profile.tsx
│   │   │   ├── Settings.tsx
│   │   │   ├── Login.tsx
│   │   │   ├── Signup.tsx
│   │   │   ├── BottomNav.tsx
│   │   │   └── ui/              # Shadcn UI components
│   │   ├── contexts/            # React Contexts
│   │   │   ├── AuthContext.tsx
│   │   │   ├── DataContext.tsx
│   │   │   └── ThemeContext.tsx
│   │   ├── services/            # API Services
│   │   │   └── api.ts
│   │   ├── utils/               # Utilities
│   │   │   ├── storage.ts       # Cache & calculations
│   │   │   └── types.ts         # TypeScript types
│   │   ├── config/              # Configuration
│   │   │   └── supabase.ts
│   │   ├── routes.tsx           # React Router config
│   │   └── App.tsx              # Root component
│   └── styles/                  # Tailwind & themes
│       ├── index.css
│       ├── theme.css
│       └── fonts.css
├── supabase/
│   └── functions/
│       └── server/              # Backend API
│           ├── index.tsx        # Hono server + routes
│           └── kv_store.tsx     # Database utilities
├── .env.example                 # Environment variables template
├── SUPABASE_SETUP.md           # Setup guide
└── README.md                    # This file
```

---

## 🛠️ Tech Stack

### Frontend
- **React 18.3** - UI library
- **TypeScript** - Type safety
- **Tailwind CSS v4** - Styling
- **React Router 7** - Navigation
- **Shadcn UI** - Component library
- **Motion** - Animations
- **Lucide React** - Icons
- **Sonner** - Toast notifications
- **Recharts** - Charts (for future analytics)

### Backend
- **Supabase** - Backend as a Service
- **Supabase Auth** - Authentication
- **Supabase Edge Functions** - Serverless API
- **Hono** - Web framework for Edge Functions
- **KV Store** - Key-value database

### Development
- **Vite** - Build tool
- **ESLint** - Linting
- **PostCSS** - CSS processing

---

## 🎨 Design System

### Colors
- **Primary**: `#FF385C` (Airbnb Coral)
- **Accent**: `#FC642D` (Orange)
- **Success**: `#008A05` (Green)
- **Error**: `#C13515` (Red)
- **Background**: `#FFFFFF` / `#1A1A1A` (Light/Dark)

### Typography
- **Font**: System font stack for native feel
- **Headings**: Bold, modern sizing
- **Body**: 16px base, 1.5 line height

### Components
- **Cards**: Rounded corners, subtle shadows
- **Buttons**: Filled, outline, ghost variants
- **Inputs**: Clean borders, focus states
- **Navigation**: Bottom nav with icons + labels

---

## 📊 Data Model

### Sales Invoice
```typescript
{
  id: string
  invoiceNumber: string
  partyName: string
  items: InvoiceItem[]
  totalAmount: number
  advance: number
  date: string
  createdAt: string
}
```

### Payment Received/Done
```typescript
{
  id: string
  partyName: string
  amount: number
  date: string
  allocations: PaymentAllocation[]
  createdAt: string
}
```

### Payment Allocation
```typescript
{
  invoiceId: string
  invoiceNumber: string
  amount: number
}
```

---

## 🚢 Deployment

### Vercel (Recommended)
1. Push code to GitHub
2. Import project in Vercel
3. Add environment variables in Vercel dashboard
4. Deploy!

### Netlify
1. Build: `npm run build`
2. Publish directory: `dist`
3. Add environment variables
4. Deploy!

### Supabase Edge Function
The backend is already configured as a Supabase Edge Function in `/supabase/functions/server/`. It's automatically deployed with your Supabase project.

---

## 🔒 Security Features

✅ **JWT Authentication** - Secure token-based auth  
✅ **Password Encryption** - Handled by Supabase  
✅ **Protected API Routes** - All data routes require valid token  
✅ **User Isolation** - Data scoped per user  
✅ **CORS Protection** - Configured in backend  
✅ **HTTPS Only** - Enforced by Supabase  
✅ **Session Management** - Auto-refresh tokens  

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

---

## 📄 License

MIT License - feel free to use this project for personal or commercial use.

---

## 🆘 Support

- **Setup Issues**: See [SUPABASE_SETUP.md](./SUPABASE_SETUP.md)
- **Bug Reports**: Open an issue on GitHub
- **Feature Requests**: Open a discussion on GitHub

---

## 🎯 Roadmap

### Planned Features
- [ ] PDF Invoice Generation
- [ ] Excel Export
- [ ] Multi-currency Support
- [ ] SMS/Email Reminders
- [ ] Analytics Dashboard
- [ ] Recurring Invoices
- [ ] Bulk Import
- [ ] Mobile App (React Native)

---

## 🙏 Acknowledgments

- Design inspiration from Airbnb
- UI components from Shadcn UI
- Icons from Lucide
- Backend powered by Supabase

---

## 📞 Contact

For questions or support, please open an issue on GitHub.

---

**Built with ❤️ using React, Tailwind CSS, and Supabase**
