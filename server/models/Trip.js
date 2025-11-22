const mongoose = require("mongoose");

const tripSchema = new mongoose.Schema({
  driverId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  busId: { type: mongoose.Schema.Types.ObjectId, ref: "Bus", required: true },
  routeId: { type: mongoose.Schema.Types.ObjectId, ref: "Route", required: true },
  assignmentId: { type: mongoose.Schema.Types.ObjectId, ref: "Assignment" },
  status: { 
    type: String, 
    enum: ["pending", "started", "paused", "completed", "cancelled"], 
    default: "pending" 
  },
  startTime: { type: Date },
  endTime: { type: Date },
  pauseTime: { type: Date },
  resumeTime: { type: Date },
  delayReason: { type: String },
  emergencyReport: { type: String },
  passengerCount: { type: Number, default: 0 },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model("Trip", tripSchema);

