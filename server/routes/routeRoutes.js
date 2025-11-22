const express = require("express");
const router = express.Router();
const authMiddleware = require("../middleware/authMiddleware");
const {
  searchRoutes,
  getAllRoutes,
  createRoute,
  updateRoute,
  deleteRoute
} = require("../controllers/routeController");

// Public route - search routes
router.get("/search", searchRoutes);

// Get all routes
router.get("/", getAllRoutes);

// Admin routes
router.post("/admin", authMiddleware, createRoute);
router.put("/admin/:id", authMiddleware, updateRoute);
router.delete("/admin/:id", authMiddleware, deleteRoute);

module.exports = router;
