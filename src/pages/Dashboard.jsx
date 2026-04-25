import { useEffect, useState, useCallback } from "react";
import { Link } from "react-router-dom";
import { Calendar, Brain, MessageCircle, Clock, Users, CreditCard, RefreshCw, IndianRupee, Github, Linkedin } from "lucide-react";
import { useAuth } from "../context/AuthContext";

export default function Dashboard() {
  const { user } = useAuth();
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [lastUpdated, setLastUpdated] = useState(null);

  const fetchData = useCallback(async (silent = false) => {
    if (!silent) setLoading(true); else setRefreshing(true);
    try {
      const r = await fetch(`/api/dashboard?userId=${user.userId}`);
      const d = await r.json();
      if (!d.error) { setData(d); setLastUpdated(new Date()); }
    } catch {}
    setLoading(false); setRefreshing(false);
  }, [user.userId]);

  // Initial load
  useEffect(() => { fetchData(); }, [fetchData]);

  // Auto-refresh every 30 seconds
  useEffect(() => {
    const id = setInterval(() => fetchData(true), 30000);
    return () => clearInterval(id);
  }, [fetchData]);

  // Instant refresh when user joins/leaves a group on the Groups page
  useEffect(() => {
    const handler = () => fetchData(true);
    window.addEventListener("groups-changed", handler);
    return () => window.removeEventListener("groups-changed", handler);
  }, [fetchData]);

  if (loading) return (
    <div className="container mx-auto py-8 px-4 flex items-center justify-center min-h-[60vh]">
      <div className="text-muted-foreground animate-pulse text-sm">Loading your dashboard…</div>
    </div>
  );

  const stats = [
    { label: "Sessions Completed", value: data?.stats?.sessions ?? 0, icon: Clock, color: "text-primary", gradient: "gradient-card-sage" },
    { label: "Assessments Taken", value: data?.stats?.assessments ?? 0, icon: Brain, color: "text-accent", gradient: "gradient-card-warm" },
    { label: "Groups Joined", value: data?.stats?.groups ?? 0, icon: Users, color: "text-primary", gradient: "gradient-card-sky" },
    { label: "Upcoming Appts", value: data?.stats?.upcoming ?? 0, icon: Calendar, color: "text-accent", gradient: "gradient-card-lavender" },
    { label: "Payments Made", value: data?.stats?.payments ?? 0, icon: CreditCard, color: "text-primary", gradient: "gradient-card-sage", to: "/payment" },
  ];

  return (
    <div className="container mx-auto py-8 px-4 space-y-6">
      {/* Header */}
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-3xl text-foreground" style={{ fontFamily: "var(--font-heading)" }}>
            Welcome back, {user.name} 👋
          </h1>
          <p className="text-muted-foreground text-sm mt-1">Here's your wellness overview</p>
        </div>
        <button onClick={() => fetchData(true)} disabled={refreshing}
          className="flex items-center gap-1.5 px-3 py-2 rounded-xl border border-border text-xs text-muted-foreground hover:bg-muted transition disabled:opacity-50 shrink-0 mt-1">
          <RefreshCw className={`w-3.5 h-3.5 ${refreshing ? "animate-spin" : ""}`} />
          {lastUpdated ? `Updated ${lastUpdated.toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit" })}` : "Refresh"}
        </button>
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-3">
        {stats.map((s) => {
          const inner = (
            <div className={`${s.gradient} rounded-2xl border border-border p-4 flex items-center gap-3 hover:shadow-sm transition-shadow h-full`}>
              <div className="p-2 rounded-xl bg-white/60">
                <s.icon className={`w-5 h-5 ${s.color}`} />
              </div>
              <div>
                <p className="text-2xl font-bold text-foreground">{s.value}</p>
                <p className="text-[11px] text-muted-foreground leading-tight">{s.label}</p>
              </div>
            </div>
          );
          return s.to ? (
            <Link key={s.label} to={s.to} className="block">{inner}</Link>
          ) : (
            <div key={s.label}>{inner}</div>
          );
        })}
      </div>

      {/* Upcoming Appointments + Recent Assessments */}
      <div className="grid lg:grid-cols-2 gap-5">
        <div className="bg-card rounded-2xl border border-border p-5">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-base font-semibold text-foreground" style={{ fontFamily: "var(--font-heading)" }}>Upcoming Appointments</h2>
            <Link to="/appointments" className="text-xs text-primary hover:underline font-medium">View all</Link>
          </div>
          <div className="space-y-2">
            {data?.upcomingAppointments?.length > 0 ? data.upcomingAppointments.map((a) => (
              <div key={a.Appointment_ID} className="flex items-center justify-between p-3 rounded-xl bg-muted/40">
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center shrink-0">
                    <Calendar className="w-3.5 h-3.5 text-primary" />
                  </div>
                  <div>
                    <p className="text-sm font-medium text-foreground">{a.therapist_name}</p>
                    <p className="text-xs text-muted-foreground">{a.Specialization}</p>
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-xs font-semibold text-foreground">
                    {new Date(a.Date).toLocaleDateString("en-IN", { day: "numeric", month: "short" })}
                  </p>
                  <p className="text-xs text-muted-foreground">{String(a.Time).slice(0, 5)}</p>
                </div>
              </div>
            )) : (
              <p className="text-sm text-muted-foreground text-center py-6">
                No upcoming appointments.{" "}
                <Link to="/therapists" className="text-primary hover:underline font-medium">Book one</Link>
              </p>
            )}
          </div>
        </div>

        <div className="bg-card rounded-2xl border border-border p-5">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-base font-semibold text-foreground" style={{ fontFamily: "var(--font-heading)" }}>Recent Assessments</h2>
            <Link to="/assessment" className="text-xs text-primary hover:underline font-medium">Take New</Link>
          </div>
          <div className="space-y-2">
            {data?.recentAssessments?.length > 0 ? data.recentAssessments.map((a) => (
              <div key={a.Assessment_ID} className="flex items-center justify-between p-3 rounded-xl bg-muted/40">
                <div>
                  <p className="text-sm font-medium text-foreground">{a.Assessment_Type}</p>
                  <p className="text-xs text-muted-foreground">{a.Remarks || "—"}</p>
                </div>
                <p className="text-xs text-muted-foreground shrink-0 ml-4">
                  {new Date(a.Date).toLocaleDateString("en-IN", { day: "numeric", month: "short" })}
                </p>
              </div>
            )) : (
              <p className="text-sm text-muted-foreground text-center py-6">
                No assessments yet.{" "}
                <Link to="/assessment" className="text-primary hover:underline font-medium">Take one</Link>
              </p>
            )}
          </div>
        </div>
      </div>

      {/* Recent Payments strip */}
      {data?.recentPayments?.length > 0 && (
        <div className="bg-card rounded-2xl border border-border p-5">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-base font-semibold text-foreground" style={{ fontFamily: "var(--font-heading)" }}>Recent Payments</h2>
            <Link to="/payment" className="text-xs text-primary hover:underline font-medium">View all</Link>
          </div>
          <div className="grid sm:grid-cols-3 gap-3">
            {data.recentPayments.map((p) => (
              <div key={p.Payment_ID} className="flex items-center gap-3 p-3 rounded-xl bg-muted/40">
                <div className="p-2 rounded-xl bg-primary/10">
                  <IndianRupee className="w-3.5 h-3.5 text-primary" />
                </div>
                <div className="min-w-0 flex-1">
                  <p className="text-sm font-bold text-foreground">₹{Number(p.Amount).toLocaleString("en-IN")}</p>
                  <p className="text-xs text-muted-foreground truncate">{p.Payment_Mode} · {p.Status}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Quick Actions */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-3">
        {[
          { label: "Book Appointment", icon: Calendar, to: "/therapists", gradient: "gradient-card-sage" },
          { label: "Chat with Therapist", icon: MessageCircle, to: "/chat", gradient: "gradient-card-lavender" },
          { label: "Take Assessment", icon: Brain, to: "/assessment", gradient: "gradient-card-warm" },
          { label: "Join a Group", icon: Users, to: "/groups", gradient: "gradient-card-sky" },
          { label: "Make Payment", icon: CreditCard, to: "/payment", gradient: "gradient-card-sage" },
        ].map((a) => (
          <Link key={a.label} to={a.to}>
            <div className={`${a.gradient} rounded-2xl p-4 border border-border hover:shadow-md transition-shadow text-center h-full flex flex-col items-center justify-center`}>
              <a.icon className="w-6 h-6 text-primary mb-2" />
              <p className="text-xs font-semibold text-foreground">{a.label}</p>
            </div>
          </Link>
        ))}
      </div>

      {/* Footer */}
      <footer className="pt-12 pb-6 border-t border-border mt-8">
        <div className="flex flex-col md:flex-row items-center justify-between gap-6">
          <div className="text-center md:text-left">
            <h3 className="text-lg font-bold text-foreground mb-1">MindWell</h3>
            <p className="text-xs text-muted-foreground">Built with ❤️ for your mental well-being</p>
          </div>
          
          <div className="flex items-center gap-4">
            <a href="https://github.com/muskankakwani06" target="_blank" rel="noopener noreferrer" 
              className="flex items-center gap-2 px-4 py-2 rounded-xl bg-muted/50 hover:bg-muted transition text-sm font-medium text-foreground">
              <Github className="w-4 h-4" /> GitHub
            </a>
            <a href="https://www.linkedin.com/in/muskan-kakwani-528753346/" target="_blank" rel="noopener noreferrer"
              className="flex items-center gap-2 px-4 py-2 rounded-xl bg-primary text-white hover:opacity-90 transition text-sm font-medium">
              <Linkedin className="w-4 h-4" /> LinkedIn
            </a>
          </div>
        </div>
        <p className="text-center text-[10px] text-muted-foreground mt-8">© 2026 MindWell App. All rights reserved.</p>
      </footer>
    </div>
  );
}

