const mongoose = require("mongoose");

const assignmentSchema = new mongoose.Schema({
  driverId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  busId: { type: mongoose.Schema.Types.ObjectId, ref: "Bus" },
  routeId: { type: mongoose.Schema.Types.ObjectId, ref: "Route", required: true },
  depotId: { type: mongoose.Schema.Types.ObjectId, ref: "Depot" },
  scheduledDate: { type: Date, required: true },
  scheduledTime: { type: String, required: true },
  startTime: { type: Date },
  endTime: { type: Date },
  status: { 
    type: String, 
    enum: ["pending", "accepted", "rejected", "completed"], 
    default: "pending" 
  },
  assignedBy: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  driverResponse: { type: String },
  notes: { type: String },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },
});

assignmentSchema.pre("save", function(next) {
  this.updatedAt = new Date();
  if (!this.startTime && this.scheduledDate && this.scheduledTime) {
    const [hours, minutes] = this.scheduledTime.split(":").map(Number);
    const start = new Date(this.scheduledDate);
    if (!Number.isNaN(hours)) {
      start.setHours(hours || 0, minutes || 0, 0, 0);
      this.startTime = start;
    }
  }
  next();
});

module.exports = mongoose.model("Assignment", assignmentSchema);

