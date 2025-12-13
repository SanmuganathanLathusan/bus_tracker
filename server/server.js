// server.js
require('dotenv').config(); // load env first
const express = require("express");
const cors = require("cors");
const path = require("path");
const fs = require("fs");
const http = require("http");              // 👈 NEW: for HTTP server
const { Server } = require("socket.io");   // 👈 NEW: Socket.IO
const connectDB = require("./config/db");
const { initializeFirebase } = require("./config/firebase");
const paymentRoutes = require('./routes/paymentRoutes');

// --- Quick environment checks (safe: prints length only) ---
const stripeKey = process.env.STRIPE_SECRET_KEY || process.env.STRIPE_SECTER_KEY; // support legacy typo while migrating
if (stripeKey && process.env.STRIPE_SECTER_KEY) {
  console.warn('⚠️  Found STRIPE_SECTER_KEY (typo). Please rename to STRIPE_SECRET_KEY in your .env');
}
console.log('STRIPE key present:', stripeKey ? `yes (length ${stripeKey.length})` : 'NO');

if (process.env.NODE_ENV !== 'production' && !stripeKey) {
  console.warn('⚠️  STRIPE_SECRET_KEY is not set. Payment endpoints will fail until it is configured in auth_backend/.env');
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
app.use("/api/payments", paymentRoutes);
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

// --- HTTP server + Socket.IO ---
const PORT = process.env.PORT || 5000;

// 👇 Create HTTP server from Express app
const server = http.createServer(app);

// 👇 Attach Socket.IO to same server/port
const io = new Server(server, {
  cors: {
    origin: "*",               // for dev; lock down in prod
    methods: ["GET", "POST"],
  },
});

// Simple in-memory store for bus locations
const busLocations = {}; // { [busId]: { lat, lng } }

// Socket.IO handlers
io.on("connection", (socket) => {
  console.log("✅ Socket client connected:", socket.id);

  // Flutter emits this right after connect:
  // _socket?.emit('requestBusLocations');
  socket.on("requestBusLocations", () => {
    console.log("📡 requestBusLocations from", socket.id);
    // Send current known bus locations to this client
    socket.emit("busLocations", busLocations);
  });

  // If you later send live updates from driver app/backend, handle here:
  // expected payload: { busId: '...', location: { lat: 6.9, lng: 79.8 } }
  socket.on("busLocationUpdate", (data) => {
    try {
      if (
        data &&
        data.busId &&
        data.location &&
        typeof data.location.lat === "number" &&
        typeof data.location.lng === "number"
      ) {
        busLocations[data.busId] = {
          lat: data.location.lat,
          lng: data.location.lng,
        };

        console.log("🚌 Bus location update:", data.busId, data.location);

        // Broadcast to all *other* clients
        socket.broadcast.emit("busLocationUpdate", data);
      } else {
        console.warn("⚠️ Invalid busLocationUpdate payload:", data);
      }
    } catch (err) {
      console.error("Error handling busLocationUpdate:", err);
    }
  });

  socket.on("disconnect", () => {
    console.log("❌ Socket client disconnected:", socket.id);
  });
});

// Start server with Socket.IO, NOT app.listen
server.listen(PORT, "0.0.0.0", () =>
  console.log(`🚀 Server running on http://0.0.0.0:${PORT}`)
);

// Export stripe & io if other modules need them
module.exports = { stripe, io };
