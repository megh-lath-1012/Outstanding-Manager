import { Link } from 'react-router';
import { Button } from './ui/button';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { ArrowLeft, FileText } from 'lucide-react';
import BottomNav from './BottomNav';

export default function Terms() {
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
              <h1 className="text-xl font-bold">Terms & Conditions</h1>
            </div>
          </div>
        </div>
      </header>

      <main className="container mx-auto px-4 py-6 space-y-6">
        <div className="text-center py-8">
          <div className="w-16 h-16 rounded-full bg-primary/10 flex items-center justify-center mx-auto mb-4">
            <FileText className="w-8 h-8 text-primary" />
          </div>
          <h2 className="text-2xl font-bold mb-2">Terms of Service</h2>
          <p className="text-muted-foreground">Last updated: January 28, 2026</p>
        </div>

        <Card>
          <CardHeader>
            <CardTitle>1. Acceptance of Terms</CardTitle>
          </CardHeader>
          <CardContent className="text-sm text-muted-foreground">
            <p>
              By accessing and using Outstanding Manager, you accept and agree to be bound
              by the terms and conditions of this agreement.
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>2. Use License</CardTitle>
          </CardHeader>
          <CardContent className="text-sm text-muted-foreground space-y-2">
            <p>
              Permission is granted to use this application for personal and commercial
              business management purposes.
            </p>
            <p>This is the grant of a license, not a transfer of title.</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>3. Disclaimer</CardTitle>
          </CardHeader>
          <CardContent className="text-sm text-muted-foreground">
            <p>
              The application is provided "as is" without warranty of any kind. We do not
              guarantee the accuracy, completeness, or reliability of any content.
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>4. Limitations</CardTitle>
          </CardHeader>
          <CardContent className="text-sm text-muted-foreground">
            <p>
              In no event shall Outstanding Manager or its suppliers be liable for any
              damages arising out of the use or inability to use the application.
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>5. Data Responsibility</CardTitle>
          </CardHeader>
          <CardContent className="text-sm text-muted-foreground">
            <p>
              You are responsible for maintaining backups of your data. We recommend
              regularly exporting your data from the Settings page.
            </p>
          </CardContent>
        </Card>
      </main>

      <BottomNav />
    </div>
  );
}
