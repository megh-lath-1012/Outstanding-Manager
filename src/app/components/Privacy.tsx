import { Link } from 'react-router';
import { Button } from './ui/button';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { ArrowLeft, Shield } from 'lucide-react';
import BottomNav from './BottomNav';

export default function Privacy() {
  return (
    <div className="min-h-screen bg-background pb-24">
      <header className="bg-card border-b sticky top-0 z-10">
        <div className="container mx-auto px-4 py-3">
          <div className="flex items-center gap-3">
            <Link to="/settings">
              <Button variant="ghost" size="icon">
                <ArrowLeft className="w-5 h-5" />
              </Button>
            </Link>
            <div>
              <h1 className="text-xl font-bold">Privacy & Security</h1>
            </div>
          </div>
        </div>
      </header>

      <main className="container mx-auto px-4 py-6 space-y-6">
        <div className="text-center py-8">
          <div className="w-16 h-16 rounded-full bg-primary/10 flex items-center justify-center mx-auto mb-4">
            <Shield className="w-8 h-8 text-primary" />
          </div>
          <h2 className="text-2xl font-bold mb-2">Your Privacy Matters</h2>
          <p className="text-muted-foreground">We take your data security seriously</p>
        </div>

        <Card>
          <CardHeader>
            <CardTitle>Local Storage Only</CardTitle>
          </CardHeader>
          <CardContent className="text-sm text-muted-foreground space-y-2">
            <p>
              All your data is stored locally on your device. We do not transmit, store, or
              process any of your information on external servers.
            </p>
            <p>
              This means complete privacy and security - only you have access to your data.
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Data Control</CardTitle>
          </CardHeader>
          <CardContent className="text-sm text-muted-foreground space-y-2">
            <p>
              You have full control over your data. You can export, backup, or delete all
              your information at any time from the Settings page.
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>No Third-Party Access</CardTitle>
          </CardHeader>
          <CardContent className="text-sm text-muted-foreground space-y-2">
            <p>
              We do not share, sell, or provide access to your data to any third parties.
              Your business information remains completely private.
            </p>
          </CardContent>
        </Card>
      </main>

      <BottomNav />
    </div>
  );
}
