const express = require("express");
const router = express.Router();
const authMiddleware = require("../middleware/authMiddleware");

// Passenger Dashboard
router.get("/passenger-dashboard", authMiddleware, (req, res) => {
  if (req.user.userType !== "passenger") {
    return res.status(403).json({ error: "Access denied. Passenger access required." });
  }
  
  res.json({
    message: "Welcome to Passenger Dashboard",
    user: req.user,
    dashboard: {
      type: "passenger",
      features: [
        "Book a ride",
        "View ride history",
        "Manage profile",
        "Payment methods",
        "Support"
      ]
    }
  });
});

// Driver Dashboard
router.get("/driver-dashboard", authMiddleware, (req, res) => {
  if (req.user.userType !== "driver") {
    return res.status(403).json({ error: "Access denied. Driver access required." });
  }
  
  res.json({
    message: "Welcome to Driver Dashboard",
    user: req.user,
    dashboard: {
      type: "driver",
      features: [
        "Accept ride requests",
        "View earnings",
        "Manage availability",
        "Vehicle information",
        "Support"
      ]
    }
  });
});

// Admin Dashboard
router.get("/admin-dashboard", authMiddleware, (req, res) => {
  if (req.user.userType !== "admin") {
    return res.status(403).json({ error: "Access denied. Admin access required." });
  }
  
  res.json({
    message: "Welcome to Admin Dashboard",
    user: req.user,
    dashboard: {
      type: "admin",
      features: [
        "Manage users",
        "View analytics",
        "System settings",
        "Support tickets",
        "Reports"
      ]
    }
  });
});

// General dashboard route (fallback)
router.get("/dashboard", authMiddleware, (req, res) => {
  const userType = req.user.userType;
  let redirectUrl;
  
  switch (userType) {
    case "passenger":
      redirectUrl = "/api/dashboard/passenger-dashboard";
      break;
    case "driver":
      redirectUrl = "/api/dashboard/driver-dashboard";
      break;
    case "admin":
      redirectUrl = "/api/dashboard/admin-dashboard";
      break;
    default:
      return res.status(400).json({ error: "Invalid user type" });
  }
  
  res.redirect(redirectUrl);
});

module.exports = router;
