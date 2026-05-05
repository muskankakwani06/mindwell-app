const express = require("express");
const router = express.Router();
const db = require("../db");

router.get("/", async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT t.Therapist_ID, t.Name, t.Phone, t.Specialization,
              ROUND(AVG(f.Rating), 1) AS avg_rating,
              COUNT(f.Feedback_ID) AS review_count
       FROM THERAPIST t
       LEFT JOIN FEEDBACK f ON f.Therapist_ID = t.Therapist_ID
       GROUP BY t.Therapist_ID`
    );
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
