import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { AuthProvider } from "./context/AuthContext";
import { Layout, ProtectedRoute } from "./components/Layout";

import Landing from "./pages/Landing";
import Login from "./pages/Login";
import Signup from "./pages/Signup";
import Dashboard from "./pages/Dashboard";
import Therapists from "./pages/Therapists";
import Appointments from "./pages/Appointments";
import Assessment from "./pages/Assessment";
import Groups from "./pages/Groups";
import Chat from "./pages/Chat";
import Feedback from "./pages/Feedback";
import Payment from "./pages/Payment";
import NotFound from "./pages/NotFound";

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          {/* Public */}
          <Route path="/" element={<Layout><Landing /></Layout>} />
          <Route path="/login" element={<Login />} />
          <Route path="/signup" element={<Signup />} />

          {/* Protected */}
          <Route path="/dashboard"    element={<ProtectedRoute><Dashboard /></ProtectedRoute>} />
          <Route path="/therapists"   element={<ProtectedRoute><Therapists /></ProtectedRoute>} />
          <Route path="/appointments" element={<ProtectedRoute><Appointments /></ProtectedRoute>} />
          <Route path="/assessment"   element={<ProtectedRoute><Assessment /></ProtectedRoute>} />
          <Route path="/groups"       element={<ProtectedRoute><Groups /></ProtectedRoute>} />
          <Route path="/chat"         element={<ProtectedRoute><Chat /></ProtectedRoute>} />

          <Route path="/payment" element={<ProtectedRoute><Payment /></ProtectedRoute>} />
          <Route path="/feedback" element={<ProtectedRoute><Feedback /></ProtectedRoute>} />
          <Route path="*" element={<NotFound />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}
