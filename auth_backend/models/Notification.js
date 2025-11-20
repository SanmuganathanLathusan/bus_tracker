const mongoose = require("mongoose");

const notificationSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
  userType: { type: String, enum: ["passenger", "driver", "admin", "all"] },
  type: { type: String, enum: ["Alert", "Update", "Info"], default: "Info" },
  title: { type: String, required: true },
  message: { type: String, required: true },
  isRead: { type: Boolean, default: false },
  icon: { type: String },
  iconColor: { type: String },
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model("Notification", notificationSchema);

