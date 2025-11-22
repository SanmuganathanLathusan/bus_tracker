const Route = require("../models/Route");
const Bus = require("../models/Bus");
const Reservation = require("../models/Reservation");

// SEARCH ROUTES
exports.searchRoutes = async (req, res) => {
  try {
    const { start, destination, date } = req.query;

    if (!start || !destination || !date) {
      return res.status(400).json({ error: "Start, destination, and date are required" });
    }

    const searchDate = new Date(date);
    searchDate.setHours(0, 0, 0, 0);

    // Find routes matching start and destination
    const routes = await Route.find({
      start: new RegExp(start, "i"),
      destination: new RegExp(destination, "i"),
      isActive: true,
    })
    .populate("busId", "busNumber busName totalSeats")
    .select("-__v");

    // Get booked seats for the date
    const reservations = await Reservation.find({
      date: {
        $gte: searchDate,
        $lt: new Date(searchDate.getTime() + 24 * 60 * 60 * 1000),
      },
      status: { $in: ["reserved", "paid"] },
    });

    // Map routes with booked seats
    const routesWithAvailability = routes.map(route => {
      const routeReservations = reservations.filter(r => r.routeId.toString() === route._id.toString());
      const bookedSeats = [];
      routeReservations.forEach(res => {
        bookedSeats.push(...res.seats);
      });

      return {
        ...route.toObject(),
        bookedSeats: [...new Set(bookedSeats)],
        availableSeats: route.totalSeats - bookedSeats.length,
      };
    });

    res.json(routesWithAvailability);
  } catch (error) {
    console.error("Search routes error:", error);
    res.status(500).json({ error: "Failed to search routes" });
  }
};

// GET ALL ROUTES
exports.getAllRoutes = async (req, res) => {
  try {
    const routes = await Route.find({ isActive: true })
      .populate("busId", "busNumber busName")
      .sort({ createdAt: -1 })
      .select("-__v");

    res.json(routes);
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch routes" });
  }
};

// CREATE ROUTE (admin)
exports.createRoute = async (req, res) => {
  try {
    const { start, destination, departure, arrival, duration, busId, price } = req.body;

    const bus = await Bus.findById(busId);
    if (!bus) {
      return res.status(404).json({ error: "Bus not found" });
    }

    const route = await Route.create({
      start,
      destination,
      departure,
      arrival,
      duration,
      busId,
      busName: bus.busName,
      totalSeats: bus.totalSeats,
      price,
    });

    res.status(201).json({
      message: "Route created successfully",
      route
    });
  } catch (error) {
    res.status(500).json({ error: "Failed to create route" });
  }
};

// UPDATE ROUTE (admin)
exports.updateRoute = async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    const route = await Route.findByIdAndUpdate(
      id,
      { ...updateData, updatedAt: new Date() },
      { new: true }
    );

    if (!route) {
      return res.status(404).json({ error: "Route not found" });
    }

    res.json({
      message: "Route updated successfully",
      route
    });
  } catch (error) {
    res.status(500).json({ error: "Failed to update route" });
  }
};

// DELETE ROUTE (admin)
exports.deleteRoute = async (req, res) => {
  try {
    const { id } = req.params;

    const route = await Route.findByIdAndUpdate(
      id,
      { isActive: false, updatedAt: new Date() },
      { new: true }
    );

    if (!route) {
      return res.status(404).json({ error: "Route not found" });
    }

    res.json({ message: "Route deleted successfully" });
  } catch (error) {
    res.status(500).json({ error: "Failed to delete route" });
  }
};

