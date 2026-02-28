import { useNavigate } from 'react-router';
import { useAuth } from '../contexts/AuthContext';
import { useTheme } from '../contexts/ThemeContext';
import { Button } from './ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { 
  Moon, 
  Sun, 
  Bell, 
  Shield, 
  HelpCircle, 
  FileText, 
  LogOut, 
  ChevronRight,
  Trash2,
  Download
} from 'lucide-react';
import { toast } from 'sonner';
import BottomNav from './BottomNav';
import { Link } from 'react-router';

export default function Settings() {
  const { logout, user } = useAuth();
  const { theme, toggleTheme } = useTheme();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    toast.success('Logged out successfully');
    navigate('/login');
  };

  const handleClearData = () => {
    if (window.confirm('Are you sure you want to clear all data? This action cannot be undone.')) {
      // Keep user data, clear business data
      localStorage.removeItem('salesInvoices');
      localStorage.removeItem('purchaseInvoices');
      localStorage.removeItem('salesPayments');
      localStorage.removeItem('purchasePayments');
      localStorage.removeItem('partyNames');
      toast.success('All business data cleared');
    }
  };

  const handleExportData = () => {
    const data = {
      salesInvoices: JSON.parse(localStorage.getItem('salesInvoices') || '[]'),
      purchaseInvoices: JSON.parse(localStorage.getItem('purchaseInvoices') || '[]'),
      salesPayments: JSON.parse(localStorage.getItem('salesPayments') || '[]'),
      purchasePayments: JSON.parse(localStorage.getItem('purchasePayments') || '[]'),
      exportedAt: new Date().toISOString(),
    };

    const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `outstanding_manager_backup_${new Date().toISOString().split('T')[0]}.json`;
    a.click();
    URL.revokeObjectURL(url);
    toast.success('Data exported successfully');
  };

  return (
    <div className="min-h-screen bg-background pb-24">
      {/* Header */}
      <header className="bg-card border-b sticky top-0 z-10">
        <div className="container mx-auto px-4 py-4">
          <h1 className="text-2xl font-bold">Settings</h1>
          <p className="text-sm text-muted-foreground">Manage your account and preferences</p>
        </div>
      </header>

      <main className="container mx-auto px-4 py-6 space-y-6">
        {/* Appearance */}
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Appearance</CardTitle>
            <CardDescription>Customize how the app looks</CardDescription>
          </CardHeader>
          <CardContent>
            <button
              onClick={toggleTheme}
              className="flex items-center justify-between w-full p-4 rounded-lg hover:bg-muted/50 transition-colors"
            >
              <div className="flex items-center gap-3">
                {theme === 'dark' ? (
                  <Moon className="w-5 h-5 text-primary" />
                ) : (
                  <Sun className="w-5 h-5 text-primary" />
                )}
                <div className="text-left">
                  <p className="font-medium">Theme</p>
                  <p className="text-sm text-muted-foreground">
                    {theme === 'dark' ? 'Dark mode' : 'Light mode'}
                  </p>
                </div>
              </div>
              <ChevronRight className="w-5 h-5 text-muted-foreground" />
            </button>
          </CardContent>
        </Card>

        {/* Account */}
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Account</CardTitle>
            <CardDescription>Manage your account settings</CardDescription>
          </CardHeader>
          <CardContent className="space-y-1">
            <Link to="/help">
              <button className="flex items-center justify-between w-full p-4 rounded-lg hover:bg-muted/50 transition-colors">
                <div className="flex items-center gap-3">
                  <HelpCircle className="w-5 h-5 text-primary" />
                  <div className="text-left">
                    <p className="font-medium">Help & Support</p>
                    <p className="text-sm text-muted-foreground">Get help with the app</p>
                  </div>
                </div>
                <ChevronRight className="w-5 h-5 text-muted-foreground" />
              </button>
            </Link>

            <Link to="/privacy">
              <button className="flex items-center justify-between w-full p-4 rounded-lg hover:bg-muted/50 transition-colors">
                <div className="flex items-center gap-3">
                  <Shield className="w-5 h-5 text-primary" />
                  <div className="text-left">
                    <p className="font-medium">Privacy & Security</p>
                    <p className="text-sm text-muted-foreground">Manage your privacy</p>
                  </div>
                </div>
                <ChevronRight className="w-5 h-5 text-muted-foreground" />
              </button>
            </Link>

            <Link to="/terms">
              <button className="flex items-center justify-between w-full p-4 rounded-lg hover:bg-muted/50 transition-colors">
                <div className="flex items-center gap-3">
                  <FileText className="w-5 h-5 text-primary" />
                  <div className="text-left">
                    <p className="font-medium">Terms & Conditions</p>
                    <p className="text-sm text-muted-foreground">Read our terms</p>
                  </div>
                </div>
                <ChevronRight className="w-5 h-5 text-muted-foreground" />
              </button>
            </Link>
          </CardContent>
        </Card>

        {/* Data Management */}
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Data Management</CardTitle>
            <CardDescription>Manage your app data</CardDescription>
          </CardHeader>
          <CardContent className="space-y-3">
            <Button
              onClick={handleExportData}
              variant="outline"
              className="w-full justify-start h-auto p-4"
            >
              <Download className="w-5 h-5 mr-3" />
              <div className="text-left">
                <p className="font-medium">Export Data</p>
                <p className="text-sm text-muted-foreground font-normal">Download all your data</p>
              </div>
            </Button>

            <Button
              onClick={handleClearData}
              variant="outline"
              className="w-full justify-start h-auto p-4 text-destructive border-destructive/30 hover:bg-destructive/10"
            >
              <Trash2 className="w-5 h-5 mr-3" />
              <div className="text-left">
                <p className="font-medium">Clear All Data</p>
                <p className="text-sm text-muted-foreground font-normal">Remove all business data</p>
              </div>
            </Button>
          </CardContent>
        </Card>

        {/* Logout */}
        <Card>
          <CardContent className="pt-6">
            <Button
              onClick={handleLogout}
              variant="destructive"
              className="w-full h-12 gap-2"
            >
              <LogOut className="w-5 h-5" />
              Logout
            </Button>
            
            <p className="text-xs text-center text-muted-foreground mt-4">
              Logged in as {user?.email}
            </p>
          </CardContent>
        </Card>

        {/* App Info */}
        <div className="text-center text-sm text-muted-foreground pb-4">
          <p>Outstanding Manager v1.0.0</p>
          <p className="mt-1">© 2026 All rights reserved</p>
        </div>
      </main>

      <BottomNav />
    </div>
  );
}