const express = require("express");
const router = express.Router();
const db = require("../db");

// GET assessments for user with results
router.get("/", async (req, res) => {
  const { userId } = req.query;
  if (!userId) return res.status(400).json({ error: "userId required" });
  try {
    const [rows] = await db.query(
      `SELECT ma.Assessment_ID, ma.Assessment_Type, ma.Date, ar.Result_ID, ar.Remarks
       FROM MENTAL_ASSESSMENT ma
       LEFT JOIN ASSESSMENT_RESULT ar ON ar.Assessment_ID = ma.Assessment_ID
       WHERE ma.User_ID = ?
       ORDER BY ma.Date DESC`,
      [userId]
    );
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// POST save a new assessment + result
router.post("/", async (req, res) => {
  const { userId, assessmentType, remarks } = req.body;
  if (!userId || !assessmentType) return res.status(400).json({ error: "userId and assessmentType required" });
  try {
    const today = new Date().toISOString().split("T")[0];
    const [aRes] = await db.query(
      "INSERT INTO MENTAL_ASSESSMENT (Assessment_Type, Date, User_ID) VALUES (?, ?, ?)",
      [assessmentType, today, userId]
    );
    const assessmentId = aRes.insertId;
    if (remarks) {
      await db.query(
        "INSERT INTO ASSESSMENT_RESULT (Remarks, Assessment_ID) VALUES (?, ?)",
        [remarks, assessmentId]
      );
    }
    res.json({ message: "Assessment saved", assessmentId });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
