const express = require("express");
const router = express.Router();
const authMiddleware = require("../middleware/authMiddleware");
const {
  startTrip,
  pauseTrip,
  resumeTrip,
  endTrip,
  updateTripStatus,
  getDriverTrips,
  getDriverAssignments,
  respondToAssignment,
  getTripPassengers,
  markPassengerStatus,
  getDriverPerformance,
  getAssignmentPassengers,
  getNextPendingAssignment
} = require("../controllers/driverController");

// All routes require authentication
router.use(authMiddleware);

// Trip management
router.post("/trip/start", startTrip);
router.post("/trip/pause", pauseTrip);
router.post("/trip/resume", resumeTrip);
router.post("/trip/end", endTrip);
router.put("/trip/status", updateTripStatus);
router.get("/trips", getDriverTrips);

// Assignments
router.get("/assignments", getDriverAssignments);
router.post("/assignments/respond", respondToAssignment);
router.get("/assignments/:assignmentId/passengers", getAssignmentPassengers);

// Passengers
router.get("/trip/:tripId/passengers", getTripPassengers);
router.post("/passenger/status", markPassengerStatus);

// Performance
router.get("/performance", getDriverPerformance);

// Next pending assignment
router.get("/assignments/next-pending", getNextPendingAssignment);

module.exports = router;
