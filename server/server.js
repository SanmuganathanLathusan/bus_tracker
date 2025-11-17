require("dotenv").config(); // Load .env variables

const express = require("express");
const cors = require("cors");
const http = require("http");
const { Server } = require("socket.io");
const connectDB = require("./config/db");


const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: "*" } });

app.use(cors());
app.use(express.json());

// Connect to MongoDB
connectDB();

// SOCKET.IO
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
app.use("/api/auth", require("./routes/auth"));
app.use("/api/tickets", require("./routes/ticket"));
app.use("/api/schedule", require("./routes/schedule"));


// PORT
const PORT = process.env.PORT || 5000;
server.listen(PORT, "0.0.0.0", () => {
  console.log(`Server running on http://0.0.0.0:${PORT}`);
});
