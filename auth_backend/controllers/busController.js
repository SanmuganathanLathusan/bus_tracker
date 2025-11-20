const Bus = require("../models/Bus");
const User = require("../models/User");
const Depot = require("../models/Depot");

// UPDATE BUS LOCATION
exports.updateLocation = async (req, res) => {
  try {
    const { busId, lat, lng } = req.body;
    const driverId = req.user._id;

    // Verify driver owns the bus
    const bus = await Bus.findById(busId);
    if (!bus || bus.driverId.toString() !== driverId.toString()) {
      return res.status(403).json({ error: "Unauthorized" });
    }

    bus.currentLocation = {
      lat,
      lng,
      updatedAt: new Date(),
    };
    await bus.save();

    res.json({
      message: "Location updated successfully",
      location: bus.currentLocation
    });
  } catch (error) {
    res.status(500).json({ error: "Failed to update location" });
  }
};

// START/STOP LOCATION SHARING
exports.toggleLocationSharing = async (req, res) => {
  try {
    const { busId, isSharing } = req.body;
    const driverId = req.user._id;

    const bus = await Bus.findById(busId);
    if (!bus || bus.driverId.toString() !== driverId.toString()) {
      return res.status(403).json({ error: "Unauthorized" });
    }

    bus.isLocationSharing = isSharing;
    await bus.save();

    res.json({
      message: `Location sharing ${isSharing ? "started" : "stopped"}`,
      bus
    });
  } catch (error) {
    res.status(500).json({ error: "Failed to toggle location sharing" });
  }
};

// GET BUS LOCATION
exports.getBusLocation = async (req, res) => {
  try {
    const { busId } = req.params;

    const bus = await Bus.findById(busId);
    if (!bus) {
      return res.status(404).json({ error: "Bus not found" });
    }

    if (!bus.isLocationSharing) {
      return res.json({
        message: "Location sharing is disabled",
        location: null
      });
    }

    res.json({
      busId: bus._id,
      busNumber: bus.busNumber,
      location: bus.currentLocation
    });
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch bus location" });
  }
};

// GET ALL BUSES (admin)
exports.getAllBuses = async (req, res) => {
  try {
    const buses = await Bus.find()
      .populate("driverId", "userName email phone")
      .populate("depotId", "name code city")
      .sort({ createdAt: -1 })
      .select("-__v");

    res.json(buses);
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch buses" });
  }
};

// CREATE BUS (admin)
exports.createBus = async (req, res) => {
  try {
    const { busNumber, busName, totalSeats, busType, depotId, conditionStatus } = req.body;

    if (depotId) {
      const depotExists = await Depot.exists({ _id: depotId, isActive: true });
      if (!depotExists) {
        return res.status(404).json({ error: "Depot not found" });
      }
    }

    const allowedStatuses = ["workable", "non_workable", "maintenance"];
    if (conditionStatus && !allowedStatuses.includes(conditionStatus)) {
      return res.status(400).json({ error: "Invalid condition status" });
    }

    const bus = await Bus.create({
      busNumber,
      busName,
      totalSeats: totalSeats || 40,
      busType: busType || "standard",
      depotId,
      conditionStatus: conditionStatus || "workable",
    });

    res.status(201).json({
      message: "Bus created successfully",
      bus,
    });
  } catch (error) {
    res.status(500).json({ error: "Failed to create bus" });
  }
};

// UPDATE BUS CONDITION/DEPOT (admin)
exports.updateBusStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { conditionStatus, depotId, notes } = req.body;

    const update = {};
    const allowedStatuses = ["workable", "non_workable", "maintenance"];

    if (conditionStatus) {
      if (!allowedStatuses.includes(conditionStatus)) {
        return res.status(400).json({ error: "Invalid condition status" });
      }
      update.conditionStatus = conditionStatus;
    }

    if (typeof notes !== "undefined") {
      update.notes = notes;
    }

    if (depotId) {
      const depotExists = await Depot.exists({ _id: depotId, isActive: true });
      if (!depotExists) {
        return res.status(404).json({ error: "Depot not found" });
      }
      update.depotId = depotId;
    } else if (depotId === null) {
      update.depotId = null;
    }

    if (Object.keys(update).length === 0) {
      return res.status(400).json({ error: "No updates provided" });
    }

    const bus = await Bus.findByIdAndUpdate(id, update, { new: true })
      .populate("driverId", "userName email phone")
      .populate("depotId", "name code city")
      .select("-__v");

    if (!bus) {
      return res.status(404).json({ error: "Bus not found" });
    }

    res.json({ message: "Bus updated successfully", bus });
  } catch (error) {
    res.status(500).json({ error: "Failed to update bus" });
  }
};

// ASSIGN DRIVER TO BUS (admin)
exports.assignDriverToBus = async (req, res) => {
  try {
    const { busId, driverId } = req.body;

    const bus = await Bus.findById(busId);
    const driver = await User.findById(driverId);

    if (!bus) {
      return res.status(404).json({ error: "Bus not found" });
    }
    if (!driver || driver.userType !== "driver") {
      return res.status(404).json({ error: "Driver not found" });
    }

    bus.driverId = driverId;
    driver.busId = busId;
    await bus.save();
    await driver.save();

    res.json({
      message: "Driver assigned to bus successfully",
      bus,
      driver
    });
  } catch (error) {
    res.status(500).json({ error: "Failed to assign driver" });
  }
};

