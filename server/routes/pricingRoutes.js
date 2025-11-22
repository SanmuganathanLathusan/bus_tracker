const express = require("express");
const router = express.Router();
const authMiddleware = require("../middleware/authMiddleware");
const {
  getAllPricings,
  createPricing,
  updatePricing,
  deletePricing,
  getPricingStats
} = require("../controllers/pricingController");

// Public route
router.get("/", getAllPricings);

// Admin routes
router.get("/admin/stats", authMiddleware, getPricingStats);
router.post("/admin", authMiddleware, createPricing);
router.put("/admin/:id", authMiddleware, updatePricing);
router.delete("/admin/:id", authMiddleware, deletePricing);

module.exports = router;

