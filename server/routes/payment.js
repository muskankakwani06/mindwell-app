const express = require("express");
const router = express.Router();
const db = require("../db");

// GET all payments for a user
router.get("/", async (req, res) => {
  const { userId } = req.query;
  if (!userId) return res.status(400).json({ error: "userId required" });
  try {
    const [rows] = await db.query(
      `SELECT p.Payment_ID, p.Amount, p.Payment_Mode, p.Status, p.Date,
              a.Date AS appointment_date, t.Name AS therapist_name
       FROM PAYMENT p
       LEFT JOIN APPOINTMENT a ON a.Appointment_ID = p.Appointment_ID
       LEFT JOIN THERAPIST t ON t.Therapist_ID = a.Therapist_ID
       WHERE p.User_ID = ?
       ORDER BY p.Payment_ID DESC`,
      [userId]
    );
    res.json(rows);
  } catch (err) {
    try {
      const [rows] = await db.query(
        "SELECT Payment_ID, Amount, Payment_Mode, Status, Date FROM PAYMENT WHERE User_ID = ? ORDER BY Payment_ID DESC",
        [userId]
      );
      res.json(rows);
    } catch (err2) {
      console.error(err2);
      res.status(500).json({ error: err2.message });
    }
  }
});

// Helper — get next Payment_ID since the table has no AUTO_INCREMENT
async function getNextPaymentId() {
  const [[row]] = await db.query("SELECT COALESCE(MAX(Payment_ID), 0) + 1 AS next_id FROM PAYMENT");
  return row.next_id;
}

// POST make a payment
router.post("/", async (req, res) => {
  const { userId, amount, paymentMode, appointmentId } = req.body;
  if (!userId || !amount || !paymentMode)
    return res.status(400).json({ error: "userId, amount and paymentMode required" });

  try {
    const today = new Date().toISOString().split("T")[0];
    const nextId = await getNextPaymentId();

    // Attempt 1: with Payment_ID + Date + Appointment_ID
    try {
      const [result] = await db.query(
        "INSERT INTO PAYMENT (Payment_ID, Amount, Payment_Mode, Status, User_ID, Date, Appointment_ID) VALUES (?, ?, ?, 'Completed', ?, ?, ?)",
        [nextId, amount, paymentMode, userId, today, appointmentId || null]
      );
      return res.json({ message: "Payment successful", paymentId: result.insertId || nextId });
    } catch (e1) {
      // Attempt 2: with Payment_ID + Date, no Appointment_ID
      try {
        const [result] = await db.query(
          "INSERT INTO PAYMENT (Payment_ID, Amount, Payment_Mode, Status, User_ID, Date) VALUES (?, ?, ?, 'Completed', ?, ?)",
          [nextId, amount, paymentMode, userId, today]
        );
        return res.json({ message: "Payment successful", paymentId: result.insertId || nextId });
      } catch (e2) {
        // Attempt 3: with Payment_ID only, no Date
        const [result] = await db.query(
          "INSERT INTO PAYMENT (Payment_ID, Amount, Payment_Mode, Status, User_ID) VALUES (?, ?, ?, 'Completed', ?)",
          [nextId, amount, paymentMode, userId]
        );
        return res.json({ message: "Payment successful", paymentId: result.insertId || nextId });
      }
    }
  } catch (err) {
    console.error("Payment insert error:", err.message);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
