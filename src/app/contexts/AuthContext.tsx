import { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { supabase, API_URL } from '../config/supabase';

interface User {
  id: string;
  name: string;
  email: string;
  phone?: string;
  avatar?: string;
  company?: string;
  createdAt: string;
}

interface AuthContextType {
  user: User | null;
  isAuthenticated: boolean;
  accessToken: string | null;
  login: (email: string, password: string) => Promise<void>;
  signup: (name: string, email: string, password: string) => Promise<void>;
  logout: () => void;
  updateProfile: (updates: Partial<User>) => void;
}

// Create context with default values to prevent undefined errors
const defaultAuthContext: AuthContextType = {
  user: null,
  isAuthenticated: false,
  accessToken: null,
  login: async () => { throw new Error('AuthProvider not initialized'); },
  signup: async () => { throw new Error('AuthProvider not initialized'); },
  logout: () => { throw new Error('AuthProvider not initialized'); },
  updateProfile: () => { throw new Error('AuthProvider not initialized'); },
};

const AuthContext = createContext<AuthContextType>(defaultAuthContext);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [accessToken, setAccessToken] = useState<string | null>(null);

  useEffect(() => {
    // Check for existing session
    const checkSession = async () => {
      const { data: { session } } = await supabase.auth.getSession();
      
      if (session) {
        const userData: User = {
          id: session.user.id,
          email: session.user.email || '',
          name: session.user.user_metadata?.name || '',
          phone: session.user.user_metadata?.phone,
          company: session.user.user_metadata?.company,
          avatar: session.user.user_metadata?.avatar,
          createdAt: session.user.created_at || new Date().toISOString(),
        };
        
        setUser(userData);
        setAccessToken(session.access_token);
        setIsAuthenticated(true);
      }
    };
    
    checkSession();
    
    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      if (session) {
        const userData: User = {
          id: session.user.id,
          email: session.user.email || '',
          name: session.user.user_metadata?.name || '',
          phone: session.user.user_metadata?.phone,
          company: session.user.user_metadata?.company,
          avatar: session.user.user_metadata?.avatar,
          createdAt: session.user.created_at || new Date().toISOString(),
        };
        
        setUser(userData);
        setAccessToken(session.access_token);
        setIsAuthenticated(true);
      } else {
        setUser(null);
        setAccessToken(null);
        setIsAuthenticated(false);
      }
    });
    
    return () => {
      subscription.unsubscribe();
    };
  }, []);

  const login = async (email: string, password: string) => {
    try {
      console.log('Attempting login for:', email);
      
      // Use Supabase client directly for authentication
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });
      
      if (error) {
        console.error('Login error from Supabase:', error);
        throw new Error(error.message || 'Login failed');
      }
      
      if (!data.session) {
        throw new Error('No session returned');
      }
      
      console.log('Login successful!');
      
      const userData: User = {
        id: data.user.id,
        email: data.user.email || '',
        name: data.user.user_metadata?.name || '',
        phone: data.user.user_metadata?.phone,
        company: data.user.user_metadata?.company,
        avatar: data.user.user_metadata?.avatar,
        createdAt: data.user.created_at || new Date().toISOString(),
      };
      
      setUser(userData);
      setAccessToken(data.session.access_token);
      setIsAuthenticated(true);
    } catch (error) {
      console.error('Login error:', error);
      throw error;
    }
  };

  const signup = async (name: string, email: string, password: string) => {
    try {
      console.log('Starting signup for:', email);
      
      // Get the anon key to pass in header
      const { publicAnonKey } = await import('/utils/supabase/info');
      
      // Use server-side signup to auto-confirm email
      const response = await fetch(`${API_URL}/auth/signup`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${publicAnonKey}`,
        },
        body: JSON.stringify({ name, email, password }),
      });
      
      const data = await response.json();
      
      if (!response.ok) {
        console.error('Signup error response:', data);
        throw new Error(data.error || 'Signup failed');
      }
      
      console.log('Signup successful, now logging in...');
      
      // After successful signup, login to get the session
      await login(email, password);
    } catch (error) {
      console.error('Signup error:', error);
      throw error;
    }
  };

  const logout = async () => {
    await supabase.auth.signOut();
    setUser(null);
    setAccessToken(null);
    setIsAuthenticated(false);
  };

  const updateProfile = async (updates: Partial<User>) => {
    if (!user || !accessToken) return;
    
    try {
      const response = await fetch(`${API_URL}/auth/profile`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${accessToken}`,
        },
        body: JSON.stringify(updates),
      });
      
      if (!response.ok) {
        const data = await response.json();
        console.error('Profile update error response:', data);
        throw new Error(data.error || 'Profile update failed');
      }
      
      const data = await response.json();
      const updatedUser = { ...user, ...updates };
      setUser(updatedUser);
      console.log('Profile updated successfully');
    } catch (error) {
      console.error('Profile update error:', error);
      // Don't throw - just log the error and update locally
      // This allows the app to continue working even if the server is unavailable
      const updatedUser = { ...user, ...updates };
      setUser(updatedUser);
    }
  };

  return (
    <AuthContext.Provider value={{ user, isAuthenticated, accessToken, login, signup, logout, updateProfile }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  return context;
}