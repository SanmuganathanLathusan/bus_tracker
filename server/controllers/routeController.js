const Route = require("../models/Route");
const Bus = require("../models/Bus");
const Reservation = require("../models/Reservation");
const Assignment = require("../models/Assignment");

// SEARCH ROUTES
exports.searchRoutes = async (req, res) => {
  try {
    const { start, destination, date } = req.query;

    if (!start || !destination || !date) {
      return res.status(400).json({ error: "Start, destination, and date are required" });
    }

    const searchDate = new Date(date);
    searchDate.setHours(0, 0, 0, 0);
    const nextDay = new Date(searchDate.getTime() + 24 * 60 * 60 * 1000);

    // Find routes matching start and destination
    const routes = await Route.find({
      start: new RegExp(start, "i"),
      destination: new RegExp(destination, "i"),
      isActive: true,
    })
    .populate("busId", "busNumber busName totalSeats busType")
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

      const routeObj = route.toObject();
      const busData = routeObj.busId || {};
      
      // Determine price based on bus type
      let routePrice = routeObj.price;
      if (busData.busType === "deluxe" && routeObj.priceDeluxe) {
        routePrice = routeObj.priceDeluxe;
      } else if (busData.busType === "luxury" && routeObj.priceLuxury) {
        routePrice = routeObj.priceLuxury;
      }

      return {
        ...routeObj,
        routeNumber: routeObj.routeNumber || `R${route._id.toString().substring(0, 6)}`,
        distance: routeObj.distance || null,
        bookedSeats: [...new Set(bookedSeats)],
        availableSeats: (routeObj.totalSeats || busData.totalSeats || 40) - bookedSeats.length,
        // Ensure consistent field names
        start: routeObj.start,
        destination: routeObj.destination,
        departure: routeObj.departure,
        arrival: routeObj.arrival,
        price: routePrice,
        priceDeluxe: routeObj.priceDeluxe,
        priceLuxury: routeObj.priceLuxury,
        busNumber: busData.busNumber || '',
        busName: routeObj.busName || busData.busName || '',
        busType: busData.busType || 'standard',
        totalSeats: routeObj.totalSeats || busData.totalSeats || 40,
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
      .populate("busId", "busNumber busName busType totalSeats")
      .sort({ createdAt: -1 })
      .select("-__v");

    // Normalize routes to ensure consistent field names
    const normalizedRoutes = routes.map(route => {
      const routeObj = route.toObject();
      const busData = routeObj.busId || {};
      
      return {
        ...routeObj,
        routeNumber: routeObj.routeNumber || `R${route._id.toString().substring(0, 6)}`,
        start: routeObj.start,
        destination: routeObj.destination,
        departure: routeObj.departure,
        arrival: routeObj.arrival,
        price: routeObj.price,
        priceDeluxe: routeObj.priceDeluxe,
        priceLuxury: routeObj.priceLuxury,
        distance: routeObj.distance || null,
        busNumber: busData.busNumber || '',
        busName: routeObj.busName || busData.busName || '',
        busType: busData.busType || 'standard',
        totalSeats: routeObj.totalSeats || busData.totalSeats || 40,
      };
    });

    res.json(normalizedRoutes);
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

// GET ROUTE PRICES BY TYPE (for ticket prices page)
exports.getRoutePricesByType = async (req, res) => {
  try {
    const routes = await Route.find({ isActive: true })
      .populate("busId", "busType")
      .select("routeNumber start destination price priceDeluxe priceLuxury distance")
      .sort({ start: 1, destination: 1 });

    // Group routes by route identifier (start-destination)
    const routeGroups = {};
    routes.forEach(route => {
      const key = `${route.start}-${route.destination}`;
      if (!routeGroups[key]) {
        routeGroups[key] = {
          routeNumber: route.routeNumber || `R${route._id.toString().substring(0, 6)}`,
          route: `${route.start} - ${route.destination}`,
          distance: route.distance || null,
          prices: {
            normal: route.price || 0,
            semiLuxurious: route.priceDeluxe || null,
            luxury: route.priceLuxury || null,
          }
        };
      } else {
        // Update prices if different bus types have different prices
        if (route.priceDeluxe && (!routeGroups[key].prices.semiLuxurious || route.priceDeluxe > routeGroups[key].prices.semiLuxurious)) {
          routeGroups[key].prices.semiLuxurious = route.priceDeluxe;
        }
        if (route.priceLuxury && (!routeGroups[key].prices.luxury || route.priceLuxury > routeGroups[key].prices.luxury)) {
          routeGroups[key].prices.luxury = route.priceLuxury;
        }
      }
    });

    res.json(Object.values(routeGroups));
  } catch (error) {
    console.error("Get route prices error:", error);
    res.status(500).json({ error: "Failed to fetch route prices" });
  }
};

