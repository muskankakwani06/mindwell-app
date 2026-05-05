const express = require("express");
const router = express.Router();
const db = require("../db");

const safeCount = async (query, params) => {
  try {
    const [[row]] = await db.query(query, params);
    return Object.values(row)[0] ?? 0;
  } catch (e) {
    console.error("Dashboard query error:", e.message);
    return 0;
  }
};

router.get("/", async (req, res) => {
  const userId = req.query.userId;
  if (!userId) return res.status(400).json({ error: "userId required" });
  try {
    const [sessions, assessments, groups, upcoming, payments] = await Promise.all([
      safeCount("SELECT COUNT(*) AS n FROM SESSION WHERE User_ID = ?", [userId]),
      safeCount("SELECT COUNT(*) AS n FROM MENTAL_ASSESSMENT WHERE User_ID = ?", [userId]),
      safeCount("SELECT COUNT(*) AS n FROM GROUP_MEMBERSHIP WHERE User_ID = ?", [userId]),
      safeCount("SELECT COUNT(*) AS n FROM APPOINTMENT WHERE User_ID = ? AND Date >= CURDATE()", [userId]),
      safeCount("SELECT COUNT(*) AS n FROM PAYMENT WHERE User_ID = ?", [userId]),
    ]);

    let upcomingAppointments = [], recentAssessments = [], recentPayments = [];

    try {
      const [rows] = await db.query(
        `SELECT a.Appointment_ID, a.Date, a.Time, t.Name AS therapist_name, t.Specialization
         FROM APPOINTMENT a JOIN THERAPIST t ON a.Therapist_ID = t.Therapist_ID
         WHERE a.User_ID = ? AND a.Date >= CURDATE()
         ORDER BY a.Date ASC, a.Time ASC LIMIT 3`,
        [userId]
      );
      upcomingAppointments = rows;
    } catch (e) { console.error(e.message); }

    try {
      const [rows] = await db.query(
        `SELECT ma.Assessment_ID, ma.Assessment_Type, ma.Date, ar.Remarks
         FROM MENTAL_ASSESSMENT ma
         LEFT JOIN ASSESSMENT_RESULT ar ON ar.Assessment_ID = ma.Assessment_ID
         WHERE ma.User_ID = ? ORDER BY ma.Date DESC LIMIT 5`,
        [userId]
      );
      recentAssessments = rows;
    } catch (e) { console.error(e.message); }

    try {
      const [rows] = await db.query(
        `SELECT Payment_ID, Amount, Payment_Mode, Status, Date
         FROM PAYMENT WHERE User_ID = ? ORDER BY Payment_ID DESC LIMIT 3`,
        [userId]
      );
      recentPayments = rows;
    } catch (e) { console.error(e.message); }

    res.json({
      stats: { sessions, assessments, groups, upcoming, payments },
      upcomingAppointments,
      recentAssessments,
      recentPayments,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
