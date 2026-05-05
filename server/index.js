const express = require("express");
const cors = require("cors");

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json());

app.use("/api/auth", require("./routes/auth"));
app.use("/api/dashboard", require("./routes/dashboard"));
app.use("/api/therapists", require("./routes/therapists"));
app.use("/api/appointments", require("./routes/appointments"));
app.use("/api/assessments", require("./routes/assessments"));
app.use("/api/groups", require("./routes/groups"));
app.use("/api/chat", require("./routes/chat"));
app.use("/api/feedback", require("./routes/feedback"));
app.use("/api/payment", require("./routes/payment"));

app.listen(PORT, () => {
  console.log(`✅ MindWell API running at http://localhost:${PORT}`);
});
