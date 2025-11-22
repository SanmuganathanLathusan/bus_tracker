const mongoose = require("mongoose");

const pricingSchema = new mongoose.Schema({
  routeId: { type: mongoose.Schema.Types.ObjectId, ref: "Route", required: true },
  start: { type: String, required: true },
  destination: { type: String, required: true },
  price: { type: Number, required: true },
  isActive: { type: Boolean, default: true },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model("Pricing", pricingSchema);

