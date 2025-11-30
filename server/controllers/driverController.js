const Trip = require("../models/Trip");
const Assignment = require("../models/Assignment");
const Bus = require("../models/Bus");
const Reservation = require("../models/Reservation");
const Rating = require("../models/Rating");
const Notification = require("../models/Notification");
const {
  markDriverAssigned,
  releaseDriverIfIdle,
  markBusAssigned,
  releaseBusIfIdle,
} = require("../utils/assignmentState");

// START TRIP
exports.startTrip = async (req, res) => {
  try {
    const driverId = req.user._id;
    const { assignmentId } = req.body;

    const assignment = await Assignment.findById(assignmentId);
    if (!assignment || assignment.driverId.toString() !== driverId.toString()) {
      return res.status(404).json({ error: "Assignment not found" });
    }

    // Check if trip already exists
    let trip = await Trip.findOne({ assignmentId, status: { $in: ["pending", "started", "paused"] } });

    if (!trip) {
      trip = await Trip.create({
        driverId,
        busId: assignment.busId,
        routeId: assignment.routeId,
        assignmentId,
        status: "started",
        startTime: new Date(),
      });
    } else {
      trip.status = "started";
      trip.startTime = new Date();
      await trip.save();
    }

    res.json({
      message: "Trip started successfully",
      trip
    });
  } catch (error) {
    console.error("Start trip error:", error);
    res.status(500).json({ error: "Failed to start trip" });
  }
};

// PAUSE TRIP
exports.pauseTrip = async (req, res) => {
  try {
    const driverId = req.user._id;
    const { tripId, reason } = req.body;

    const trip = await Trip.findOne({ _id: tripId, driverId });
    if (!trip) {
      return res.status(404).json({ error: "Trip not found" });
    }

    trip.status = "paused";
    trip.pauseTime = new Date();
    if (reason) trip.delayReason = reason;
    await trip.save();

    res.json({
      message: "Trip paused successfully",
      trip
    });
  } catch (error) {
    res.status(500).json({ error: "Failed to pause trip" });
  }
};

// RESUME TRIP
exports.resumeTrip = async (req, res) => {
  try {
    const driverId = req.user._id;
    const { tripId } = req.body;

    const trip = await Trip.findOne({ _id: tripId, driverId });
    if (!trip) {
      return res.status(404).json({ error: "Trip not found" });
    }

    trip.status = "started";
    trip.resumeTime = new Date();
    await trip.save();

    res.json({
      message: "Trip resumed successfully",
      trip
    });
  } catch (error) {
    res.status(500).json({ error: "Failed to resume trip" });
  }
};

// END TRIP
exports.endTrip = async (req, res) => {
  try {
    const driverId = req.user._id;
    const { tripId } = req.body;

    const trip = await Trip.findOne({ _id: tripId, driverId });
    if (!trip) {
      return res.status(404).json({ error: "Trip not found" });
    }

    trip.status = "completed";
    trip.endTime = new Date();
    await trip.save();

    // Automatically mark the associated assignment as completed
    if (trip.assignmentId) {
      const assignment = await Assignment.findById(trip.assignmentId);
      if (assignment && assignment.status === "accepted") {
        assignment.status = "completed";
        assignment.endTime = trip.endTime;
        assignment.updatedAt = new Date();
        await assignment.save();
        await releaseDriverIfIdle(assignment.driverId, assignment._id);
        if (assignment.busId) {
          await releaseBusIfIdle(assignment.busId, assignment._id);
        }
      }
    }

    res.json({
      message: "Trip completed successfully",
      trip
    });
  } catch (error) {
    console.error("End trip error:", error);
    res.status(500).json({ error: "Failed to end trip" });
  }
};

// UPDATE TRIP STATUS
exports.updateTripStatus = async (req, res) => {
  try {
    const driverId = req.user._id;
    const { tripId, status, delayReason, emergencyReport } = req.body;

    const trip = await Trip.findOne({ _id: tripId, driverId });
    if (!trip) {
      return res.status(404).json({ error: "Trip not found" });
    }

    trip.status = status;
    if (delayReason) trip.delayReason = delayReason;
    if (emergencyReport) trip.emergencyReport = emergencyReport;
    trip.updatedAt = new Date();
    await trip.save();

    res.json({
      message: "Trip status updated successfully",
      trip
    });
  } catch (error) {
    res.status(500).json({ error: "Failed to update trip status" });
  }
};

// GET DRIVER TRIPS
exports.getDriverTrips = async (req, res) => {
  try {
    const driverId = req.user._id;

    const trips = await Trip.find({ driverId })
      .populate("busId", "busNumber busName")
      .populate("routeId", "start destination departure arrival")
      .sort({ createdAt: -1 })
      .select("-__v");

    res.json(trips);
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch trips" });
  }
};

// GET DRIVER ASSIGNMENTS
exports.getDriverAssignments = async (req, res) => {
  try {
    const driverId = req.user._id;

    const assignments = await Assignment.find({ driverId })
      .populate("busId", "busNumber busName")
      .populate("routeId", "start destination departure arrival price")
      .populate("depotId", "name code city")
      .populate("assignedBy", "userName")
      .sort({ scheduledDate: -1 })
      .select("-__v");

    res.json(assignments);
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch assignments" });
  }
};

// ACCEPT/REJECT ASSIGNMENT
exports.respondToAssignment = async (req, res) => {
  try {
    const driverId = req.user._id;
    const { assignmentId, response, status } = req.body; // status: "accepted" or "rejected"

    if (!["accepted", "rejected"].includes(status)) {
      return res.status(400).json({ error: "Invalid status" });
    }

    const assignment = await Assignment.findOne({ _id: assignmentId, driverId });
    if (!assignment) {
      return res.status(404).json({ error: "Assignment not found" });
    }

    if (assignment.status !== "pending") {
      return res.status(400).json({ error: "Assignment already processed" });
    }

    assignment.status = status;
    assignment.driverResponse = response;
    assignment.updatedAt = new Date();
    
    if (status === "accepted") {
      assignment.acceptedAt = new Date();
    }
    
    await assignment.save();

    if (status === "rejected") {
      await releaseDriverIfIdle(driverId, assignment._id);
      if (assignment.busId) {
        await releaseBusIfIdle(assignment.busId, assignment._id);
      }
      
      // Mark assignment notification as read
      await Notification.updateMany(
        { userId: driverId, assignmentId: assignment._id },
        { isRead: true }
      );
    } else if (status === "accepted") {
      await markDriverAssigned(driverId, assignment._id);
      if (assignment.busId) {
        await markBusAssigned(assignment.busId, assignment._id, assignment.scheduledDate);
      }
      
      // Mark assignment notification as read
      await Notification.updateMany(
        { userId: driverId, assignmentId: assignment._id },
        { isRead: true }
      );
      
      // Note: Passenger booking notifications will be sent when reservations are made
      // The driver is now subscribed to receive notifications for this assignment
    }

    res.json({
      message: `Assignment ${status} successfully`,
      assignment
    });
  } catch (error) {
    res.status(500).json({ error: "Failed to respond to assignment" });
  }
};

// GET PASSENGERS FOR AN ASSIGNMENT
exports.getAssignmentPassengers = async (req, res) => {
  try {
    const { assignmentId } = req.params;
    const driverId = req.user._id;

    const assignment = await Assignment.findOne({ _id: assignmentId, driverId })
      .populate("routeId", "start destination departure arrival price")
      .populate("busId", "busNumber busName totalSeats");

    if (!assignment) {
      return res.status(404).json({ error: "Assignment not found" });
    }

    const refDate = assignment.startTime || assignment.scheduledDate;
    const dayStart = new Date(refDate);
    dayStart.setHours(0, 0, 0, 0);
    const dayEnd = new Date(dayStart);
    dayEnd.setDate(dayEnd.getDate() + 1);

    const reservationQuery = {
      routeId: assignment.routeId?._id || assignment.routeId,
      date: { $gte: dayStart, $lt: dayEnd },
      status: { $in: ["paid", "reserved"] },
    };

    if (assignment.busId) {
      reservationQuery.busId = assignment.busId._id || assignment.busId;
    }

    const reservations = await Reservation.find(reservationQuery)
      .populate("userId", "userName email phone")
      .sort({ createdAt: 1 })
      .select("-__v");

    const reservedSeats = [];
    reservations.forEach((resv) => {
      reservedSeats.push(...resv.seats);
    });

    res.json({
      assignment,
      passengers: reservations,
      reservedSeats: [...new Set(reservedSeats)],
    });
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch assignment passengers" });
  }
};

// GET PASSENGERS FOR TRIP
exports.getTripPassengers = async (req, res) => {
  try {
    const { tripId } = req.params;
    const driverId = req.user._id;

    const trip = await Trip.findById(tripId);
    if (!trip || trip.driverId.toString() !== driverId.toString()) {
      return res.status(404).json({ error: "Trip not found" });
    }

    const reservations = await Reservation.find({
      routeId: trip.routeId,
      busId: trip.busId,
      date: trip.startTime,
      status: "paid",
    })
    .populate("userId", "userName email phone")
    .select("-__v");

    res.json(reservations);
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch passengers" });
  }
};

// MARK PASSENGER AS BOARDED/ABSENT
exports.markPassengerStatus = async (req, res) => {
  try {
    const { reservationId, status } = req.body; // status: "boarded" or "absent"

    const reservation = await Reservation.findById(reservationId);
    if (!reservation) {
      return res.status(404).json({ error: "Reservation not found" });
    }

    // You can add a boardingStatus field to Reservation model if needed
    reservation.boardingStatus = status;
    await reservation.save();

    res.json({
      message: `Passenger marked as ${status}`,
      reservation
    });
  } catch (error) {
    res.status(500).json({ error: "Failed to update passenger status" });
  }
};

// GET DRIVER PERFORMANCE
exports.getDriverPerformance = async (req, res) => {
  try {
    const driverId = req.user._id;

    const trips = await Trip.find({ driverId, status: "completed" });
    const ratings = await Rating.find({ driverId });

    const totalTrips = trips.length;
    const totalPassengers = trips.reduce((sum, trip) => sum + (trip.passengerCount || 0), 0);
    const averageRating = ratings.length > 0
      ? ratings.reduce((sum, r) => sum + r.rating, 0) / ratings.length
      : 0;

    res.json({
      totalTrips,
      totalPassengers,
      averageRating: averageRating.toFixed(1),
      recentRatings: ratings.slice(-5).reverse(),
    });
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch performance data" });
  }
};

// GET NEXT PENDING ASSIGNMENT (after completing a trip)
exports.getNextPendingAssignment = async (req, res) => {
  try {
    const driverId = req.user._id;

    // Get the next pending assignment for this driver
    const nextAssignment = await Assignment.findOne({
      driverId,
      status: "pending"
    })
      .populate("busId", "busNumber busName")
      .populate("routeId", "start destination departure arrival price")
      .populate("assignedBy", "userName")
      .sort({ scheduledDate: 1, scheduledTime: 1 })
      .select("-__v");

    if (!nextAssignment) {
      return res.json({ assignment: null, message: "No pending assignments" });
    }

    res.json({
      assignment: nextAssignment,
      message: "Next pending assignment found"
    });
  } catch (error) {
    console.error("Get next pending assignment error:", error);
    res.status(500).json({ error: "Failed to fetch next pending assignment" });
  }
};

