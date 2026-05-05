import { useState, useEffect } from "react";
import { CreditCard, Smartphone, Banknote, CheckCircle, Clock, XCircle, IndianRupee } from "lucide-react";
import { useAuth } from "../context/AuthContext";
import { db } from "../lib/firebase";
import { collection, query, where, onSnapshot, addDoc, orderBy, serverTimestamp } from "firebase/firestore";

const MODES = [
  { id: "UPI",  label: "UPI",         icon: Smartphone,  desc: "Google Pay, PhonePe, Paytm" },
  { id: "Card", label: "Card",        icon: CreditCard,  desc: "Debit / Credit card" },
  { id: "Cash", label: "Cash",        icon: Banknote,    desc: "Pay at the clinic" },
];

const PRESET_AMOUNTS = [300, 500, 700, 1000, 1500];

export default function Payment() {
  const { user } = useAuth();
  const [history, setHistory]       = useState([]);
  const [loading, setLoading]       = useState(true);
  const [amount, setAmount]         = useState("");
  const [mode, setMode]             = useState("UPI");
  const [paying, setPaying]         = useState(false);
  const [success, setSuccess]       = useState(false);
  const [toast, setToast]           = useState("");
  const [upiId, setUpiId]           = useState("");
  const [cardNum, setCardNum]       = useState("");

  const showToast = (msg) => { setToast(msg); setTimeout(() => setToast(""), 3000); };

  useEffect(() => {
    if (!user?.uid) return;
    const q = query(collection(db, "payments"), where("userId", "==", user.uid));
    const unsubscribe = onSnapshot(q, (snap) => {
      setHistory(snap.docs.map(d => ({ Payment_ID: d.id, ...d.data() }))
        .sort((a, b) => (b.timestamp?.seconds || 0) - (a.timestamp?.seconds || 0)));
      setLoading(false);
    });
    return () => unsubscribe();
  }, [user?.uid]);

  const pay = async () => {
    if (!amount || isNaN(amount) || Number(amount) <= 0) { showToast("Enter a valid amount"); return; }
    if (mode === "UPI" && !upiId.trim()) { showToast("Enter your UPI ID"); return; }
    if (mode === "Card" && cardNum.replace(/\s/g, "").length < 12) { showToast("Enter a valid card number"); return; }
    setPaying(true);
    try {
      await addDoc(collection(db, "payments"), {
        userId: user.uid,
        Amount: Number(amount),
        Payment_Mode: mode,
        Status: "Completed",
        timestamp: serverTimestamp(),
        Date: new Date().toISOString()
      });
      setSuccess(true);
      setAmount(""); setUpiId(""); setCardNum("");
      setTimeout(() => setSuccess(false), 4000);
    } catch { showToast("Payment failed. Try again."); }
    setPaying(false);
  };

  const totalPaid = history.filter(p => p.Status === "Completed").reduce((s, p) => s + Number(p.Amount), 0);

  const statusIcon = (s) => s === "Completed"
    ? <CheckCircle className="w-3.5 h-3.5 text-emerald-500" />
    : s === "Pending"
    ? <Clock className="w-3.5 h-3.5 text-amber-400" />
    : <XCircle className="w-3.5 h-3.5 text-red-400" />;

  const statusColor = (s) => s === "Completed" ? "text-emerald-600 bg-emerald-50" : s === "Pending" ? "text-amber-600 bg-amber-50" : "text-red-600 bg-red-50";

  return (
    <div className="container mx-auto py-8 px-4 max-w-4xl space-y-6">
      <div>
        <h1 className="text-3xl text-foreground" style={{ fontFamily: "var(--font-heading)" }}>Payments</h1>
        <p className="text-muted-foreground text-sm mt-1">Manage your session payments securely</p>
      </div>

      {/* Summary pill */}
      {!loading && history.length > 0 && (
        <div className="flex gap-3 flex-wrap">
          <div className="flex items-center gap-2 bg-primary/8 border border-primary/20 rounded-2xl px-4 py-2.5">
            <IndianRupee className="w-4 h-4 text-primary" />
            <span className="text-sm font-semibold text-primary">₹{totalPaid.toLocaleString("en-IN")} paid total</span>
          </div>
          <div className="flex items-center gap-2 bg-muted rounded-2xl px-4 py-2.5">
            <CreditCard className="w-4 h-4 text-muted-foreground" />
            <span className="text-sm text-muted-foreground">{history.length} transaction{history.length !== 1 ? "s" : ""}</span>
          </div>
        </div>
      )}

      <div className="grid lg:grid-cols-5 gap-5">
        {/* Payment Form */}
        <div className="lg:col-span-3 bg-card rounded-3xl border border-border p-6 shadow-sm space-y-5">
          <h2 className="text-base font-semibold text-foreground" style={{ fontFamily: "var(--font-heading)" }}>
            Make a Payment
          </h2>

          {success ? (
            <div className="text-center py-10">
              <div className="w-16 h-16 rounded-full bg-emerald-100 flex items-center justify-center mx-auto mb-3">
                <CheckCircle className="w-8 h-8 text-emerald-500" />
              </div>
              <p className="text-base font-semibold text-foreground">Payment Successful!</p>
              <p className="text-sm text-muted-foreground mt-1">Your transaction has been recorded.</p>
            </div>
          ) : (
            <>
              {/* Amount */}
              <div>
                <label className="text-xs font-semibold text-muted-foreground uppercase tracking-wide mb-2 block">Amount (₹)</label>
                <div className="relative">
                  <span className="absolute left-4 top-1/2 -translate-y-1/2 text-muted-foreground text-sm">₹</span>
                  <input
                    type="number" value={amount} onChange={(e) => setAmount(e.target.value)}
                    placeholder="0.00"
                    className="w-full pl-8 pr-4 py-3 rounded-2xl border border-border bg-background text-foreground text-sm focus:outline-none focus:ring-2 focus:ring-ring"
                  />
                </div>
                <div className="flex flex-wrap gap-2 mt-2.5">
                  {PRESET_AMOUNTS.map((a) => (
                    <button key={a} onClick={() => setAmount(String(a))}
                      className={`px-3 py-1.5 rounded-xl text-xs font-semibold border transition ${
                        amount === String(a) ? "bg-primary text-white border-primary" : "border-border text-muted-foreground hover:bg-muted"
                      }`}>
                      ₹{a}
                    </button>
                  ))}
                </div>
              </div>

              {/* Mode */}
              <div>
                <label className="text-xs font-semibold text-muted-foreground uppercase tracking-wide mb-2 block">Payment Mode</label>
                <div className="grid grid-cols-3 gap-2">
                  {MODES.map((m) => (
                    <button key={m.id} onClick={() => setMode(m.id)}
                      className={`flex flex-col items-center gap-1.5 p-3 rounded-2xl border text-center transition ${
                        mode === m.id ? "border-primary bg-primary/8" : "border-border hover:bg-muted"
                      }`}>
                      <m.icon className={`w-5 h-5 ${mode === m.id ? "text-primary" : "text-muted-foreground"}`} />
                      <span className={`text-xs font-semibold ${mode === m.id ? "text-primary" : "text-foreground"}`}>{m.label}</span>
                      <span className="text-[10px] text-muted-foreground leading-tight">{m.desc}</span>
                    </button>
                  ))}
                </div>
              </div>

              {/* UPI field */}
              {mode === "UPI" && (
                <div>
                  <label className="text-xs font-semibold text-muted-foreground uppercase tracking-wide mb-2 block">UPI ID</label>
                  <input type="text" value={upiId} onChange={(e) => setUpiId(e.target.value)}
                    placeholder="yourname@upi"
                    className="w-full px-4 py-3 rounded-2xl border border-border bg-background text-sm focus:outline-none focus:ring-2 focus:ring-ring" />
                </div>
              )}

              {/* Card field */}
              {mode === "Card" && (
                <div className="space-y-3">
                  <div>
                    <label className="text-xs font-semibold text-muted-foreground uppercase tracking-wide mb-2 block">Card Number</label>
                    <input type="text" value={cardNum}
                      onChange={(e) => {
                        const v = e.target.value.replace(/\D/g, "").slice(0, 16);
                        setCardNum(v.replace(/(.{4})/g, "$1 ").trim());
                      }}
                      placeholder="1234 5678 9012 3456"
                      className="w-full px-4 py-3 rounded-2xl border border-border bg-background text-sm focus:outline-none focus:ring-2 focus:ring-ring font-mono tracking-widest" />
                  </div>
                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <label className="text-xs font-semibold text-muted-foreground uppercase tracking-wide mb-2 block">Expiry</label>
                      <input type="text" placeholder="MM / YY"
                        className="w-full px-4 py-3 rounded-2xl border border-border bg-background text-sm focus:outline-none focus:ring-2 focus:ring-ring" />
                    </div>
                    <div>
                      <label className="text-xs font-semibold text-muted-foreground uppercase tracking-wide mb-2 block">CVV</label>
                      <input type="password" maxLength={3} placeholder="···"
                        className="w-full px-4 py-3 rounded-2xl border border-border bg-background text-sm focus:outline-none focus:ring-2 focus:ring-ring font-mono" />
                    </div>
                  </div>
                </div>
              )}

              <button onClick={pay} disabled={paying || !amount}
                className="w-full py-3.5 rounded-2xl bg-primary text-white text-sm font-bold hover:opacity-90 active:scale-[0.98] transition-all disabled:opacity-50 flex items-center justify-center gap-2">
                {paying ? (
                  <span className="animate-pulse">Processing…</span>
                ) : (
                  <><IndianRupee className="w-4 h-4" /> Pay {amount ? `₹${Number(amount).toLocaleString("en-IN")}` : "Now"}</>
                )}
              </button>

              <p className="text-[11px] text-muted-foreground text-center">🔒 This is a demo — no real money is charged</p>
            </>
          )}
        </div>

        {/* History */}
        <div className="lg:col-span-2 bg-card rounded-3xl border border-border shadow-sm overflow-hidden flex flex-col">
          <div className="px-5 py-4 border-b border-border bg-muted/30">
            <p className="text-[11px] font-bold text-muted-foreground tracking-widest uppercase">Transaction History</p>
          </div>
          <div className="flex-1 overflow-y-auto divide-y divide-border/50">
            {loading ? (
              <div className="p-6 text-center text-sm text-muted-foreground animate-pulse">Loading…</div>
            ) : history.length === 0 ? (
              <div className="p-8 text-center">
                <CreditCard className="w-10 h-10 text-muted-foreground mx-auto mb-3" />
                <p className="text-sm text-muted-foreground">No transactions yet</p>
              </div>
            ) : (
              history.map((p) => (
                <div key={p.Payment_ID} className="px-5 py-3.5 flex items-center justify-between gap-3">
                  <div className="min-w-0">
                    <div className="flex items-center gap-1.5 mb-0.5">
                      {statusIcon(p.Status)}
                      <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${statusColor(p.Status)}`}>
                        {p.Status}
                      </span>
                    </div>
                    <p className="text-xs text-muted-foreground truncate">{p.Payment_Mode}
                      {p.therapist_name ? ` · ${p.therapist_name}` : ""}
                    </p>
                    {p.Date && (
                      <p className="text-[10px] text-muted-foreground mt-0.5">
                        {new Date(p.Date).toLocaleDateString("en-IN", { day: "numeric", month: "short", year: "numeric" })}
                      </p>
                    )}
                  </div>
                  <p className="text-sm font-bold text-foreground shrink-0">₹{Number(p.Amount).toLocaleString("en-IN")}</p>
                </div>
              ))
            )}
          </div>
        </div>
      </div>

      {toast && (
        <div className="fixed bottom-6 left-1/2 -translate-x-1/2 bg-card border border-border shadow-lg rounded-2xl px-6 py-3 text-sm text-foreground z-50 whitespace-nowrap">
          {toast}
        </div>
      )}
    </div>
  );
}
