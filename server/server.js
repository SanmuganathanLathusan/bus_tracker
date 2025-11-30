// server.js
require('dotenv').config(); // load env first
const express = require("express");
const cors = require("cors");
const path = require("path");
const fs = require("fs");
const connectDB = require("./config/db");
const { initializeFirebase } = require("./config/firebase");
const paymentRoutes = require('./routes/paymentRoutes');

// --- Quick environment checks (safe: prints length only) ---
const stripeKey = process.env.STRIPE_SECRET_KEY || process.env.STRIPE_SECTER_KEY; // support legacy typo while migrating
if (stripeKey && process.env.STRIPE_SECTER_KEY) {
  console.warn('⚠️  Found STRIPE_SECTER_KEY (typo). Please rename to STRIPE_SECRET_KEY in your .env');
}
console.log('STRIPE key present:', stripeKey ? `yes (length ${stripeKey.length})` : 'NO');

// Optional: fail-fast in dev if Stripe is required
if (process.env.NODE_ENV !== 'production' && !stripeKey) {
  console.warn('⚠️  STRIPE_SECRET_KEY is not set. Payment endpoints will fail until it is configured in auth_backend/.env');
  // Uncomment the next line if you want the server to exit when missing:
  // process.exit(1);
}

// If you use stripe on server:
let stripe = null;
if (stripeKey) {
  try {
    const Stripe = require('stripe');
    stripe = new Stripe(stripeKey, { apiVersion: '2022-11-15' });
  } catch (err) {
    console.error('Failed to initialize Stripe:', err);
  }
}

// --- Connect to DB ---
connectDB();

// --- Initialize Firebase ---
initializeFirebase();

// --- App setup ---
const app = express();

// Create uploads directories if they don't exist
const uploadDirs = ["uploads/profiles", "uploads/maintenance"];
uploadDirs.forEach(dir => {
  const dirPath = path.join(__dirname, dir);
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
});

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static files from uploads
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

// Routes
app.use("/api/auth", require("./routes/auth"));
app.use("/api/dashboard", require("./routes/dashboard"));
app.use("/api/news", require("./routes/newsRoutes"));
app.use("/api/routes", require("./routes/routeRoutes"));
app.use("/api/reservations", require("./routes/reservationRoutes"));
app.use("/api/payments", paymentRoutes); // ensure paymentRoutes uses `stripe` from require or local import
app.use("/api/bus", require("./routes/bus"));
app.use("/api/driver", require("./routes/driverRoutes"));
app.use("/api/maintenance", require("./routes/maintenanceRoutes"));
app.use("/api/feedback", require("./routes/feedbackRoutes"));
app.use("/api/notifications", require("./routes/notificationRoutes"));
app.use("/api/admin", require("./routes/adminRoutes"));
app.use("/api/pricing", require("./routes/pricingRoutes"));
app.use("/api/fcm", require("./routes/fcmRoutes"));

// Health check
app.get("/api/health", (req, res) => {
  res.json({ status: "OK", message: "Server is running" });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, '0.0.0.0', () => console.log(`🚀 Server running on port ${PORT}`));

// Export stripe if other modules need it
module.exports = { stripe };
