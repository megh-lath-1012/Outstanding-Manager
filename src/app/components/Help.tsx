import { useState } from 'react';
import { Link } from 'react-router';
import { Button } from './ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Input } from './ui/input';
import { Textarea } from './ui/textarea';
import { Label } from './ui/label';
import { 
  ArrowLeft, 
  Mail, 
  MessageCircle, 
  Phone, 
  ChevronDown,
  ChevronUp,
  Send
} from 'lucide-react';
import { toast } from 'sonner';
import BottomNav from './BottomNav';

const faqs = [
  {
    question: 'How do I add a new invoice?',
    answer: 'Navigate to the Outstanding tab, select either Sales or Purchase Outstanding, then tap the "+" button at the bottom-right corner. Fill in the invoice details and save.',
  },
  {
    question: 'How do I record a payment?',
    answer: 'Go to the Outstanding screen, tap on a party name to view their invoices, then tap "Record Payment". You can auto-allocate the payment or manually select specific invoices to pay.',
  },
  {
    question: 'Can I edit or delete a payment?',
    answer: 'Yes! Go to the party details page and view their payment history. You can edit or delete any payment from there.',
  },
  {
    question: 'How do I export data to Excel?',
    answer: 'On any outstanding list or history screen, tap the "Export" button in the header. This will download an Excel file with all the data.',
  },
  {
    question: 'What is the profit calculation?',
    answer: 'The profit shown on the dashboard is calculated as: Sales Outstanding - Purchase Outstanding. This shows your net receivable position.',
  },
  {
    question: 'How do I switch between light and dark mode?',
    answer: 'Go to Settings → Appearance and tap on the Theme option to toggle between light and dark modes.',
  },
  {
    question: 'Is my data secure?',
    answer: 'All your data is stored locally on your device. We do not store any data on external servers, ensuring complete privacy.',
  },
  {
    question: 'Can I backup my data?',
    answer: 'Yes! Go to Settings → Data Management and tap "Export Data" to download a JSON backup file of all your data.',
  },
];

export default function Help() {
  const [expandedFaq, setExpandedFaq] = useState<number | null>(null);
  const [contactForm, setContactForm] = useState({
    name: '',
    email: '',
    message: '',
  });

  const toggleFaq = (index: number) => {
    setExpandedFaq(expandedFaq === index ? null : index);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // Simulate sending message
    toast.success('Message sent! We\'ll get back to you soon.');
    setContactForm({ name: '', email: '', message: '' });
  };

  return (
    <div className="min-h-screen bg-background pb-24">
      {/* Header */}
      <header className="bg-card border-b sticky top-0 z-10">
        <div className="container mx-auto px-4 py-3">
          <div className="flex items-center gap-3">
            <Link to="/settings">
              <Button variant="ghost" size="icon">
                <ArrowLeft className="w-5 h-5" />
              </Button>
            </Link>
            <div>
              <h1 className="text-xl font-bold">Help & Support</h1>
              <p className="text-xs text-muted-foreground">Get help with the app</p>
            </div>
          </div>
        </div>
      </header>

      <main className="container mx-auto px-4 py-6 space-y-6">
        {/* Quick Contact */}
        <div className="grid grid-cols-3 gap-3">
          <button className="flex flex-col items-center gap-2 p-4 bg-card border rounded-xl hover:bg-muted/50 transition-colors">
            <div className="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center">
              <Mail className="w-6 h-6 text-primary" />
            </div>
            <span className="text-xs font-medium">Email</span>
          </button>
          
          <button className="flex flex-col items-center gap-2 p-4 bg-card border rounded-xl hover:bg-muted/50 transition-colors">
            <div className="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center">
              <Phone className="w-6 h-6 text-primary" />
            </div>
            <span className="text-xs font-medium">Call</span>
          </button>
          
          <button className="flex flex-col items-center gap-2 p-4 bg-card border rounded-xl hover:bg-muted/50 transition-colors">
            <div className="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center">
              <MessageCircle className="w-6 h-6 text-primary" />
            </div>
            <span className="text-xs font-medium">Chat</span>
          </button>
        </div>

        {/* FAQs */}
        <Card>
          <CardHeader>
            <CardTitle>Frequently Asked Questions</CardTitle>
            <CardDescription>Find answers to common questions</CardDescription>
          </CardHeader>
          <CardContent className="space-y-2">
            {faqs.map((faq, index) => (
              <div key={index} className="border rounded-lg overflow-hidden">
                <button
                  onClick={() => toggleFaq(index)}
                  className="w-full flex items-center justify-between p-4 text-left hover:bg-muted/50 transition-colors"
                >
                  <span className="font-medium pr-4">{faq.question}</span>
                  {expandedFaq === index ? (
                    <ChevronUp className="w-5 h-5 text-muted-foreground flex-shrink-0" />
                  ) : (
                    <ChevronDown className="w-5 h-5 text-muted-foreground flex-shrink-0" />
                  )}
                </button>
                {expandedFaq === index && (
                  <div className="px-4 pb-4 text-sm text-muted-foreground">
                    {faq.answer}
                  </div>
                )}
              </div>
            ))}
          </CardContent>
        </Card>

        {/* Contact Form */}
        <Card>
          <CardHeader>
            <CardTitle>Still need help?</CardTitle>
            <CardDescription>Send us a message and we'll get back to you</CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="name">Name</Label>
                <Input
                  id="name"
                  placeholder="Your name"
                  value={contactForm.name}
                  onChange={(e) => setContactForm({ ...contactForm, name: e.target.value })}
                  required
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="email">Email</Label>
                <Input
                  id="email"
                  type="email"
                  placeholder="your@email.com"
                  value={contactForm.email}
                  onChange={(e) => setContactForm({ ...contactForm, email: e.target.value })}
                  required
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="message">Message</Label>
                <Textarea
                  id="message"
                  placeholder="Describe your issue or question..."
                  rows={4}
                  value={contactForm.message}
                  onChange={(e) => setContactForm({ ...contactForm, message: e.target.value })}
                  required
                />
              </div>

              <Button type="submit" className="w-full gap-2">
                <Send className="w-4 h-4" />
                Send Message
              </Button>
            </form>
          </CardContent>
        </Card>

        {/* Tutorial Videos */}
        <Card>
          <CardHeader>
            <CardTitle>Video Tutorials</CardTitle>
            <CardDescription>Learn how to use the app</CardDescription>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="p-4 border rounded-lg hover:bg-muted/50 cursor-pointer transition-colors">
              <h4 className="font-medium mb-1">Getting Started</h4>
              <p className="text-sm text-muted-foreground">Learn the basics of the app (3:45)</p>
            </div>
            <div className="p-4 border rounded-lg hover:bg-muted/50 cursor-pointer transition-colors">
              <h4 className="font-medium mb-1">Managing Invoices</h4>
              <p className="text-sm text-muted-foreground">How to add and track invoices (5:20)</p>
            </div>
            <div className="p-4 border rounded-lg hover:bg-muted/50 cursor-pointer transition-colors">
              <h4 className="font-medium mb-1">Recording Payments</h4>
              <p className="text-sm text-muted-foreground">Master payment allocation (4:15)</p>
            </div>
          </CardContent>
        </Card>
      </main>

      <BottomNav />
    </div>
  );
}
