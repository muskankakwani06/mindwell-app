import { useState, useEffect } from "react";
import { Star, Send, Trash2, CheckCircle } from "lucide-react";
import { useAuth } from "../context/AuthContext";
import { db } from "../lib/firebase";
import { collection, query, where, onSnapshot, addDoc, deleteDoc, doc, serverTimestamp } from "firebase/firestore";

export default function Feedback() {
  const { user } = useAuth();
  const [history, setHistory] = useState([]);
  const [loading, setLoading] = useState(true);
  const [rating, setRating] = useState(0);
  const [hovered, setHovered] = useState(0);
  const [feedbackText, setFeedbackText] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [toast, setToast] = useState("");

  const showToast = (msg) => { setToast(msg); setTimeout(() => setToast(""), 3000); };

  useEffect(() => {
    if (!user?.uid) return;
    const q = query(collection(db, "feedback"), where("userId", "==", user.uid));
    const unsubscribe = onSnapshot(q, (snap) => {
      setHistory(snap.docs.map(d => ({ Feedback_ID: d.id, ...d.data() }))
        .sort((a, b) => (b.timestamp?.seconds || 0) - (a.timestamp?.seconds || 0)));
      setLoading(false);
    });
    return () => unsubscribe();
  }, [user?.uid]);

  const submit = async () => {
    if (!rating) { showToast("Please select a star rating"); return; }
    setSubmitting(true);
    try {
      await addDoc(collection(db, "feedback"), {
        userId: user.uid,
        Rating: rating,
        Feedback_Text: feedbackText,
        Date: new Date().toISOString(),
        timestamp: serverTimestamp()
      });
      setSubmitted(true);
      setRating(0);
      setFeedbackText("");
      setTimeout(() => setSubmitted(false), 3000);
    } catch {
      showToast("Something went wrong. Try again.");
    }
    setSubmitting(false);
  };

  const deleteFeedback = async (id) => {
    try {
      await deleteDoc(doc(db, "feedback", id));
      showToast("Feedback deleted");
    } catch {
      showToast("Couldn't delete. Try again.");
    }
  };

  const ratingLabel = ["", "Poor", "Fair", "Good", "Very Good", "Excellent"];
  const ratingColor = ["", "text-red-500", "text-orange-400", "text-yellow-400", "text-primary", "text-primary"];

  return (
    <div className="container mx-auto py-8 px-4 space-y-8 max-w-3xl">
      <div>
        <h1 className="text-3xl text-foreground" style={{ fontFamily: "var(--font-heading)" }}>Feedback</h1>
        <p className="text-muted-foreground text-sm mt-1">Share your experience with MindWell</p>
      </div>

      {/* Submit Form */}
      <div className="bg-[hsl(var(--card))] rounded-3xl border border-border p-6 shadow-sm">
        <h2 className="text-lg font-semibold text-foreground mb-1" style={{ fontFamily: "var(--font-heading)" }}>
          How was your experience?
        </h2>
        <p className="text-sm text-muted-foreground mb-6">Your feedback helps us improve MindWell for everyone.</p>

        {submitted ? (
          <div className="text-center py-8">
            <div className="w-16 h-16 rounded-full bg-primary/10 flex items-center justify-center mx-auto mb-3">
              <CheckCircle className="w-8 h-8 text-primary" />
            </div>
            <p className="text-base font-semibold text-foreground">Thank you for your feedback!</p>
            <p className="text-sm text-muted-foreground mt-1">Your response has been recorded.</p>
          </div>
        ) : (
          <>
            {/* Star Rating */}
            <div className="flex flex-col items-center gap-3 mb-6">
              <div className="flex gap-2">
                {[1, 2, 3, 4, 5].map((star) => (
                  <button
                    key={star}
                    onClick={() => setRating(star)}
                    onMouseEnter={() => setHovered(star)}
                    onMouseLeave={() => setHovered(0)}
                    className="transition-transform hover:scale-110 active:scale-95"
                  >
                    <Star
                      className={`w-9 h-9 transition-colors ${
                        star <= (hovered || rating)
                          ? "text-yellow-400 fill-yellow-400"
                          : "text-border fill-transparent"
                      }`}
                    />
                  </button>
                ))}
              </div>
              {(hovered || rating) > 0 && (
                <span className={`text-sm font-semibold ${ratingColor[hovered || rating]}`}>
                  {ratingLabel[hovered || rating]}
                </span>
              )}
            </div>

            {/* Text Input */}
            <textarea
              value={feedbackText}
              onChange={(e) => setFeedbackText(e.target.value)}
              placeholder="Tell us more about your experience (optional)…"
              rows={4}
              className="w-full rounded-2xl border border-border bg-background px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-ring resize-none text-foreground placeholder:text-muted-foreground"
            />

            <button
              onClick={submit}
              disabled={submitting || !rating}
              className="mt-4 w-full flex items-center justify-center gap-2 py-3 rounded-2xl bg-primary text-white text-sm font-semibold hover:opacity-90 active:scale-[0.98] transition-all disabled:opacity-50"
            >
              {submitting ? (
                <span className="animate-pulse">Submitting…</span>
              ) : (
                <><Send className="w-4 h-4" /> Submit Feedback</>
              )}
            </button>
          </>
        )}
      </div>

      {/* History */}
      {!loading && history.length > 0 && (
        <div className="bg-[hsl(var(--card))] rounded-3xl border border-border p-6 shadow-sm">
          <h2 className="text-lg font-semibold text-foreground mb-4" style={{ fontFamily: "var(--font-heading)" }}>
            Your Previous Feedback
          </h2>
          <div className="space-y-3">
            {history.map((f) => (
              <div key={f.Feedback_ID}
                className="flex items-start justify-between p-4 rounded-2xl bg-muted/40 border border-border/50 gap-4">
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 mb-1">
                    <div className="flex gap-0.5">
                      {[1, 2, 3, 4, 5].map((s) => (
                        <Star key={s} className={`w-3.5 h-3.5 ${s <= f.Rating ? "text-yellow-400 fill-yellow-400" : "text-border"}`} />
                      ))}
                    </div>
                    <span className={`text-xs font-semibold ${ratingColor[f.Rating]}`}>{ratingLabel[f.Rating]}</span>
                    {f.therapist_name && (
                      <span className="text-xs text-muted-foreground">· {f.therapist_name}</span>
                    )}
                  </div>
                  {(f.Comments || f.Feedback_Text) && (
                    <p className="text-sm text-foreground mt-1 leading-relaxed">{f.Comments || f.Feedback_Text}</p>
                  )}
                  <p className="text-xs text-muted-foreground mt-1.5">
                    {new Date(f.Date).toLocaleDateString("en-IN", { day: "numeric", month: "short", year: "numeric" })}
                  </p>
                </div>
                <button
                  onClick={() => deleteFeedback(f.Feedback_ID)}
                  className="p-2 rounded-xl text-muted-foreground hover:text-destructive hover:bg-destructive/10 transition shrink-0"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            ))}
          </div>
        </div>
      )}

      {toast && (
        <div className="fixed bottom-6 left-1/2 -translate-x-1/2 bg-card border border-border shadow-lg rounded-2xl px-6 py-3 text-sm text-foreground z-50 whitespace-nowrap">
          {toast}
        </div>
      )}
    </div>
  );
}
