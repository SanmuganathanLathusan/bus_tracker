const express = require("express");
const router = express.Router();
const authMiddleware = require("../middleware/authMiddleware");
const {
  updateLocation,
  toggleLocationSharing,
  getBusLocation,
  getAllBuses,
  createBus,
  assignDriverToBus
} = require("../controllers/busController");

// Driver routes
router.post("/update-location", authMiddleware, updateLocation);
router.post("/toggle-sharing", authMiddleware, toggleLocationSharing);

// Public/Passenger routes
router.get("/:busId", getBusLocation);

// Admin routes
router.get("/admin/all", authMiddleware, getAllBuses);
router.post("/admin", authMiddleware, createBus);
router.post("/admin/assign-driver", authMiddleware, assignDriverToBus);

module.exports = router;
