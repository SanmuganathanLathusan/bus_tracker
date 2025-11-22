const mongoose = require("mongoose");

const routeSchema = new mongoose.Schema({
  start: { type: String, required: true },
  destination: { type: String, required: true },
  departure: { type: String, required: true },
  arrival: { type: String, required: true },
  duration: { type: String },
  busId: { type: mongoose.Schema.Types.ObjectId, ref: "Bus" },
  busName: { type: String },
  totalSeats: { type: Number, default: 40 },
  price: { type: Number, required: true },
  isActive: { type: Boolean, default: true },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model("Route", routeSchema);
