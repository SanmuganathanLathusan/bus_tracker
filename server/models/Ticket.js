const mongoose = require("mongoose");

const ticketSchema = new mongoose.Schema({
  userId: { type: String, required: true },
  busId: { type: String, required: true },
  route: String,
  price: Number,
  seatNo: String,
  timestamp: { type: Date, default: Date.now }
});

module.exports = mongoose.model("Ticket", ticketSchema);
