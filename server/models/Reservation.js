const mongoose = require("mongoose");

const reservationSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  routeId: { type: mongoose.Schema.Types.ObjectId, ref: "Route", required: true },
  busId: { type: mongoose.Schema.Types.ObjectId, ref: "Bus" },
  seats: [Number],
  status: { type: String, enum: ["reserved", "paid", "cancelled"], default: "reserved" },
  date: { type: Date, required: true },
  totalAmount: { type: Number, default: 0 },
  qrCode: { type: String },
  ticketId: { type: String, unique: true },
  boardingStatus: { type: String, enum: ["pending", "boarded", "absent"], default: "pending" },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model("Reservation", reservationSchema);
