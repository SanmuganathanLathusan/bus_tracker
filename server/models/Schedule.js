// models/Schedule.js
const mongoose = require("mongoose");

const scheduleSchema = new mongoose.Schema({
  from: { type: String, required: true },
  to: { type: String, required: true },
  startTime: { type: String, required: true },
  endTime: { type: String, required: true },
  busType: { type: String, default: "Any" },
  busName: { type: String, required: true },
  price: { type: Number, required: true }
});

module.exports = mongoose.model("Schedule", scheduleSchema);