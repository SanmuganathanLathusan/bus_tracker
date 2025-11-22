const express = require("express");
const router = express.Router();
const authMiddleware = require("../middleware/authMiddleware");
const {
  createFeedback,
  getUserFeedback,
  getAllFeedback,
  getFeedbackById,
  reviewFeedback
} = require("../controllers/feedbackController");

// All routes require authentication
router.use(authMiddleware);

// User routes
router.post("/", createFeedback);
router.get("/my-feedback", getUserFeedback);
router.get("/:id", getFeedbackById);

// Admin routes
router.get("/admin/all", getAllFeedback);
router.put("/admin/:id/review", reviewFeedback);

module.exports = router;

