import { RouterProvider } from "react-router";
import { router } from "@/app/routes.tsx";
import { Toaster } from "@/app/components/ui/sonner";
import { AuthProvider } from "@/app/contexts/AuthContext";
import { DataProvider } from "@/app/contexts/DataContext";
import { ThemeProvider } from "@/app/contexts/ThemeContext";

export default function App() {
  return (
    <ThemeProvider>
      <AuthProvider>
        <DataProvider>
          <RouterProvider router={router} />
          <Toaster />
        </DataProvider>
      </AuthProvider>
    </ThemeProvider>
  );
}