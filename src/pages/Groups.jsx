import { useEffect, useState } from "react";
import { Users, Calendar, CheckCircle } from "lucide-react";
import { useAuth } from "../context/AuthContext";
import { db } from "../lib/firebase";
import { collection, onSnapshot, updateDoc, doc, arrayUnion, arrayRemove } from "firebase/firestore";

const FOCUS_COLORS = {
  Stress:      "bg-blue-100 text-blue-700",
  Anxiety:     "bg-purple-100 text-purple-700",
  Depression:  "bg-rose-100 text-rose-700",
  Mindfulness: "bg-green-100 text-green-700",
};

export default function Groups() {
  const { user } = useAuth();
  const [groups,         setGroups]         = useState([]);
  const [loading,        setLoading]        = useState(true);
  const [actionId,       setActionId]       = useState(null);
  const [joinedIds,      setJoinedIds]      = useState(new Set());

  useEffect(() => {
    if (!user?.uid) return;
    const unsubscribe = onSnapshot(collection(db, "groups"), (snap) => {
      const arr = snap.docs.map(d => ({ 
        Group_ID: d.id, 
        ...d.data(),
        member_count: d.data().members?.length || 0,
        joined: d.data().members?.includes(user.uid) ? 1 : 0
      }));
      setGroups(arr);
      setJoinedIds(new Set(arr.filter(g => g.joined).map(g => g.Group_ID)));
      setLoading(false);
    });
    return () => unsubscribe();
  }, [user?.uid]);

  const handleJoin = async (groupId) => {
    setActionId(groupId);
    try {
      await updateDoc(doc(db, "groups", groupId), {
        members: arrayUnion(user.uid)
      });
      window.dispatchEvent(new CustomEvent("groups-changed"));
    } catch (err) {
      console.error("Error joining group:", err);
    }
    setActionId(null);
  };

  const handleLeave = async (groupId) => {
    setActionId(groupId);
    try {
      await updateDoc(doc(db, "groups", groupId), {
        members: arrayRemove(user.uid)
      });
      window.dispatchEvent(new CustomEvent("groups-changed"));
    } catch (err) {
      console.error("Error leaving group:", err);
    }
    setActionId(null);
  };

  /* ── loading ── */
  if (loading) return (
    <div className="container mx-auto py-8 px-4 flex items-center justify-center min-h-[60vh]">
      <div className="text-muted-foreground animate-pulse text-sm">Loading groups…</div>
    </div>
  );

  const myGroups    = groups.filter(g =>  joinedIds.has(g.Group_ID));
  const otherGroups = groups.filter(g => !joinedIds.has(g.Group_ID));

  return (
    <div className="container mx-auto py-8 px-4 space-y-8">

      {/* ── Page title ── */}
      <div>
        <h1 className="text-3xl text-foreground" style={{ fontFamily: "var(--font-heading)" }}>
          Support Groups
        </h1>
        <p className="text-muted-foreground text-sm mt-1">Connect with others on a similar journey</p>
      </div>

      {/* ── YOUR GROUPS ── */}
      {myGroups.length > 0 && (
        <section>
          <div className="flex items-center gap-2 mb-4">
            <h2 className="text-lg font-semibold text-foreground" style={{ fontFamily: "var(--font-heading)" }}>
              Your Groups
            </h2>
            <span className="px-2.5 py-0.5 rounded-full bg-primary/10 text-primary text-xs font-bold">
              {myGroups.length}
            </span>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
            {myGroups.map(g => (
              <div
                key={g.Group_ID}
                className="bg-card rounded-2xl border border-primary/30 p-5 shadow-sm relative"
              >
                {/* green tick top-right */}
                <CheckCircle className="absolute top-3 right-3 w-4 h-4 text-primary" />

                {/* icon + name */}
                <div className="flex items-start gap-3 mb-3">
                  <div className="p-2.5 rounded-xl bg-primary/10 shrink-0">
                    <Users className="w-5 h-5 text-primary" />
                  </div>
                  <div className="min-w-0 pr-6">
                    <h3 className="font-semibold text-foreground text-sm leading-tight"
                        style={{ fontFamily: "var(--font-heading)" }}>
                      {g.Group_Name}
                    </h3>
                    <span className={`inline-block mt-1 text-[10px] font-semibold px-2 py-0.5 rounded-full
                      ${FOCUS_COLORS[g.Focus_Area] || "bg-gray-100 text-gray-600"}`}>
                      {g.Focus_Area}
                    </span>
                  </div>
                </div>

                {/* meta */}
                <div className="flex items-center gap-3 text-xs text-muted-foreground mb-4">
                  <span className="flex items-center gap-1">
                    <Users className="w-3 h-3" /> {g.member_count} members
                  </span>
                  {g.Created_Date && (
                    <span className="flex items-center gap-1">
                      <Calendar className="w-3 h-3" />
                      {new Date(g.Created_Date).toLocaleDateString("en-IN", { month: "short", year: "numeric" })}
                    </span>
                  )}
                </div>

                {/* ✅ JOINED badge */}
                <div className="w-full py-2 rounded-xl text-xs font-semibold
                                flex items-center justify-center gap-1.5
                                bg-green-50 text-green-700 border border-green-200 mb-2">
                  <CheckCircle className="w-3.5 h-3.5" />
                  Joined
                </div>

                {/* Leave button */}
                <button
                  onClick={() => handleLeave(g.Group_ID)}
                  disabled={actionId === g.Group_ID}
                  className="w-full py-2 rounded-xl text-xs font-semibold border border-border
                             text-muted-foreground hover:bg-red-50 hover:text-red-600
                             hover:border-red-200 transition disabled:opacity-50"
                >
                  {actionId === g.Group_ID ? "Leaving…" : "Leave Group"}
                </button>
              </div>
            ))}
          </div>
        </section>
      )}

      {/* ── AVAILABLE GROUPS ── */}
      {otherGroups.length > 0 && (
        <section>
          <h2 className="text-lg font-semibold text-foreground mb-4"
              style={{ fontFamily: "var(--font-heading)" }}>
            Available Groups
          </h2>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
            {otherGroups.map(g => (
              <div
                key={g.Group_ID}
                className="bg-card rounded-2xl border border-border p-5
                           hover:shadow-md hover:border-primary/20 transition-all"
              >
                {/* icon + name */}
                <div className="flex items-start gap-3 mb-3">
                  <div className="p-2.5 rounded-xl bg-muted shrink-0">
                    <Users className="w-5 h-5 text-muted-foreground" />
                  </div>
                  <div className="min-w-0">
                    <h3 className="font-semibold text-foreground text-sm leading-tight"
                        style={{ fontFamily: "var(--font-heading)" }}>
                      {g.Group_Name}
                    </h3>
                    <span className={`inline-block mt-1 text-[10px] font-semibold px-2 py-0.5 rounded-full
                      ${FOCUS_COLORS[g.Focus_Area] || "bg-gray-100 text-gray-600"}`}>
                      {g.Focus_Area}
                    </span>
                  </div>
                </div>

                {/* meta */}
                <div className="flex items-center gap-3 text-xs text-muted-foreground mb-4">
                  <span className="flex items-center gap-1">
                    <Users className="w-3 h-3" /> {g.member_count} members
                  </span>
                  {g.Created_Date && (
                    <span className="flex items-center gap-1">
                      <Calendar className="w-3 h-3" />
                      {new Date(g.Created_Date).toLocaleDateString("en-IN", { month: "short", year: "numeric" })}
                    </span>
                  )}
                </div>

                {/* Join button */}
                <button
                  onClick={() => handleJoin(g.Group_ID)}
                  disabled={actionId === g.Group_ID}
                  className="w-full py-2 rounded-xl text-xs font-semibold
                             bg-primary text-white hover:opacity-90 transition disabled:opacity-50"
                >
                  {actionId === g.Group_ID ? "Joining…" : "Join Group"}
                </button>
              </div>
            ))}
          </div>
        </section>
      )}

      {/* ── empty ── */}
      {groups.length === 0 && (
        <div className="text-center py-16 bg-card rounded-2xl border border-border">
          <Users className="w-12 h-12 text-muted-foreground mx-auto mb-3" />
          <p className="text-muted-foreground text-sm">No support groups found.</p>
        </div>
      )}
    </div>
  );
}
