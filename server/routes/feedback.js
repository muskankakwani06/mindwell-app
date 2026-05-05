const express = require("express");
const router  = express.Router();
const db      = require("../db");

/* ── GET feedback history for a user ── */
router.get("/", async (req, res) => {
  const { userId } = req.query;
  if (!userId) return res.status(400).json({ error: "userId required" });
  try {
    const [rows] = await db.query(
      `SELECT f.Feedback_ID, f.Rating, f.Comments, f.Date,
              t.Name AS therapist_name, t.Specialization
       FROM FEEDBACK f
       LEFT JOIN THERAPIST t ON t.Therapist_ID = f.Therapist_ID
       WHERE f.User_ID = ?
       ORDER BY f.Feedback_ID DESC`,
      [userId]
    );
    res.json(rows);
  } catch (err) {
    try {
      const [rows] = await db.query(
        "SELECT Feedback_ID, Rating, Comments, Date FROM FEEDBACK WHERE User_ID = ? ORDER BY Feedback_ID DESC",
        [userId]
      );
      res.json(rows);
    } catch (err2) {
      console.error(err2);
      res.status(500).json({ error: err2.message });
    }
  }
});

/* ── POST submit feedback ── */
router.post("/", async (req, res) => {
  const { userId, rating, feedbackText, therapistId } = req.body;
  if (!userId || !rating) return res.status(400).json({ error: "userId and rating required" });

  const today = new Date().toISOString().split("T")[0];
  const text  = feedbackText || null;
  const tId   = therapistId  || null;

  // Attempt 1 — with Therapist_ID (nullable)
  try {
    const [r] = await db.query(
      "INSERT INTO FEEDBACK (User_ID, Rating, Comments, Date, Therapist_ID) VALUES (?,?,?,?,?)",
      [userId, rating, text, today, tId]
    );
    return res.json({ message: "Feedback submitted", feedbackId: r.insertId });
  } catch (e1) {
    // Attempt 2 — without Therapist_ID column
    try {
      const [r] = await db.query(
        "INSERT INTO FEEDBACK (User_ID, Rating, Comments, Date) VALUES (?,?,?,?)",
        [userId, rating, text, today]
      );
      return res.json({ message: "Feedback submitted", feedbackId: r.insertId });
    } catch (e2) {
      // Attempt 3 — manual ID (if AUTO_INCREMENT still missing)
      try {
        const [[row]] = await db.query("SELECT COALESCE(MAX(Feedback_ID),0)+1 AS n FROM FEEDBACK");
        const nextId  = row.n;
        try {
          const [r] = await db.query(
            "INSERT INTO FEEDBACK (Feedback_ID, User_ID, Rating, Comments, Date, Therapist_ID) VALUES (?,?,?,?,?,?)",
            [nextId, userId, rating, text, today, tId]
          );
          return res.json({ message: "Feedback submitted", feedbackId: r.insertId || nextId });
        } catch (e3) {
          const [r] = await db.query(
            "INSERT INTO FEEDBACK (Feedback_ID, User_ID, Rating, Comments, Date) VALUES (?,?,?,?,?)",
            [nextId, userId, rating, text, today]
          );
          return res.json({ message: "Feedback submitted", feedbackId: r.insertId || nextId });
        }
      } catch (e4) {
        console.error("All feedback inserts failed:", e4.message);
        return res.status(500).json({ error: e4.message });
      }
    }
  }
});

/* ── DELETE feedback ── */
router.delete("/:id", async (req, res) => {
  try {
    await db.query("DELETE FROM FEEDBACK WHERE Feedback_ID = ?", [req.params.id]);
    res.json({ message: "Deleted" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
