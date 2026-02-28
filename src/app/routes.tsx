import { createBrowserRouter } from "react-router";
import Dashboard from "./components/Dashboard";
import SalesOutstanding from "./components/SalesOutstanding";
import PurchaseOutstanding from "./components/PurchaseOutstanding";
import AddSalesInvoice from "./components/AddSalesInvoice";
import AddPurchaseInvoice from "./components/AddPurchaseInvoice";
import RecordPaymentReceived from "./components/RecordPaymentReceived";
import RecordPaymentDone from "./components/RecordPaymentDone";
import PartyDetails from "./components/PartyDetails";
import SalesHistory from "./components/SalesHistory";
import PurchaseHistory from "./components/PurchaseHistory";
import Login from "./components/Login";
import Signup from "./components/Signup";
import Profile from "./components/Profile";
import Settings from "./components/Settings";
import Help from "./components/Help";
import Outstanding from "./components/Outstanding";
import ProtectedRoute from "./components/ProtectedRoute";
import Privacy from "./components/Privacy";
import Terms from "./components/Terms";

export const router = createBrowserRouter([
  {
    path: "/login",
    Component: Login,
  },
  {
    path: "/signup",
    Component: Signup,
  },
  {
    path: "/",
    element: <ProtectedRoute><Dashboard /></ProtectedRoute>,
  },
  {
    path: "/outstanding",
    element: <ProtectedRoute><Outstanding /></ProtectedRoute>,
  },
  {
    path: "/profile",
    element: <ProtectedRoute><Profile /></ProtectedRoute>,
  },
  {
    path: "/settings",
    element: <ProtectedRoute><Settings /></ProtectedRoute>,
  },
  {
    path: "/help",
    element: <ProtectedRoute><Help /></ProtectedRoute>,
  },
  {
    path: "/sales-outstanding",
    element: <ProtectedRoute><SalesOutstanding /></ProtectedRoute>,
  },
  {
    path: "/purchase-outstanding",
    element: <ProtectedRoute><PurchaseOutstanding /></ProtectedRoute>,
  },
  {
    path: "/add-sales-invoice",
    element: <ProtectedRoute><AddSalesInvoice /></ProtectedRoute>,
  },
  {
    path: "/add-purchase-invoice",
    element: <ProtectedRoute><AddPurchaseInvoice /></ProtectedRoute>,
  },
  {
    path: "/record-payment-received/:partyName",
    element: <ProtectedRoute><RecordPaymentReceived /></ProtectedRoute>,
  },
  {
    path: "/record-payment-done/:partyName",
    element: <ProtectedRoute><RecordPaymentDone /></ProtectedRoute>,
  },
  {
    path: "/party/:type/:partyName",
    element: <ProtectedRoute><PartyDetails /></ProtectedRoute>,
  },
  {
    path: "/sales-history",
    element: <ProtectedRoute><SalesHistory /></ProtectedRoute>,
  },
  {
    path: "/purchase-history",
    element: <ProtectedRoute><PurchaseHistory /></ProtectedRoute>,
  },
  {
    path: "/privacy",
    element: <ProtectedRoute><Privacy /></ProtectedRoute>,
  },
  {
    path: "/terms",
    element: <ProtectedRoute><Terms /></ProtectedRoute>,
  },
]);