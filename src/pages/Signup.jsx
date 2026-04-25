import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { Heart } from "lucide-react";
import { useAuth } from "../context/AuthContext";

export default function Signup() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const [form, setForm] = useState({ name: "", email: "", phone: "" });
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      const res = await fetch("/api/auth/register", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(form),
      });
      const data = await res.json();
      if (!res.ok) { setError(data.error || "Registration failed"); setLoading(false); return; }
      login(data.user);
      navigate("/dashboard");
    } catch {
      setError("Could not connect to server. Is the backend running?");
      setLoading(false);
    }
  };

  const field = (key, label, type = "text", placeholder = "") => (
    <div>
      <label className="block text-sm font-medium text-foreground mb-1.5">{label}</label>
      <input type={type} value={form[key]}
        onChange={(e) => setForm({ ...form, [key]: e.target.value })}
        placeholder={placeholder}
        className="w-full rounded-xl border border-border bg-background px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-ring" />
    </div>
  );

  return (
    <div className="min-h-screen gradient-hero flex items-center justify-center px-4 py-8">
      <div className="bg-[hsl(var(--card))] rounded-3xl border border-border shadow-xl w-full max-w-md p-8">
        <div className="flex flex-col items-center mb-8">
          <div className="flex items-center gap-2 mb-2">
            <Heart className="w-7 h-7 text-primary fill-primary/20" />
            <span style={{ fontFamily: "var(--font-heading)" }} className="text-2xl text-foreground">MindWell</span>
          </div>
          <h1 className="text-xl text-foreground mt-2" style={{ fontFamily: "var(--font-heading)" }}>Create your account</h1>
          <p className="text-sm text-muted-foreground mt-1">Start your wellness journey today</p>
        </div>

        {error && <div className="mb-4 p-3 rounded-xl bg-destructive/10 text-destructive text-sm text-center">{error}</div>}

        <form onSubmit={handleSubmit} className="space-y-4">
          {field("name", "Full Name", "text", "Muskan")}
          {field("email", "Email", "email", "you@example.com")}
          {field("phone", "Phone (optional)", "tel", "9876543210")}
          <button type="submit" disabled={loading}
            className="w-full py-2.5 rounded-xl bg-primary text-[hsl(var(--primary-foreground))] text-sm font-medium hover:opacity-90 transition disabled:opacity-60">
            {loading ? "Creating account..." : "Create Account"}
          </button>
        </form>

        <p className="text-center text-sm text-muted-foreground mt-6">
          Already have an account?{" "}
          <Link to="/login" className="text-primary hover:underline font-medium">Sign in</Link>
        </p>
      </div>
    </div>
  );
}
