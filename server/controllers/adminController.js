const User = require("../models/User");
const Bus = require("../models/Bus");
const Route = require("../models/Route");
const Trip = require("../models/Trip");
const Reservation = require("../models/Reservation");
const Payment = require("../models/Payment");
const Assignment = require("../models/Assignment");
const Feedback = require("../models/Feedback");
const Maintenance = require("../models/Maintenance");
const News = require("../models/News");
const Depot = require("../models/Depot");
const { notifyDriverAssignment } = require("../utils/notificationService");
const {
  markDriverAssigned,
  releaseDriverIfIdle,
  markBusAssigned,
  releaseBusIfIdle,
} = require("../utils/assignmentState");

// GET OVERVIEW STATS
exports.getOverview = async (req, res) => {
  try {
    const totalUsers = await User.countDocuments();
    const totalPassengers = await User.countDocuments({ userType: "passenger" });
    const totalDrivers = await User.countDocuments({ userType: "driver" });
    const totalBuses = await Bus.countDocuments();
    const activeTrips = await Trip.countDocuments({ status: "started" });
    const totalReservations = await Reservation.countDocuments({ status: "paid" });
    const totalRevenue = await Payment.aggregate([
      { $match: { status: "success" } },
      { $group: { _id: null, total: { $sum: "$amount" } } }
    ]);

    res.json({
      totalUsers,
      totalPassengers,
      totalDrivers,
      totalBuses,
      activeTrips,
      totalReservations,
      totalRevenue: totalRevenue[0]?.total || 0,
    });
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch overview" });
  }
};

// GET ALL USERS
exports.getAllUsers = async (req, res) => {
  try {
    const { userType, isActive } = req.query;

    const query = {};
    if (userType) query.userType = userType;
    if (isActive !== undefined) query.isActive = isActive === "true";

    const users = await User.find(query)
      .populate("busId", "busNumber busName")
      .select("-password")
      .sort({ createdAt: -1 })
      .select("-__v");

    res.json(users);
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch users" });
  }
};

// UPDATE USER STATUS
exports.updateUserStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { isActive } = req.body;

    const user = await User.findByIdAndUpdate(
      id,
      { isActive },
      { new: true }
    ).select("-password");

    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    res.json({
      message: "User status updated successfully",
      user
    });
  } catch (error) {
    res.status(500).json({ error: "Failed to update user status" });
  }
};

// DELETE USER
exports.deleteUser = async (req, res) => {
  try {
    const { id } = req.params;

    const user = await User.findByIdAndDelete(id);

    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    res.json({ message: "User deleted successfully" });
  } catch (error) {
    res.status(500).json({ error: "Failed to delete user" });
  }
};

const ASSIGNMENT_STATUSES = ["pending", "accepted", "rejected", "completed"];

const populateAssignment = async (assignmentId) => {
  return Assignment.findById(assignmentId)
    .populate("driverId", "userName email phone")
    .populate("busId", "busNumber busName")
    .populate("routeId", "start destination departure arrival price")
    .populate("depotId", "name code city")
    .populate("assignedBy", "userName");
};

const normalizeDate = (value) => {
  if (!value) return null;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return null;
  date.setHours(0, 0, 0, 0);
  return date;
};

const ensureDriver = async (driverId) => {
  if (!driverId) return null;
  const driver = await User.findById(driverId);
  if (!driver || driver.userType !== "driver" || !driver.isActive) {
    throw new Error("Driver not found or inactive");
  }
  return driver;
};

const ensureBus = async (busId) => {
  if (!busId) return null;
  const bus = await Bus.findById(busId);
  if (!bus || !bus.isActive) {
    throw new Error("Bus not found or inactive");
  }
  return bus;
};

const ensureRoute = async (routeId) => {
  if (!routeId) return null;
  const route = await Route.findById(routeId);
  if (!route || !route.isActive) {
    throw new Error("Route not found or inactive");
  }
  return route;
};

const ensureDepot = async (depotId) => {
  if (!depotId) return null;
  const depot = await Depot.findById(depotId);
  if (!depot || !depot.isActive) {
    throw new Error("Depot not found or inactive");
  }
  return depot;
};

const hasConflictingAssignment = async ({ driverId, busId, scheduledDate, assignmentId }) => {
  const dayStart = new Date(scheduledDate);
  const dayEnd = new Date(dayStart);
  dayEnd.setDate(dayEnd.getDate() + 1);

  const conflictQueries = [
    {
      driverId,
      scheduledDate: { $gte: dayStart, $lt: dayEnd },
      status: { $in: ["pending", "accepted"] },
    },
  ];

  if (busId) {
    conflictQueries.push({
      busId,
      scheduledDate: { $gte: dayStart, $lt: dayEnd },
      status: { $in: ["pending", "accepted"] },
    });
  }

  const query = { $or: conflictQueries };
  if (assignmentId) {
    query._id = { $ne: assignmentId };
  }

  return Assignment.findOne(query);
};

// CREATE ASSIGNMENT
exports.createAssignment = async (req, res) => {
  try {
    const {
      driverId,
      busId,
      routeId,
      depotId,
      scheduledDate,
      scheduledTime,
      startTime,
      endTime,
      notes,
    } = req.body;

    if (!driverId || !routeId || !scheduledDate || !scheduledTime) {
      return res.status(400).json({ error: "Driver, route, date, and time are required" });
    }

    let driver;
    let bus;
    try {
      driver = await ensureDriver(driverId);
      bus = await ensureBus(busId);
      await ensureRoute(routeId);
      if (depotId) {
        await ensureDepot(depotId);
      }
    } catch (validationError) {
      return res.status(404).json({ error: validationError.message });
    }

    // Check for conflicting assignments on the same date
    const date = new Date(scheduledDate);
    date.setHours(0, 0, 0, 0);
    const nextDay = new Date(date);
    nextDay.setDate(nextDay.getDate() + 1);

    const conflictingAssignment = await hasConflictingAssignment({
      driverId,
      busId,
      scheduledDate: date,
    });

    if (conflictingAssignment) {
      return res.status(400).json({
        error: "Driver or bus already has an assignment on this date",
      });
    }

    let parsedStart = null;
    if (startTime) {
      parsedStart = new Date(startTime);
    } else {
      parsedStart = new Date(date);
      const [hours, minutes] = scheduledTime.split(":").map(Number);
      parsedStart.setHours(hours || 0, minutes || 0, 0, 0);
    }

    const parsedEnd = endTime ? new Date(endTime) : null;

    const resolvedDepotId = depotId || bus?.depotId || driver?.homeDepotId || null;

    const assignment = await Assignment.create({
      driverId,
      busId,
      routeId,
      depotId: resolvedDepotId,
      scheduledDate: date,
      scheduledTime,
      startTime: parsedStart,
      endTime: parsedEnd,
      notes,
      assignedBy: req.user._id,
      status: "pending",
    });

    await markDriverAssigned(driverId, assignment._id);
    if (busId) {
      await markBusAssigned(busId, assignment._id, assignment.scheduledDate);
    }

    // Populate the assignment for response
    const populatedAssignment = await populateAssignment(assignment._id);

    // Send push notification to driver (async, don't wait)
    notifyDriverAssignment(driverId, populatedAssignment).catch(err => {
      console.error("Failed to send assignment notification:", err);
    });

    res.status(201).json({
      message: "Assignment created successfully",
      assignment: populatedAssignment,
    });
  } catch (error) {
    console.error("Create assignment error:", error);
    res.status(500).json({ error: "Failed to create assignment" });
  }
};

// GET ALL ASSIGNMENTS (with optional filters)
exports.getAllAssignments = async (req, res) => {
  try {
    const { status, driverId, routeId, date } = req.query;

    const query = {};
    if (status && ASSIGNMENT_STATUSES.includes(status)) {
      query.status = status;
    }
    if (driverId) {
      query.driverId = driverId;
    }
    if (routeId) {
      query.routeId = routeId;
    }
    if (date) {
      const day = normalizeDate(date);
      if (day) {
        const nextDay = new Date(day);
        nextDay.setDate(nextDay.getDate() + 1);
        query.scheduledDate = { $gte: day, $lt: nextDay };
      }
    }

    const assignments = await Assignment.find(query)
      .populate("driverId", "userName email phone")
      .populate("busId", "busNumber busName")
      .populate("routeId", "start destination departure arrival")
      .populate("depotId", "name code city")
      .populate("assignedBy", "userName")
      .sort({ scheduledDate: -1, scheduledTime: 1 })
      .select("-__v");

    res.json(assignments);
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch assignments" });
  }
};

// GET ASSIGNMENT BY ID
exports.getAssignmentById = async (req, res) => {
  try {
    const { id } = req.params;
    const assignment = await populateAssignment(id);

    if (!assignment) {
      return res.status(404).json({ error: "Assignment not found" });
    }

    res.json(assignment);
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch assignment" });
  }
};

// UPDATE ASSIGNMENT
exports.updateAssignment = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      driverId,
      busId,
      routeId,
      depotId,
      scheduledDate,
      scheduledTime,
      startTime,
      endTime,
      status,
      notes,
    } = req.body;

    const assignment = await Assignment.findById(id);
    if (!assignment) {
      return res.status(404).json({ error: "Assignment not found" });
    }

    if (status && !ASSIGNMENT_STATUSES.includes(status)) {
      return res.status(400).json({ error: "Invalid status" });
    }

    const originalDriverId = assignment.driverId?.toString();
    const originalBusId = assignment.busId ? assignment.busId.toString() : null;

    try {
      if (driverId && driverId.toString() !== originalDriverId) {
        await ensureDriver(driverId);
      }
      if (typeof busId !== "undefined") {
        if (busId && busId.toString() !== originalBusId) {
          await ensureBus(busId);
        } else if (busId === null) {
          // allow removing bus
        }
      }
      if (routeId && routeId.toString() !== assignment.routeId.toString()) {
        await ensureRoute(routeId);
      }
      if (typeof depotId !== "undefined" && depotId !== null) {
        await ensureDepot(depotId);
      }
    } catch (validationError) {
      return res.status(404).json({ error: validationError.message });
    }

    const newDate = scheduledDate ? normalizeDate(scheduledDate) : assignment.scheduledDate;
    if (!newDate) {
      return res.status(400).json({ error: "Invalid scheduled date" });
    }

    const effectiveDriverId = driverId || assignment.driverId;
    const effectiveBusId =
      typeof busId === "undefined"
        ? assignment.busId
        : busId === null || busId === ""
            ? null
            : busId;

    const conflict = await hasConflictingAssignment({
      driverId: effectiveDriverId,
      busId: effectiveBusId,
      scheduledDate: newDate,
      assignmentId: assignment._id,
    });

    if (conflict) {
      return res.status(400).json({ error: "Driver or bus already has an assignment on this date" });
    }

    assignment.driverId = effectiveDriverId;
    assignment.busId = effectiveBusId;
    assignment.routeId = routeId || assignment.routeId;
    assignment.scheduledDate = newDate;
    assignment.scheduledTime = scheduledTime || assignment.scheduledTime;
    assignment.notes = typeof notes === "undefined" ? assignment.notes : notes;

    if (startTime) {
      assignment.startTime = new Date(startTime);
    } else if (scheduledTime) {
      const [hours, minutes] = scheduledTime.split(":").map(Number);
      const computedStart = new Date(newDate);
      computedStart.setHours(hours || 0, minutes || 0, 0, 0);
      assignment.startTime = computedStart;
    }

    if (endTime) {
      assignment.endTime = new Date(endTime);
    } else if (endTime === null) {
      assignment.endTime = null;
    }

    let resolvedDepotId = assignment.depotId;
    if (typeof depotId !== "undefined") {
      resolvedDepotId = depotId;
    } else if (!resolvedDepotId && effectiveBusId) {
      const busDoc = await Bus.findById(effectiveBusId).select("depotId");
      resolvedDepotId = busDoc?.depotId || resolvedDepotId;
    }
    if (!resolvedDepotId && effectiveDriverId) {
      const driverDoc = await User.findById(effectiveDriverId).select("homeDepotId");
      resolvedDepotId = driverDoc?.homeDepotId || resolvedDepotId;
    }
    assignment.depotId = resolvedDepotId;

    if (status) {
      assignment.status = status;
    }

    assignment.updatedAt = new Date();
    await assignment.save();

    const newDriverId = assignment.driverId.toString();
    const newBusId = assignment.busId ? assignment.busId.toString() : null;

    if (originalDriverId !== newDriverId) {
      if (originalDriverId) {
        await releaseDriverIfIdle(originalDriverId, assignment._id);
      }
      await markDriverAssigned(newDriverId, assignment._id);
    }

    if (originalBusId !== newBusId) {
      if (originalBusId) {
        await releaseBusIfIdle(originalBusId, assignment._id);
      }
      if (newBusId) {
        await markBusAssigned(newBusId, assignment._id, assignment.scheduledDate);
      }
    }

    if (["completed", "rejected"].includes(assignment.status)) {
      await releaseDriverIfIdle(assignment.driverId, assignment._id);
      if (assignment.busId) {
        await releaseBusIfIdle(assignment.busId, assignment._id);
      }
    } else if (["pending", "accepted"].includes(assignment.status)) {
      await markDriverAssigned(assignment.driverId, assignment._id);
      if (assignment.busId) {
        await markBusAssigned(assignment.busId, assignment._id, assignment.scheduledDate);
      }
    }

    const populated = await populateAssignment(assignment._id);

    res.json({
      message: "Assignment updated successfully",
      assignment: populated,
    });
  } catch (error) {
    console.error("Update assignment error:", error);
    res.status(500).json({ error: "Failed to update assignment" });
  }
};

// DELETE ASSIGNMENT
exports.deleteAssignment = async (req, res) => {
  try {
    const { id } = req.params;
    const assignment = await Assignment.findById(id);

    if (!assignment) {
      return res.status(404).json({ error: "Assignment not found" });
    }

    await Assignment.deleteOne({ _id: id });
    await releaseDriverIfIdle(assignment.driverId, assignment._id);
    if (assignment.busId) {
      await releaseBusIfIdle(assignment.busId, assignment._id);
    }

    res.json({ message: "Assignment deleted successfully" });
  } catch (error) {
    res.status(500).json({ error: "Failed to delete assignment" });
  }
};

// GET ALL BUSES WITH LOCATIONS (for live tracking)
exports.getBusesForTracking = async (req, res) => {
  try {
    const { busId } = req.query;

    const query = {};
    if (busId) {
      query.busNumber = new RegExp(busId, "i");
    }

    const buses = await Bus.find(query)
      .populate("driverId", "userName")
      .select("-__v");

    const busesWithStatus = await Promise.all(
      buses.map(async (bus) => {
        const activeTrip = await Trip.findOne({
          busId: bus._id,
          status: { $in: ["started", "paused"] }
        }).populate("routeId", "start destination");

        return {
          ...bus.toObject(),
          trip: activeTrip,
          status: activeTrip ? activeTrip.status : "idle",
        };
      })
    );

    res.json(busesWithStatus);
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch buses for tracking" });
  }
};

// GET AVAILABLE BUSES (not assigned or available for assignment)
exports.getAvailableBuses = async (req, res) => {
  try {
    const { scheduledDate } = req.query;
    
    // Get all buses
    const allBuses = await Bus.find({ isActive: true, conditionStatus: "workable" })
      .populate("driverId", "userName email phone")
      .populate("depotId", "name code city")
      .select("-__v");

    // If scheduledDate is provided, check which buses are already assigned on that date
    let assignedBusIds = [];
    if (scheduledDate) {
      const date = new Date(scheduledDate);
      date.setHours(0, 0, 0, 0);
      const nextDay = new Date(date);
      nextDay.setDate(nextDay.getDate() + 1);

      const assignments = await Assignment.find({
        scheduledDate: {
          $gte: date,
          $lt: nextDay
        },
        status: { $in: ["pending", "accepted"] }
      });

      assignedBusIds = assignments
        .filter((a) => a.busId)
        .map((a) => a.busId.toString());
    }

    // Separate available and assigned buses
    const availableBuses = allBuses.filter(
      (bus) => !assignedBusIds.includes(bus._id.toString())
    );
    
    const assignedBuses = allBuses.filter((bus) =>
      assignedBusIds.includes(bus._id.toString())
    );

    res.json({
      available: availableBuses,
      assigned: assignedBuses,
      total: allBuses.length
    });
  } catch (error) {
    console.error("Get available buses error:", error);
    res.status(500).json({ error: "Failed to fetch available buses" });
  }
};

// GET AVAILABLE DRIVERS (not assigned or available for assignment)
exports.getAvailableDrivers = async (req, res) => {
  try {
    const { scheduledDate } = req.query;

    // Get all active drivers
    const allDrivers = await User.find({ 
      userType: "driver",
      isActive: true 
    })
    .populate("busId", "busNumber busName")
    .populate("homeDepotId", "name code city")
    .select("-password -__v");

    // If scheduledDate is provided, check which drivers are already assigned on that date
    let assignedDriverIds = [];
    if (scheduledDate) {
      const date = new Date(scheduledDate);
      date.setHours(0, 0, 0, 0);
      const nextDay = new Date(date);
      nextDay.setDate(nextDay.getDate() + 1);

      const assignments = await Assignment.find({
        scheduledDate: {
          $gte: date,
          $lt: nextDay
        },
        status: { $in: ["pending", "accepted"] }
      });

      assignedDriverIds = assignments.map(a => a.driverId.toString());
    }

    // Separate available and assigned drivers
    const availableDrivers = allDrivers.filter(
      (driver) =>
        driver.dutyStatus === "available" &&
        !assignedDriverIds.includes(driver._id.toString())
    );
    
    const assignedDrivers = allDrivers.filter((driver) =>
      assignedDriverIds.includes(driver._id.toString())
    );

    res.json({
      available: availableDrivers,
      assigned: assignedDrivers,
      total: allDrivers.length
    });
  } catch (error) {
    console.error("Get available drivers error:", error);
    res.status(500).json({ error: "Failed to fetch available drivers" });
  }
};

// GET BUS AND DRIVER STATISTICS
exports.getBusDriverStats = async (req, res) => {
  try {
    const buses = await Bus.find({ isActive: true })
      .populate("driverId", "userName email phone dutyStatus homeDepotId")
      // NOTE: do not populate depotId here – some legacy records store the depot
      // code (e.g. "DPT-01") instead of an ObjectId. We will resolve depots
      // manually to avoid CastError on ObjectId.
      .select("-__v")
      .lean();

    const drivers = await User.find({
      userType: "driver",
      isActive: true,
    })
      .populate("busId", "busNumber busName assignmentStatus conditionStatus")
      // Same reasoning as buses: resolve homeDepotId manually to support both
      // ObjectId and string depot codes.
      .select("-password -__v")
      .lean();

    const depots = await Depot.find({ isActive: true })
      .sort({ name: 1 })
      .select("name code city address contactNumber capacity")
      .lean();

    // Map active assignments to drivers and buses
    const activeAssignments = await Assignment.find({
      status: { $in: ["pending", "accepted"] },
    })
      .populate("routeId", "start destination routeNumber departure arrival")
      .populate("busId", "busNumber busName")
      .populate("driverId", "userName")
      .select("routeId busId driverId status scheduledDate scheduledTime notes")
      .lean();

    const formatAssignment = (assignment) => ({
      id: assignment._id.toString(),
      status: assignment.status,
      scheduledDate: assignment.scheduledDate,
      scheduledTime: assignment.scheduledTime,
      route: assignment.routeId
        ? {
            id: assignment.routeId._id?.toString(),
            start: assignment.routeId.start,
            destination: assignment.routeId.destination,
            routeNumber: assignment.routeId.routeNumber,
            departure: assignment.routeId.departure,
            arrival: assignment.routeId.arrival,
          }
        : null,
      bus: assignment.busId
        ? {
            id: assignment.busId._id?.toString(),
            busNumber: assignment.busId.busNumber,
            busName: assignment.busId.busName,
          }
        : null,
      driver: assignment.driverId
        ? {
            id: assignment.driverId._id?.toString(),
            userName: assignment.driverId.userName,
          }
        : null,
      notes: assignment.notes,
    });

    const driverAssignmentMap = {};
    const busAssignmentMap = {};

    activeAssignments.forEach((assignment) => {
      const formatted = formatAssignment(assignment);
      if (assignment.driverId?._id) {
        driverAssignmentMap[assignment.driverId._id.toString()] = formatted;
      }
      if (assignment.busId?._id) {
        busAssignmentMap[assignment.busId._id.toString()] = formatted;
      }
    });

    // Build depot lookup maps (by ObjectId and by depot code)
    const depotsById = {};
    const depotsByCode = {};
    depots.forEach((depot) => {
      if (depot._id) {
        depotsById[depot._id.toString()] = depot;
      }
      if (depot.code) {
        depotsByCode[depot.code.toString()] = depot;
      }
    });

    const resolveDepot = (raw) => {
      if (!raw) return null;
      // If it's already a populated depot-like object
      if (typeof raw === "object" && raw._id) {
        const id = raw._id.toString();
        return depotsById[id] || raw;
      }
      // Otherwise it might be an ObjectId or a string code
      const value = raw.toString();
      return depotsById[value] || depotsByCode[value] || null;
    };

    const busesWithAssignments = buses.map((bus) => ({
      ...bus,
      depotId: resolveDepot(bus.depotId),
      currentAssignment: busAssignmentMap[bus._id.toString()] || null,
    }));

    const driversWithAssignments = drivers.map((driver) => ({
      ...driver,
      homeDepotId: resolveDepot(driver.homeDepotId),
      currentAssignment: driverAssignmentMap[driver._id.toString()] || null,
    }));

    const busGroups = {
      workable: busesWithAssignments.filter(
        (bus) => bus.conditionStatus === "workable"
      ),
      non_workable: busesWithAssignments.filter(
        (bus) => bus.conditionStatus === "non_workable"
      ),
      maintenance: busesWithAssignments.filter(
        (bus) => bus.conditionStatus === "maintenance"
      ),
      assigned: busesWithAssignments.filter(
        (bus) => bus.assignmentStatus === "assigned"
      ),
    };

    const driverGroups = {
      available: driversWithAssignments.filter(
        (driver) => driver.dutyStatus === "available"
      ),
      assigned: driversWithAssignments.filter(
        (driver) => driver.dutyStatus === "assigned"
      ),
      off_duty: driversWithAssignments.filter(
        (driver) => driver.dutyStatus === "off_duty"
      ),
      on_leave: driversWithAssignments.filter(
        (driver) => driver.dutyStatus === "on_leave"
      ),
    };

    res.json({
      stats: {
        totalBuses: busesWithAssignments.length,
        workableBuses: busGroups.workable.length,
        assignedBuses: busGroups.assigned.length,
        totalDrivers: driversWithAssignments.length,
        availableDrivers: driverGroups.available.length,
        assignedDrivers: driverGroups.assigned.length,
      },
      buses: busGroups,
      drivers: driverGroups,
      depots,
    });
  } catch (error) {
    console.error("Get bus driver stats error:", error);
    res
      .status(500)
      .json({ error: "Failed to fetch bus and driver statistics" });
  }
};

// DEPOT MANAGEMENT
exports.listDepots = async (req, res) => {
  try {
    const depots = await Depot.find()
      .sort({ name: 1 })
      .select("-__v");
    res.json(depots);
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch depots" });
  }
};

exports.createDepot = async (req, res) => {
  try {
    const { name, code, city, address, contactNumber, capacity, location } = req.body;
    if (!name || !code) {
      return res.status(400).json({ error: "Name and code are required" });
    }

    const depot = await Depot.create({
      name,
      code,
      city,
      address,
      contactNumber,
      capacity,
      location,
    });

    res.status(201).json({
      message: "Depot created successfully",
      depot,
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({ error: "Depot code already exists" });
    }
    res.status(500).json({ error: "Failed to create depot" });
  }
};

exports.updateDepot = async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;

    const depot = await Depot.findByIdAndUpdate(id, updates, { new: true });
    if (!depot) {
      return res.status(404).json({ error: "Depot not found" });
    }

    res.json({
      message: "Depot updated successfully",
      depot,
    });
  } catch (error) {
    res.status(500).json({ error: "Failed to update depot" });
  }
};

// DRIVER DUTY STATUS MANAGEMENT
exports.updateDriverDutyStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { dutyStatus } = req.body;

    const allowedStatuses = ["available", "off_duty", "on_leave"];
    if (!allowedStatuses.includes(dutyStatus)) {
      return res.status(400).json({ error: "Invalid duty status" });
    }

    const hasActiveAssignments = await Assignment.exists({
      driverId: id,
      status: { $in: ["pending", "accepted"] },
    });

    if (hasActiveAssignments) {
      return res
        .status(400)
        .json({ error: "Driver has active assignments. Complete or reassign them first." });
    }

    const driver = await User.findOneAndUpdate(
      { _id: id, userType: "driver" },
      {
        dutyStatus,
        ...(dutyStatus !== "available" ? { currentAssignmentId: null } : {}),
      },
      { new: true }
    )
      .populate("homeDepotId", "name code city")
      .populate("busId", "busNumber busName");

    if (!driver) {
      return res.status(404).json({ error: "Driver not found" });
    }

    await releaseDriverIfIdle(id);

    res.json({
      message: "Driver duty status updated successfully",
      driver,
    });
  } catch (error) {
    res.status(500).json({ error: "Failed to update driver status" });
  }
};

// RESET DRIVER ASSIGNMENT (force available)
exports.resetDriverAssignment = async (req, res) => {
  try {
    const { id } = req.params;

    const driver = await User.findOne({ _id: id, userType: "driver" });
    if (!driver) {
      return res.status(404).json({ error: "Driver not found" });
    }

    const activeAssignment = await Assignment.findOne({
      driverId: id,
      status: { $in: ["pending", "accepted"] },
    });

    if (activeAssignment) {
      activeAssignment.status = "rejected";
      activeAssignment.updatedAt = new Date();
      const mergedNotes = [activeAssignment.notes, "[System] Assignment reset by admin"]
        .filter((note) => typeof note === "string" && note.trim().length > 0)
        .join(" | ");
      activeAssignment.notes = mergedNotes;
      await activeAssignment.save();

      await releaseDriverIfIdle(id, activeAssignment._id);
      if (activeAssignment.busId) {
        await releaseBusIfIdle(activeAssignment.busId, activeAssignment._id);
      }
    }

    const updatedDriver = await User.findByIdAndUpdate(
      id,
      {
        dutyStatus: "available",
        currentAssignmentId: null,
      },
      { new: true }
    ).select("-password");

    res.json({
      message: "Driver reset to available",
      driver: updatedDriver,
      clearedAssignmentId: activeAssignment?._id,
    });
  } catch (error) {
    console.error("Reset driver assignment error:", error);
    res.status(500).json({ error: "Failed to reset driver assignment" });
  }
};

// GET PRICING STATISTICS WITH ROUTE DATA
exports.getPricingStats = async (req, res) => {
  try {
    // Get all active routes with bus information
    const routes = await Route.find({ isActive: true })
      .populate("busId", "busNumber busName totalSeats busType")
      .select("routeNumber start destination departure arrival price priceDeluxe priceLuxury totalSeats distance busId busName")
      .sort({ start: 1, destination: 1 });

    // Get all paid reservations
    const reservations = await Reservation.find({ status: "paid" })
      .populate("routeId", "routeNumber start destination price")
      .select("routeId seats date amount");

    // Calculate stats per route
    const routeStats = routes.map(route => {
      const routeReservations = reservations.filter(
        r => r.routeId && r.routeId._id.toString() === route._id.toString()
      );
      
      const totalSold = routeReservations.reduce((sum, res) => sum + (res.seats?.length || 0), 0);
      const totalIncome = routeReservations.reduce((sum, res) => sum + (res.amount || 0), 0);
      
      // Determine price based on bus type
      const busType = route.busId?.busType || "standard";
      let routePrice = route.price;
      if (busType === "deluxe" && route.priceDeluxe) {
        routePrice = route.priceDeluxe;
      } else if (busType === "luxury" && route.priceLuxury) {
        routePrice = route.priceLuxury;
      }

      return {
        routeId: route._id.toString(),
        routeNumber: route.routeNumber || `R${route._id.toString().substring(0, 6)}`,
        route: `${route.start} - ${route.destination}`,
        start: route.start,
        destination: route.destination,
        departure: route.departure,
        arrival: route.arrival,
        price: routePrice,
        priceDeluxe: route.priceDeluxe,
        priceLuxury: route.priceLuxury,
        capacity: route.totalSeats || route.busId?.totalSeats || 40,
        sold: totalSold,
        income: totalIncome,
        availableSeats: (route.totalSeats || route.busId?.totalSeats || 40) - totalSold,
        reservation: route.isActive ? 'Enabled' : 'Disabled',
        busNumber: route.busId?.busNumber || '',
        busName: route.busName || route.busId?.busName || '',
        busType: busType,
        distance: route.distance || null,
      };
    });

    // Calculate overall statistics
    const totalIncome = routeStats.reduce((sum, r) => sum + r.income, 0);
    const totalSold = routeStats.reduce((sum, r) => sum + r.sold, 0);
    const avgPrice = routeStats.length > 0
      ? routeStats.reduce((sum, r) => sum + r.price, 0) / routeStats.length
      : 0;

    res.json({
      routes: routeStats,
      stats: {
        totalIncome,
        totalSold,
        averagePrice: avgPrice,
        activeRoutes: routeStats.length,
      },
    });
  } catch (error) {
    console.error("Get pricing stats error:", error);
    res.status(500).json({ error: "Failed to fetch pricing statistics" });
  }
};

