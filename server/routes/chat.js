const express = require("express");
const router = express.Router();
const db = require("../db");

// GET all chats — auto-creates CHAT rows for every booked therapist
router.get("/", async (req, res) => {
  const { userId } = req.query;
  if (!userId) return res.status(400).json({ error: "userId required" });
  try {
    const [missing] = await db.query(
      `SELECT DISTINCT a.Therapist_ID
       FROM APPOINTMENT a
       WHERE a.User_ID = ?
         AND NOT EXISTS (
           SELECT 1 FROM CHAT c
           WHERE c.User_ID = a.User_ID AND c.Therapist_ID = a.Therapist_ID
         )`,
      [userId]
    );
    for (const row of missing) {
      try {
        await db.query("INSERT INTO CHAT (User_ID, Therapist_ID) VALUES (?, ?)", [userId, row.Therapist_ID]);
      } catch (e) { /* ignore duplicate */ }
    }

    const [rows] = await db.query(
      `SELECT c.Chat_ID, c.Therapist_ID, t.Name AS therapist_name, t.Specialization,
              (SELECT m.Message_Text FROM MESSAGE m WHERE m.Chat_ID = c.Chat_ID ORDER BY m.Message_ID DESC LIMIT 1) AS last_message
       FROM CHAT c
       JOIN THERAPIST t ON t.Therapist_ID = c.Therapist_ID
       WHERE c.User_ID = ?
       ORDER BY c.Chat_ID DESC`,
      [userId]
    );
    res.json(rows);
  } catch (err) {
    console.error("Chat list error:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// POST start a chat manually
router.post("/start", async (req, res) => {
  const { userId, therapistId } = req.body;
  try {
    const [existing] = await db.query(
      "SELECT Chat_ID FROM CHAT WHERE User_ID = ? AND Therapist_ID = ?",
      [userId, therapistId]
    );
    if (existing.length > 0) return res.json({ chatId: existing[0].Chat_ID });
    const [result] = await db.query("INSERT INTO CHAT (User_ID, Therapist_ID) VALUES (?, ?)", [userId, therapistId]);
    res.json({ chatId: result.insertId });
  } catch (err) {
    console.error("Chat start error:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// GET messages — returns Message_ID, Message_Text, Sender_Type (user/therapist)
router.get("/messages/:chatId", async (req, res) => {
  try {
    // Try fetching with Sender_Type column first
    let rows;
    try {
      [rows] = await db.query(
        `SELECT Message_ID, Message_Text,
                COALESCE(Sender_Type, 'user') AS Sender_Type
         FROM MESSAGE WHERE Chat_ID = ? ORDER BY Message_ID ASC`,
        [req.params.chatId]
      );
    } catch (e) {
      // Fallback: table may not have Sender_Type
      [rows] = await db.query(
        "SELECT Message_ID, Message_Text, 'user' AS Sender_Type FROM MESSAGE WHERE Chat_ID = ? ORDER BY Message_ID ASC",
        [req.params.chatId]
      );
    }
    res.json(rows);
  } catch (err) {
    console.error("Messages GET error:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// POST send a message — tries multiple INSERT patterns to match any schema
router.post("/messages", async (req, res) => {
  const { chatId, messageText, senderType } = req.body;
  if (!chatId || !messageText) return res.status(400).json({ error: "chatId and messageText required" });

  const now = new Date().toISOString().slice(0, 19).replace("T", " ");
  const sender = senderType || "user";
  let insertId = null;

  // Attempt 1: with Date_Time + Sender_Type
  try {
    const [r] = await db.query(
      "INSERT INTO MESSAGE (Message_Text, Chat_ID, Sender_Type, Date_Time) VALUES (?, ?, ?, ?)",
      [messageText, chatId, sender, now]
    );
    insertId = r.insertId;
  } catch (e1) {
    // Attempt 2: with Date_Time only
    try {
      const [r] = await db.query(
        "INSERT INTO MESSAGE (Message_Text, Chat_ID, Date_Time) VALUES (?, ?, ?)",
        [messageText, chatId, now]
      );
      insertId = r.insertId;
    } catch (e2) {
      // Attempt 3: with Sender_Type only
      try {
        const [r] = await db.query(
          "INSERT INTO MESSAGE (Message_Text, Chat_ID, Sender_Type) VALUES (?, ?, ?)",
          [messageText, chatId, sender]
        );
        insertId = r.insertId;
      } catch (e3) {
        // Attempt 4: bare minimum
        try {
          const [r] = await db.query(
            "INSERT INTO MESSAGE (Message_Text, Chat_ID) VALUES (?, ?)",
            [messageText, chatId]
          );
          insertId = r.insertId;
        } catch (e4) {
          console.error("All message insert attempts failed:", e4.message);
          return res.status(500).json({ error: e4.message });
        }
      }
    }
  }

  res.json({ messageId: insertId });
});

module.exports = router;
