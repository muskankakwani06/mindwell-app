import { useEffect, useState } from "react";
import { Star, X, Calendar, Clock, Phone } from "lucide-react";
import { useAuth } from "../context/AuthContext";
import { db } from "../lib/firebase";
import { collection, getDocs, addDoc } from "firebase/firestore";

const TIME_SLOTS = ["09:00", "10:00", "11:00", "12:00", "14:00", "15:00", "16:00", "17:00"];

export default function Therapists() {
  const { user } = useAuth();
  const [therapists, setTherapists] = useState([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState(null);
  const [date, setDate] = useState("");
  const [time, setTime] = useState("");
  const [booking, setBooking] = useState(false);
  const [toast, setToast] = useState("");

  useEffect(() => {
    getDocs(collection(db, "therapists"))
      .then((snap) => {
        setTherapists(snap.docs.map(d => ({ Therapist_ID: d.id, ...d.data() })));
        setLoading(false);
      })
      .catch(() => setLoading(false));
  }, []);

  const showToast = (msg) => { setToast(msg); setTimeout(() => setToast(""), 3500); };

  const openModal = (t) => {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    setDate(tomorrow.toISOString().split("T")[0]);
    setTime("");
    setModal(t);
  };

  const handleBook = async () => {
    if (!date || !time) { showToast("Please select a date and time"); return; }
    setBooking(true);
    try {
      await addDoc(collection(db, "appointments"), {
        date,
        time: time + ":00",
        userId: user.uid,
        therapistId: modal.Therapist_ID,
        therapist_name: modal.Name,
        Specialization: modal.Specialization,
        status: "upcoming"
      });
      showToast("✅ Appointment booked!");
      setModal(null);
    } catch {
      showToast("❌ Booking failed");
    }
    setBooking(false);
  };

  if (loading) return (
    <div className="container mx-auto py-8 px-4 flex items-center justify-center min-h-[60vh]">
      <div className="text-muted-foreground animate-pulse">Loading therapists...</div>
    </div>
  );

  const today = new Date().toISOString().split("T")[0];

  return (
    <div className="container mx-auto py-8 px-4">
      <h1 className="text-3xl text-foreground mb-1" style={{ fontFamily: "var(--font-heading)" }}>Find a Therapist</h1>
      <p className="text-muted-foreground mt-1 mb-8">Licensed professionals ready to support you</p>

      <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
        {therapists.map((t) => {
          const name = t.Name || t.name || "Therapist";
          const spec = t.Specialization || t.specialization || "";
          const initials = name.split(" ").filter(Boolean).slice(-2).map((n) => n[0]).join("");
          return (
            <div key={t.Therapist_ID} className="bg-[hsl(var(--card))] rounded-2xl border border-border p-6 hover:shadow-lg transition-shadow">
              <div className="flex items-center gap-4 mb-4">
                <div className="w-14 h-14 rounded-full bg-primary/10 flex items-center justify-center text-primary font-bold text-lg">{initials}</div>
                <div>
                  <h3 className="font-medium text-foreground" style={{ fontFamily: "var(--font-heading)" }}>{name}</h3>
                  <p className="text-sm text-muted-foreground">{spec}</p>
                </div>
              </div>
              <div className="flex items-center gap-3 mb-1 text-sm text-muted-foreground">
                {(t.Rating || t.Rating === 0) ? (
                  <span className="flex items-center gap-1">
                    <Star className="w-4 h-4 text-amber-400 fill-amber-400" />
                    {t.Rating} ({t.ReviewCount || 0} reviews)
                  </span>
                ) : (
                  <span className="text-xs text-muted-foreground">No reviews yet</span>
                )}
              </div>
              {(t.Phone || t.phone) && (
                <div className="flex items-center gap-1 text-xs text-muted-foreground mb-4">
                  <Phone className="w-3 h-3" /> {t.Phone || t.phone}
                </div>
              )}
              <button onClick={() => openModal({ ...t, Name: name, Specialization: spec })}
                className="w-full py-2.5 rounded-xl text-sm font-medium bg-primary text-[hsl(var(--primary-foreground))] hover:opacity-90 transition">
                Book Session
              </button>
            </div>
          );
        })}
      </div>

      {/* Booking Modal */}
      {modal && (
        <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-sm flex items-center justify-center p-4"
          onClick={(e) => e.target === e.currentTarget && setModal(null)}>
          <div className="bg-[hsl(var(--card))] rounded-2xl border border-border shadow-2xl w-full max-w-md p-6">
            <div className="flex items-center justify-between mb-6">
              <div>
                <h2 className="text-xl text-foreground" style={{ fontFamily: "var(--font-heading)" }}>Book Appointment</h2>
                <p className="text-sm text-muted-foreground mt-0.5">{modal.Name} — {modal.Specialization}</p>
              </div>
              <button onClick={() => setModal(null)} className="p-2 rounded-lg hover:bg-[hsl(var(--muted))] transition">
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <label className="flex items-center gap-2 text-sm font-medium text-foreground mb-2">
                  <Calendar className="w-4 h-4 text-primary" /> Select Date
                </label>
                <input type="date" value={date} min={today} onChange={(e) => setDate(e.target.value)}
                  className="w-full rounded-xl border border-border bg-background px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-ring" />
              </div>
              <div>
                <label className="flex items-center gap-2 text-sm font-medium text-foreground mb-2">
                  <Clock className="w-4 h-4 text-primary" /> Select Time
                </label>
                <div className="grid grid-cols-4 gap-2">
                  {TIME_SLOTS.map((slot) => (
                    <button key={slot} onClick={() => setTime(slot)}
                      className={`py-2 rounded-xl text-sm font-medium border transition ${
                        time === slot ? "bg-primary text-[hsl(var(--primary-foreground))] border-primary" : "border-border text-foreground hover:bg-[hsl(var(--muted))]"
                      }`}>
                      {slot}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            <button onClick={handleBook} disabled={booking}
              className="w-full mt-6 py-3 rounded-xl bg-primary text-[hsl(var(--primary-foreground))] text-sm font-medium hover:opacity-90 transition disabled:opacity-60">
              {booking ? "Booking..." : "Confirm Appointment"}
            </button>
          </div>
        </div>
      )}

      {/* Toast */}
      {toast && (
        <div className="fixed bottom-6 left-1/2 -translate-x-1/2 bg-[hsl(var(--card))] border border-border shadow-lg rounded-2xl px-6 py-3 text-sm text-foreground z-50">
          {toast}
        </div>
      )}
    </div>
  );
}
