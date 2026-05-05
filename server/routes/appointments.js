const express = require("express");
const router = express.Router();
const db = require("../db");

// GET all appointments for a user
router.get("/", async (req, res) => {
  const { userId } = req.query;
  if (!userId) return res.status(400).json({ error: "userId required" });
  try {
    const [rows] = await db.query(
      `SELECT a.Appointment_ID, a.Date, a.Time,
              t.Name AS therapist_name, t.Specialization, t.Phone AS therapist_phone
       FROM APPOINTMENT a
       JOIN THERAPIST t ON a.Therapist_ID = t.Therapist_ID
       WHERE a.User_ID = ?
       ORDER BY a.Date DESC, a.Time DESC`,
      [userId]
    );
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// POST book appointment — also creates a SESSION + CHAT automatically
router.post("/", async (req, res) => {
  const { date, time, userId, therapistId } = req.body;
  if (!date || !time || !userId || !therapistId)
    return res.status(400).json({ error: "date, time, userId and therapistId are required" });
  try {
    // 1. Create appointment
    const [apptResult] = await db.query(
      "INSERT INTO APPOINTMENT (Date, Time, User_ID, Therapist_ID) VALUES (?, ?, ?, ?)",
      [date, time, userId, therapistId]
    );
    const appointmentId = apptResult.insertId;

    // 2. Auto-create a SESSION for this appointment (default 60 min)
    try {
      await db.query(
        "INSERT INTO SESSION (Session_Date, Duration, User_ID, Therapist_ID) VALUES (?, ?, ?, ?)",
        [date, 60, userId, therapistId]
      );
    } catch (sessionErr) {
      console.warn("Session auto-create skipped:", sessionErr.message);
    }

    // 3. Auto-create a CHAT thread if one doesn't exist
    try {
      const [existingChat] = await db.query(
        "SELECT Chat_ID FROM CHAT WHERE User_ID = ? AND Therapist_ID = ?",
        [userId, therapistId]
      );
      if (existingChat.length === 0) {
        await db.query(
          "INSERT INTO CHAT (User_ID, Therapist_ID) VALUES (?, ?)",
          [userId, therapistId]
        );
      }
    } catch (chatErr) {
      console.warn("Chat auto-create skipped:", chatErr.message);
    }

    res.json({ message: "Appointment booked", appointmentId });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// DELETE cancel appointment
router.delete("/:id", async (req, res) => {
  try {
    await db.query("DELETE FROM APPOINTMENT WHERE Appointment_ID = ?", [req.params.id]);
    res.json({ message: "Appointment cancelled" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
