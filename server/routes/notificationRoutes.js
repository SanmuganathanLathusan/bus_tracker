const express = require("express");
const router = express.Router();
const authMiddleware = require("../middleware/authMiddleware");
const {
  createNotification,
  getUserNotifications,
  markAsRead,
  markAllAsRead,
  deleteNotification
} = require("../controllers/notificationController");

// All routes require authentication
router.use(authMiddleware);

// User routes
router.get("/", getUserNotifications);
router.put("/:id/read", markAsRead);
router.put("/read-all", markAllAsRead);
router.delete("/:id", deleteNotification);

// Admin route - create notification
router.post("/", createNotification);

module.exports = router;

