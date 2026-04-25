import { useState, useEffect } from "react";
import { Brain, CheckCircle } from "lucide-react";
import { useAuth } from "../context/AuthContext";

const TESTS = {
  "Depression Test": {
    desc: "PHQ-9 — Patient Health Questionnaire",
    questions: [
      "Little interest or pleasure in doing things",
      "Feeling down, depressed, or hopeless",
      "Trouble falling or staying asleep, or sleeping too much",
      "Feeling tired or having little energy",
      "Poor appetite or overeating",
      "Feeling bad about yourself — or feeling like a failure",
      "Trouble concentrating on things",
      "Moving or speaking so slowly that other people could have noticed",
      "Thoughts that you would be better off dead, or thoughts of hurting yourself",
    ],
    score: (total) => {
      if (total <= 4)  return "Minimal Depression";
      if (total <= 9)  return "Mild Depression";
      if (total <= 14) return "Moderate Depression";
      if (total <= 19) return "Moderately Severe Depression";
      return "Severe Depression";
    },
  },
  "Stress Test": {
    desc: "PSS-10 — Perceived Stress Scale",
    questions: [
      "Been upset because of something that happened unexpectedly?",
      "Felt unable to control important things in your life?",
      "Felt nervous and stressed?",
      "Felt confident about your ability to handle your personal problems?",
      "Felt that things were going your way?",
      "Found that you could not cope with all the things that you had to do?",
      "Been able to control irritations in your life?",
      "Felt that you were on top of things?",
      "Been angered because of things that were outside of your control?",
      "Felt difficulties were piling up so high that you could not overcome them?",
    ],
    score: (total) => {
      if (total <= 13) return "Low Stress";
      if (total <= 26) return "Moderate Stress";
      return "High Stress";
    },
  },
  "Anxiety Test": {
    desc: "GAD-7 — Generalized Anxiety Disorder Scale",
    questions: [
      "Feeling nervous, anxious, or on edge",
      "Not being able to stop or control worrying",
      "Worrying too much about different things",
      "Trouble relaxing",
      "Being so restless that it's hard to sit still",
      "Becoming easily annoyed or irritable",
      "Feeling afraid as if something awful might happen",
    ],
    score: (total) => {
      if (total <= 4)  return "Minimal Anxiety";
      if (total <= 9)  return "Mild Anxiety";
      if (total <= 14) return "Moderate Anxiety";
      return "Severe Anxiety";
    },
  },
};

const OPTIONS = ["Not at all", "Several days", "More than half the days", "Nearly every day"];

export default function Assessment() {
  const { user } = useAuth();
  const [selected, setSelected] = useState(null);
  const [answers, setAnswers] = useState([]);
  const [result, setResult] = useState(null);
  const [saving, setSaving] = useState(false);
  const [history, setHistory] = useState([]);
  const [toast, setToast] = useState("");

  useEffect(() => {
    fetch(`/api/assessments?userId=${user.userId}`)
      .then((r) => r.json())
      .then((d) => setHistory(Array.isArray(d) ? d : []))
      .catch(() => {});
  }, [user]);

  const showToast = (msg) => { setToast(msg); setTimeout(() => setToast(""), 3000); };

  const startTest = (name) => {
    setSelected(name);
    setAnswers(new Array(TESTS[name].questions.length).fill(null));
    setResult(null);
  };

  const setAnswer = (i, val) => {
    const copy = [...answers];
    copy[i] = val;
    setAnswers(copy);
  };

  const submit = async () => {
    if (answers.some((a) => a === null)) { showToast("Please answer all questions"); return; }
    const total = answers.reduce((s, a) => s + a, 0);
    const remarks = TESTS[selected].score(total);
    setResult({ total, remarks });
    setSaving(true);
    try {
      await fetch("/api/assessments", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ userId: user.userId, assessmentType: selected, remarks }),
      });
      const d = await fetch(`/api/assessments?userId=${user.userId}`).then((r) => r.json());
      setHistory(Array.isArray(d) ? d : []);
    } catch {}
    setSaving(false);
  };

  const reset = () => { setSelected(null); setResult(null); setAnswers([]); };

  return (
    <div className="container mx-auto py-8 px-4 space-y-8">
      <div>
        <h1 className="text-3xl text-foreground" style={{ fontFamily: "var(--font-heading)" }}>Mental Health Assessment</h1>
        <p className="text-muted-foreground mt-1">Self-assessment tools to understand your wellbeing</p>
      </div>

      {!selected && !result && (
        <>
          <div className="grid md:grid-cols-3 gap-6">
            {Object.entries(TESTS).map(([name, t]) => (
              <button key={name} onClick={() => startTest(name)}
                className="bg-[hsl(var(--card))] rounded-2xl border border-border p-6 text-left hover:shadow-lg hover:border-primary/30 transition-all group">
                <div className="p-3 rounded-xl bg-primary/10 w-fit mb-4 group-hover:bg-primary/20 transition">
                  <Brain className="w-6 h-6 text-primary" />
                </div>
                <h3 className="font-medium text-foreground mb-1" style={{ fontFamily: "var(--font-heading)" }}>{name}</h3>
                <p className="text-sm text-muted-foreground">{t.desc}</p>
                <p className="text-xs text-primary mt-3 font-medium">{t.questions.length} questions →</p>
              </button>
            ))}
          </div>

          {history.length > 0 && (
            <div className="bg-[hsl(var(--card))] rounded-2xl border border-border p-6">
              <h2 className="text-lg text-foreground mb-4" style={{ fontFamily: "var(--font-heading)" }}>Your History</h2>
              <div className="space-y-3">
                {history.map((h) => (
                  <div key={h.Assessment_ID} className="flex items-center justify-between p-3 rounded-xl bg-[hsl(var(--muted))]/50">
                    <div>
                      <p className="text-sm font-medium text-foreground">{h.Assessment_Type}</p>
                      <p className="text-xs text-muted-foreground">{h.Remarks || "—"}</p>
                    </div>
                    <p className="text-xs text-muted-foreground">
                      {new Date(h.Date).toLocaleDateString("en-IN", { day: "numeric", month: "short", year: "numeric" })}
                    </p>
                  </div>
                ))}
              </div>
            </div>
          )}
        </>
      )}

      {selected && !result && (
        <div className="bg-[hsl(var(--card))] rounded-2xl border border-border p-6 max-w-2xl mx-auto">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h2 className="text-xl text-foreground" style={{ fontFamily: "var(--font-heading)" }}>{selected}</h2>
              <p className="text-sm text-muted-foreground">{TESTS[selected].desc}</p>
            </div>
            <button onClick={reset} className="text-sm text-muted-foreground hover:text-foreground underline">Cancel</button>
          </div>

          <p className="text-sm text-muted-foreground mb-6 p-3 rounded-xl bg-[hsl(var(--muted))]/50">
            Over the last 2 weeks, how often have you been bothered by the following?
          </p>

          <div className="space-y-6">
            {TESTS[selected].questions.map((q, i) => (
              <div key={i}>
                <p className="text-sm font-medium text-foreground mb-3">{i + 1}. {q}</p>
                <div className="grid grid-cols-2 md:grid-cols-4 gap-2">
                  {OPTIONS.map((opt, val) => (
                    <button key={opt} onClick={() => setAnswer(i, val)}
                      className={`py-2 px-2 rounded-xl text-xs font-medium border transition text-center ${
                        answers[i] === val
                          ? "bg-primary text-[hsl(var(--primary-foreground))] border-primary"
                          : "border-border text-foreground hover:bg-[hsl(var(--muted))]"
                      }`}>
                      {opt}
                    </button>
                  ))}
                </div>
              </div>
            ))}
          </div>

          <button onClick={submit} disabled={saving}
            className="w-full mt-8 py-3 rounded-xl bg-primary text-[hsl(var(--primary-foreground))] text-sm font-medium hover:opacity-90 transition disabled:opacity-60">
            {saving ? "Saving..." : "Submit Assessment"}
          </button>
        </div>
      )}

      {result && (
        <div className="max-w-md mx-auto text-center">
          <div className="bg-[hsl(var(--card))] rounded-2xl border border-border p-8">
            <div className="w-16 h-16 rounded-full bg-primary/10 flex items-center justify-center mx-auto mb-4">
              <CheckCircle className="w-8 h-8 text-primary" />
            </div>
            <h2 className="text-2xl text-foreground mb-2" style={{ fontFamily: "var(--font-heading)" }}>Assessment Complete</h2>
            <p className="text-muted-foreground text-sm mb-6">Your {selected} result</p>
            <div className="p-4 rounded-xl bg-primary/5 border border-primary/20 mb-6">
              <p className="text-3xl font-bold text-primary mb-1">{result.total}</p>
              <p className="text-sm text-muted-foreground">Total Score</p>
              <p className="text-lg font-medium text-foreground mt-2">{result.remarks}</p>
            </div>
            <p className="text-xs text-muted-foreground mb-6">Results saved to your profile. Please consult a professional for clinical diagnosis.</p>
            <button onClick={reset}
              className="w-full py-2.5 rounded-xl bg-primary text-[hsl(var(--primary-foreground))] text-sm font-medium hover:opacity-90 transition">
              Take Another Assessment
            </button>
          </div>
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
