const mongoose = require("mongoose");

const maintenanceSchema = new mongoose.Schema({
  driverId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  busId: { type: mongoose.Schema.Types.ObjectId, ref: "Bus", required: true },
  issueType: { 
    type: String, 
    enum: ["engine", "brakes", "tires", "ac", "electrical", "other"],
    required: true 
  },
  description: { type: String, required: true },
  imageUrl: { type: String },
  status: { 
    type: String, 
    enum: ["pending", "resolved", "unsent"], 
    default: "unsent" 
  },
  resolvedBy: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
  resolvedAt: { type: Date },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model("Maintenance", maintenanceSchema);

