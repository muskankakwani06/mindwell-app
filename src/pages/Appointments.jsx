import { useEffect, useState } from "react";
import { Calendar, Clock, Phone, Trash2 } from "lucide-react";
import { useAuth } from "../context/AuthContext";
import { Link } from "react-router-dom";
import { db } from "../lib/firebase";
import { collection, query, where, onSnapshot, deleteDoc, doc } from "firebase/firestore";

export default function Appointments() {
  const { user } = useAuth();
  const [appointments, setAppointments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState("");

  useEffect(() => {
    if (!user?.uid) return;
    const q = query(collection(db, "appointments"), where("userId", "==", user.uid));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setAppointments(snapshot.docs.map(d => ({ Appointment_ID: d.id, ...d.data() })));
      setLoading(false);
    });
    return () => unsubscribe();
  }, [user?.uid]);

  const showToast = (msg) => { setToast(msg); setTimeout(() => setToast(""), 3000); };

  const handleCancel = async (id) => {
    if (!window.confirm("Cancel this appointment?")) return;
    try {
      await deleteDoc(doc(db, "appointments", id));
      showToast("Appointment cancelled");
    } catch { showToast("Failed to cancel"); }
  };

  const today = new Date().toISOString().split("T")[0];
  const upcoming = appointments.filter((a) => String(a.Date).slice(0, 10) >= today);
  const past     = appointments.filter((a) => String(a.Date).slice(0, 10) < today);

  const AppCard = ({ a }) => (
    <div className="flex items-center justify-between p-4 rounded-xl bg-[hsl(var(--muted))]/40 border border-border">
      <div className="flex items-center gap-4">
        <div className="p-2.5 rounded-xl bg-primary/10">
          <Calendar className="w-5 h-5 text-primary" />
        </div>
        <div>
          <p className="font-medium text-foreground">{a.therapist_name}</p>
          <p className="text-sm text-muted-foreground">{a.Specialization}</p>
          {a.therapist_phone && (
            <p className="text-xs text-muted-foreground flex items-center gap-1 mt-0.5">
              <Phone className="w-3 h-3" /> {a.therapist_phone}
            </p>
          )}
        </div>
      </div>
      <div className="flex items-center gap-4">
        <div className="text-right">
          <p className="text-sm font-medium text-foreground flex items-center gap-1 justify-end">
            <Calendar className="w-3.5 h-3.5 text-muted-foreground" />
            {new Date(a.Date).toLocaleDateString("en-IN", { day: "numeric", month: "short", year: "numeric" })}
          </p>
          <p className="text-xs text-muted-foreground flex items-center gap-1 justify-end mt-0.5">
            <Clock className="w-3 h-3" />
            {String(a.Time).slice(0, 5)}
          </p>
        </div>
        {String(a.Date).slice(0, 10) >= today && (
          <button onClick={() => handleCancel(a.Appointment_ID)}
            className="p-2 rounded-lg text-destructive hover:bg-destructive/10 transition">
            <Trash2 className="w-4 h-4" />
          </button>
        )}
      </div>
    </div>
  );

  if (loading) return (
    <div className="container mx-auto py-8 px-4 flex items-center justify-center min-h-[60vh]">
      <div className="text-muted-foreground animate-pulse">Loading appointments...</div>
    </div>
  );

  return (
    <div className="container mx-auto py-8 px-4 space-y-8">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl text-foreground" style={{ fontFamily: "var(--font-heading)" }}>Appointments</h1>
          <p className="text-muted-foreground mt-1">Manage your therapy sessions</p>
        </div>
        <Link to="/therapists"
          className="px-4 py-2 rounded-xl bg-primary text-[hsl(var(--primary-foreground))] text-sm font-medium hover:opacity-90 transition">
          + Book New
        </Link>
      </div>

      <div>
        <h2 className="text-lg font-medium text-foreground mb-3" style={{ fontFamily: "var(--font-heading)" }}>
          Upcoming ({upcoming.length})
        </h2>
        {upcoming.length > 0 ? (
          <div className="space-y-3">{upcoming.map((a) => <AppCard key={a.Appointment_ID} a={a} />)}</div>
        ) : (
          <div className="text-center py-10 bg-[hsl(var(--card))] rounded-2xl border border-border">
            <Calendar className="w-10 h-10 text-muted-foreground mx-auto mb-3" />
            <p className="text-muted-foreground text-sm">No upcoming appointments</p>
            <Link to="/therapists" className="text-primary text-sm hover:underline mt-1 inline-block">Book one now</Link>
          </div>
        )}
      </div>

      {past.length > 0 && (
        <div>
          <h2 className="text-lg font-medium text-foreground mb-3" style={{ fontFamily: "var(--font-heading)" }}>
            Past ({past.length})
          </h2>
          <div className="space-y-3 opacity-70">{past.map((a) => <AppCard key={a.Appointment_ID} a={a} />)}</div>
        </div>
      )}

      {toast && (
        <div className="fixed bottom-6 left-1/2 -translate-x-1/2 bg-[hsl(var(--card))] border border-border shadow-lg rounded-2xl px-6 py-3 text-sm text-foreground z-50">
          {toast}
        </div>
      )}
    </div>
  );
}
