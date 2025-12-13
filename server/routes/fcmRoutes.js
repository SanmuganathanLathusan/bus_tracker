const express = require("express");
const router = express.Router();
const authMiddleware = require("../middleware/authMiddleware");
const { updateFcmToken, removeFcmToken } = require("../controllers/fcmController");

// All routes require authentication
router.use(authMiddleware);

// Update FCM token
router.post("/token", updateFcmToken);

// Remove FCM token (logout)
router.delete("/token", removeFcmToken);

module.exports = router;
