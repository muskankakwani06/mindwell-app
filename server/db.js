const mysql = require("mysql2/promise");

const DB_HOST     = process.env.DB_HOST     || "localhost";
const DB_USER     = process.env.DB_USER     || "root";
const DB_PASSWORD = process.env.DB_PASSWORD || "Billabong@123";   
const DB_NAME     = process.env.DB_NAME     || "mental_health";

const pool = mysql.createPool({
  host: DB_HOST,
  user: DB_USER,
  password: DB_PASSWORD,
  database: DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
});

pool.getConnection()
  .then(conn => { console.log(`✅ MySQL connected → ${DB_NAME}@${DB_HOST}`); conn.release(); })
  .catch(err => { console.error("❌ MySQL connection FAILED:", err.message); process.exit(1); });

module.exports = pool;
