const mongoose = require("mongoose");

const busSchema = new mongoose.Schema(
  {
    busNumber: { type: String, required: true, unique: true },
    busName: { type: String, required: true },
    driverId: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
    depotId: { type: mongoose.Schema.Types.ObjectId, ref: "Depot" },
    totalSeats: { type: Number, default: 40 },
    busType: {
      type: String,
      enum: ["standard", "deluxe", "luxury"],
      default: "standard",
    },
    isActive: { type: Boolean, default: true },
    conditionStatus: {
      type: String,
      enum: ["workable", "non_workable", "maintenance"],
      default: "workable",
    },
    assignmentStatus: {
      type: String,
      enum: ["available", "assigned"],
      default: "available",
    },
    currentAssignmentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Assignment",
    },
    currentAssignmentDate: { type: Date },
    notes: { type: String },
    currentLocation: {
      lat: { type: Number },
      lng: { type: Number },
      updatedAt: { type: Date },
    },
    isLocationSharing: { type: Boolean, default: false },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("Bus", busSchema);

