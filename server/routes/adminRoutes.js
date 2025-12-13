const express = require("express");
const router = express.Router();
const authMiddleware = require("../middleware/authMiddleware");
const {
  getOverview,
  getAllUsers,
  updateUserStatus,
  deleteUser,
  createAssignment,
  getAllAssignments,
  getAssignmentById,
  updateAssignment,
  deleteAssignment,
  getBusesForTracking,
  getAvailableBuses,
  getAvailableDrivers,
  getBusDriverStats,
  listDepots,
  createDepot,
  updateDepot,
  updateDriverDutyStatus,
  resetDriverAssignment,
  getPricingStats
} = require("../controllers/adminController");
const { updateBusStatus } = require("../controllers/busController");

// All routes require admin authentication
router.use(authMiddleware);

// Check if user is admin
const adminMiddleware = (req, res, next) => {
  if (req.user.userType !== "admin") {
    return res.status(403).json({ error: "Access denied. Admin access required." });
  }
  next();
};

router.use(adminMiddleware);

// Overview
router.get("/overview", getOverview);

// User management
router.get("/users", getAllUsers);
router.put("/users/:id/status", updateUserStatus);
router.delete("/users/:id", deleteUser);

// Bus and Driver management
router.get("/buses-drivers/stats", getBusDriverStats);
router.get("/buses/available", getAvailableBuses);
router.get("/drivers/available", getAvailableDrivers);
router.patch("/buses/:id/status", updateBusStatus);
router.put("/drivers/:id/duty-status", updateDriverDutyStatus);
router.put("/drivers/:id/reset-assignment", resetDriverAssignment);

// Depot management
router.get("/depots", listDepots);
router.post("/depots", createDepot);
router.put("/depots/:id", updateDepot);

// Assignments / schedules
router.post("/assignments", createAssignment);
router.get("/assignments", getAllAssignments);
router.get("/assignments/:id", getAssignmentById);
router.put("/assignments/:id", updateAssignment);
router.delete("/assignments/:id", deleteAssignment);

// Live tracking
router.get("/tracking/buses", getBusesForTracking);

// Pricing statistics
router.get("/pricing/stats", getPricingStats);

module.exports = router;
