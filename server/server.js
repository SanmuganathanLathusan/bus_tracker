const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const http = require("http");
const { Server } = require("socket.io");

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: "*" },
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

// SOCKET.IO (optional for realtime bus locations)
let busLocations = {};
io.on("connection", (socket) => {
  console.log("Bus/Client connected:", socket.id);

  socket.on("updateLocation", (data) => {
    const { busId, lat, lng } = data;
    busLocations[busId] = { lat, lng };
    io.emit("busLocations", busLocations);
  });

  socket.on("disconnect", () => {
    console.log("Client disconnected:", socket.id);
  });
});

// ROUTES
const authRoutes = require("./routes/auth");
const busRoutes = require("./routes/bus");
const ticketRoutes = require("./routes/ticket");
const scheduleRoutes = require("./routes/schedule");

app.use("/api/auth", authRoutes);
app.use("/api/buses", busRoutes);
app.use("/api/tickets", ticketRoutes);
app.use("/api/schedule", scheduleRoutes);

const PORT = 5000;
server.listen(PORT, () => console.log(Server running on http://localhost:${PORT}));