const express = require("express");
const router = express.Router();
const db = require("../db");

// SIGNUP — insert into USER (Name, Email, Phone)
router.post("/register", async (req, res) => {
  const { name, email, phone } = req.body;
  if (!name || !email) return res.status(400).json({ error: "Name and email are required" });
  try {
    const [existing] = await db.query("SELECT User_ID FROM USER WHERE Email = ?", [email]);
    if (existing.length > 0) return res.status(400).json({ error: "Email already registered" });
    const [result] = await db.query(
      "INSERT INTO USER (Name, Email, Phone) VALUES (?, ?, ?)",
      [name, email, phone || null]
    );
    res.json({ message: "Account created", user: { userId: result.insertId, name, email } });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Registration failed: " + err.message });
  }
});

// LOGIN — lookup by email (no password)
router.post("/login", async (req, res) => {
  let { email } = req.body;
  if (!email) return res.status(400).json({ error: "Email is required" });
  email = email.trim();
  try {
    const [rows] = await db.query(
      "SELECT User_ID, Name, Email, Phone FROM USER WHERE TRIM(Email) = ?",
      [email]
    );
    if (rows.length === 0) return res.status(401).json({ error: "No account found with that email" });
    const u = rows[0];
    res.json({ message: "Login successful", user: { userId: u.User_ID, name: u.Name, email: u.Email, phone: u.Phone } });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Login failed: " + err.message });
  }
});

// UPDATE — update Name and Email
router.post("/update", async (req, res) => {
  const { userId, name, email } = req.body;
  if (!userId || !name || !email) return res.status(400).json({ error: "userId, name, and email are required" });
  try {
    await db.query("UPDATE USER SET Name = ?, Email = ? WHERE User_ID = ?", [name, email, userId]);
    res.json({ message: "Profile updated" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Update failed: " + err.message });
  }
});

module.exports = router;
