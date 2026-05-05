const express = require("express");
const router  = express.Router();
const db      = require("../db");

/* ── GET all groups + joined status for this user ── */
router.get("/", async (req, res) => {
  const userId = parseInt(req.query.userId) || 0;
  try {
    const [rows] = await db.query(
      `SELECT
         sg.Group_ID,
         sg.Group_Name,
         sg.Focus_Area,
         sg.Created_Date,
         (SELECT COUNT(*) FROM GROUP_MEMBERSHIP WHERE Group_ID = sg.Group_ID)                        AS member_count,
         (SELECT COUNT(*) FROM GROUP_MEMBERSHIP WHERE Group_ID = sg.Group_ID AND User_ID = ?)        AS joined
       FROM SUPPORT_GROUP sg
       ORDER BY sg.Group_ID`,
      [userId]
    );
    res.json(rows);
  } catch (err) {
    console.error("Groups GET:", err.message);
    res.status(500).json({ error: err.message });
  }
});

/* ── POST /join ── */
router.post("/join", async (req, res) => {
  const { userId, groupId } = req.body;
  if (!userId || !groupId)
    return res.status(400).json({ error: "userId and groupId are required" });

  /* already a member? return success so UI stays green */
  try {
    const [[check]] = await db.query(
      "SELECT COUNT(*) AS n FROM GROUP_MEMBERSHIP WHERE User_ID = ? AND Group_ID = ?",
      [userId, groupId]
    );
    if (check.n > 0) return res.json({ message: "Already joined" });
  } catch (_) {}

  const today = new Date().toISOString().split("T")[0];

  /* try 3 INSERT patterns to match any schema */
  const attempts = [
    ["INSERT INTO GROUP_MEMBERSHIP (User_ID, Group_ID, Join_Date) VALUES (?,?,?)",  [userId, groupId, today]],
    ["INSERT INTO GROUP_MEMBERSHIP (User_ID, Group_ID, Joined_Date) VALUES (?,?,?)",[userId, groupId, today]],
    ["INSERT INTO GROUP_MEMBERSHIP (User_ID, Group_ID) VALUES (?,?)",               [userId, groupId]],
  ];

  for (const [sql, params] of attempts) {
    try {
      await db.query(sql, params);
      return res.json({ message: "Joined" });
    } catch (_) {}
  }

  res.status(500).json({ error: "Could not join group – check server logs" });
});

/* ── DELETE /leave ── */
router.delete("/leave", async (req, res) => {
  const { userId, groupId } = req.body;
  if (!userId || !groupId)
    return res.status(400).json({ error: "userId and groupId are required" });
  try {
    await db.query(
      "DELETE FROM GROUP_MEMBERSHIP WHERE User_ID = ? AND Group_ID = ?",
      [userId, groupId]
    );
    res.json({ message: "Left" });
  } catch (err) {
    console.error("Groups LEAVE:", err.message);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
