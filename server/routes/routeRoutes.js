const express = require("express");
const router = express.Router();
const authMiddleware = require("../middleware/authMiddleware");
const {
  searchRoutes,
  getAllRoutes,
  getRouteById,
  createRoute,
  updateRoute,
  deleteRoute,
  getRoutePricesByType
} = require("../controllers/routeController");

// Public routes - order matters! More specific routes first
// Get route prices by type (for ticket prices page)
router.get("/prices", getRoutePricesByType);

// Search routes
router.get("/search", searchRoutes);

// Get all routes
router.get("/", getAllRoutes);

// Get route by ID
router.get("/:id", getRouteById);

// Admin routes
router.post("/admin", authMiddleware, createRoute);
router.put("/admin/:id", authMiddleware, updateRoute);
router.delete("/admin/:id", authMiddleware, deleteRoute);

module.exports = router;