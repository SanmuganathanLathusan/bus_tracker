const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const http = require("http");
const { Server } = require("socket.io");

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*", // allow all clients (Flutter)
  },
});

app.use(cors());
app.use(express.json());

// MongoDB connection
mongoose.connect("mongodb://localhost:27017/bus_tracker_db", {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
  .then(() => console.log("MongoDB connected"))
  .catch((err) => console.log("MongoDB connection error:", err));

// === SOCKET.IO FOR REAL-TIME UPDATES ===
let busLocations = {}; // { busId: { lat, lng } }

io.on("connection", (socket) => {
  console.log("Bus/Client connected:", socket.id);

  // Listen for bus location updates from driver app
  socket.on("updateLocation", (data) => {
    const { busId, lat, lng } = data;
    busLocations[busId] = { lat, lng };

    // Broadcast to all clients (passenger apps)
    io.emit("busLocations", busLocations);
  });

  socket.on("disconnect", () => {
    console.log("Client disconnected:", socket.id);
  });
});

// Routes
const authRoutes = require("./routes/auth");
const busRoutes = require("./routes/bus");
app.use("/api/auth", authRoutes);
app.use("/api/buses", busRoutes);

const PORT = 5000;
server.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
const ticketRoutes = require("./routes/ticket");
app.use("/api/tickets", ticketRoutes);
