const mongoose = require("mongoose");

const routeSchema = new mongoose.Schema({
  routeNumber: { type: String, required: true },
  start: { type: String, required: true },
  destination: { type: String, required: true },
  departure: { type: String, required: true },
  arrival: { type: String, required: true },
  duration: { type: String },
  distance: { type: Number }, // Distance in kilometers
  busId: { type: mongoose.Schema.Types.ObjectId, ref: "Bus" },
  busName: { type: String },
  totalSeats: { type: Number, default: 40 },
  price: { type: Number, required: true }, // Default price (for standard/normal type)
  priceDeluxe: { type: Number }, // Price for semi-luxurious/deluxe
  priceLuxury: { type: Number }, // Price for luxury
  isActive: { type: Boolean, default: true },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model("Route", routeSchema);
