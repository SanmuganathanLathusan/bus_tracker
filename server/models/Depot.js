const mongoose = require("mongoose");

const depotSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    code: { type: String, required: true, unique: true },
    city: { type: String },
    address: { type: String },
    contactNumber: { type: String },
    capacity: { type: Number },
    isActive: { type: Boolean, default: true },
    location: {
      lat: { type: Number },
      lng: { type: Number },
    },
    notes: { type: String },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("Depot", depotSchema);


