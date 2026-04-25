import { Navigate } from "react-router-dom";
import Navbar from "./Navbar";
import { useAuth } from "../context/AuthContext";

export function Layout({ children }) {
  return (
    <>
      <Navbar />
      <main className="min-h-screen">{children}</main>
    </>
  );
}

export function ProtectedRoute({ children }) {
  const { user } = useAuth();
  if (!user) return <Navigate to="/login" replace />;
  return <Layout>{children}</Layout>;
}
