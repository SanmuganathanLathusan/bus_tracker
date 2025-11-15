// routes/schedule.js
const express = require("express");
const router = express.Router();
const Schedule = require("../models/Schedule");

// Insert mock schedules (run once)
router.get("/insert-mock", async (req, res) => {
  const mock = [
    {
      from: "Colombo",
      to: "Kandy",
      startTime: "06:00 AM",
      endTime: "09:00 AM",
      busType: "A/C",
      busName: "SuperLine Express",
      price: 800
    },
    {
      from: "Colombo",
      to: "Galle",
      startTime: "12:00 PM",
      endTime: "03:00 PM",
      busType: "Non-A/C",
      busName: "Southern Travels",
      price: 650
    },
    {
      from: "Kandy",
      to: "Colombo",
      startTime: "06:00 PM",
      endTime: "09:00 PM",
      busType: "Luxury",
      busName: "Queen Star Bus",
      price: 1200
    }
  ];

  await Schedule.insertMany(mock);
  res.json({ message: "Mock schedules added!" });
});

// Search schedules
router.post("/search", async (req, res) => {
  const { from, to, startTime, endTime, busType } = req.body;

  let query = { from, to };

  if (startTime != null && startTime != "") query.startTime = startTime;
  if (endTime != null && endTime != "") query.endTime = endTime;
  if (busType != null && busType != "Any") query.busType = busType;

  const results = await Schedule.find(query);
  res.json(results);
});

module.exports = router;