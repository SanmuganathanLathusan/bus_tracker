const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  userType: { type: String, enum: ["passenger", "driver", "admin"], required: true },
  userName: { type: String, required: true },
  phone: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String },
  profileImage: { type: String },
  googleId: { type: String, unique: true, sparse: true },
  isGoogleUser: { type: Boolean, default: false },
  busId: { type: mongoose.Schema.Types.ObjectId, ref: "Bus" },
  homeDepotId: { type: mongoose.Schema.Types.ObjectId, ref: "Depot" },
  currentAssignmentId: { type: mongoose.Schema.Types.ObjectId, ref: "Assignment" },
  dutyStatus: {
    type: String,
    enum: ["available", "assigned", "off_duty", "on_leave"],
    default: "available",
  },
  licenseNumber: { type: String },
  isActive: { type: Boolean, default: true },
  fcmToken: { type: String },
  fcmTokens: [{ type: String }],
}, { timestamps: true });

module.exports = mongoose.model("User", userSchema);
