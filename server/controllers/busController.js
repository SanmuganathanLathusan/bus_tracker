// server/controllers/busController.js
const Bus = require('../models/Bus');

// POST /api/bus/location
exports.updateBusLocation = async (req, res) => {
  try {
    const { busId, latitude, longitude } = req.body;

    if (!busId) return res.status(400).json({ message: "busId is required" });

    const bus = await Bus.findOneAndUpdate(
      { busId },
      { latitude, longitude, lastUpdated: new Date() },
      { upsert: true, new: true }
    );

    res.json({ message: "Location updated", bus });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
};

// GET /api/bus/:busId
exports.getBusLocation = async (req, res) => {
  try {
    const { busId } = req.params;

    const bus = await Bus.findOne({ busId });
    if (!bus) return res.status(404).json({ message: "Bus not found" });

    res.json(bus);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
};
