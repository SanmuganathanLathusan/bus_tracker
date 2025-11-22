const mongoose = require("mongoose");

const feedbackSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  userType: { type: String, enum: ["passenger", "driver"], required: true },
  type: { type: String, enum: ["delay", "emergency", "general", "complaint", "suggestion"] },
  subject: { type: String, required: true },
  message: { type: String, required: true },
  status: { type: String, enum: ["pending", "reviewed", "resolved"], default: "pending" },
  reviewedBy: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
  reviewedAt: { type: Date },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model("Feedback", feedbackSchema);

