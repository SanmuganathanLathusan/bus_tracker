const User = require("../models/User");

// UPDATE FCM TOKEN
exports.updateFcmToken = async (req, res) => {
  try {
    const userId = req.user._id;
    const { fcmToken } = req.body;

    if (!fcmToken) {
      return res.status(400).json({ error: "FCM token is required" });
    }

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    // Set as primary token
    user.fcmToken = fcmToken;

    // Add to tokens array if not already present
    if (!user.fcmTokens) {
      user.fcmTokens = [];
    }

    if (!user.fcmTokens.includes(fcmToken)) {
      user.fcmTokens.push(fcmToken);
      
      // Keep only the last 5 tokens (for multiple devices)
      if (user.fcmTokens.length > 5) {
        user.fcmTokens = user.fcmTokens.slice(-5);
      }
    }

    await user.save();

    res.json({
      message: "FCM token updated successfully",
      token: fcmToken,
    });
  } catch (error) {
    console.error("Update FCM token error:", error);
    res.status(500).json({ error: "Failed to update FCM token" });
  }
};

// REMOVE FCM TOKEN (on logout)
exports.removeFcmToken = async (req, res) => {
  try {
    const userId = req.user._id;
    const { fcmToken } = req.body;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    if (fcmToken) {
      // Remove specific token
      if (user.fcmToken === fcmToken) {
        user.fcmToken = null;
      }
      if (user.fcmTokens && user.fcmTokens.includes(fcmToken)) {
        user.fcmTokens = user.fcmTokens.filter(t => t !== fcmToken);
      }
    } else {
      // Remove all tokens
      user.fcmToken = null;
      user.fcmTokens = [];
    }

    await user.save();

    res.json({
      message: "FCM token removed successfully",
    });
  } catch (error) {
    console.error("Remove FCM token error:", error);
    res.status(500).json({ error: "Failed to remove FCM token" });
  }
};
