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

    // Get assignments for these routes on the searched date
    const routeIds = routes.map(r => r._id);
    const assignments = await Assignment.find({
      routeId: { $in: routeIds },
      scheduledDate: {
        $gte: searchDate,
        $lt: nextDay,
      },
      status: { $in: ["pending", "accepted"] }, // Only show active assignments
    })
    .populate("routeId", "start destination departure arrival price priceDeluxe priceLuxury distance routeNumber")
    .populate("busId", "busNumber busName totalSeats busType isLocationSharing currentLocation")
    .populate("driverId", "userName")
    .select("-__v");

    // Get booked seats for the date
    const reservations = await Reservation.find({
      date: {
        $gte: searchDate,
        $lt: nextDay,
      },
      status: { $in: ["reserved", "paid"] },
    });

    // Build results from assignments (schedules)
    const schedulesWithAssignments = assignments.map(assignment => {
      const assignmentObj = assignment.toObject();
      const routeData = assignmentObj.routeId || {};
      const busData = assignmentObj.busId || {};
      const driverData = assignmentObj.driverId || {};

      // Get booked seats for this route on this date
      const routeReservations = reservations.filter(r => 
        r.routeId && r.routeId.toString() === routeData._id.toString()
      );
      const bookedSeats = [];
      routeReservations.forEach(res => {
        if (res.seats && Array.isArray(res.seats)) {
          bookedSeats.push(...res.seats);
        }
      });

      // Determine price based on bus type
      let routePrice = routeData.price || 0;
      if (busData.busType === "deluxe" && routeData.priceDeluxe) {
        routePrice = routeData.priceDeluxe;
      } else if (busData.busType === "luxury" && routeData.priceLuxury) {
        routePrice = routeData.priceLuxury;
      }

      // Check if location is being shared
      const hasLiveLocation = busData.isLocationSharing && 
                              busData.currentLocation && 
                              busData.currentLocation.lat && 
                              busData.currentLocation.lng;

      return {
        // Route information
        _id: routeData._id || assignment.routeId,
        routeId: routeData._id || assignment.routeId,
        routeNumber: routeData.routeNumber || `R${(routeData._id || assignment.routeId).toString().substring(0, 6)}`,
        start: routeData.start || '',
        destination: routeData.destination || '',
        departure: routeData.departure || assignment.scheduledTime,
        arrival: routeData.arrival || '',
        duration: routeData.duration || null,
        distance: routeData.distance || null,
        
        // Pricing
        price: routePrice,
        priceDeluxe: routeData.priceDeluxe || null,
        priceLuxury: routeData.priceLuxury || null,
        
        // Bus information
        busId: busData._id || assignment.busId,
        busNumber: busData.busNumber || '',
        busName: busData.busName || routeData.busName || '',
        busType: busData.busType || 'standard',
        totalSeats: busData.totalSeats || routeData.totalSeats || 40,
        
        // Assignment/Schedule information
        assignmentId: assignment._id.toString(),
        scheduledDate: assignment.scheduledDate,
        scheduledTime: assignment.scheduledTime,
        assignmentStatus: assignment.status,
        driverId: assignment.driverId ? assignment.driverId.toString() : null,
        driverName: driverData.userName || null,
        
        // Live location data
        hasLiveLocation: hasLiveLocation,
        liveLocation: hasLiveLocation ? {
          lat: busData.currentLocation.lat,
          lng: busData.currentLocation.lng,
          updatedAt: busData.currentLocation.updatedAt,
        } : null,
        
        // Seat availability
        bookedSeats: [...new Set(bookedSeats)],
        availableSeats: (busData.totalSeats || routeData.totalSeats || 40) - bookedSeats.length,
      };
    });

    // Also include routes without assignments (if any)
    const routesWithoutAssignments = routes.filter(route => {
      const hasAssignment = assignments.some(a => a.routeId.toString() === route._id.toString());
      return !hasAssignment;
    });

    const routesWithAvailability = routesWithoutAssignments.map(route => {
      const routeReservations = reservations.filter(r => 
        r.routeId && r.routeId.toString() === route._id.toString()
      );
      const bookedSeats = [];
      routeReservations.forEach(res => {
        if (res.seats && Array.isArray(res.seats)) {
          bookedSeats.push(...res.seats);
        }
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
        routeId: route._id,
        routeNumber: routeObj.routeNumber || `R${route._id.toString().substring(0, 6)}`,
        distance: routeObj.distance || null,
        bookedSeats: [...new Set(bookedSeats)],
        availableSeats: (routeObj.totalSeats || busData.totalSeats || 40) - bookedSeats.length,
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
        assignmentId: null,
        hasLiveLocation: false,
        liveLocation: null,
      };
    });

    // Combine schedules with assignments and routes without assignments
    const allResults = [...schedulesWithAssignments, ...routesWithAvailability];

    // Sort by scheduled time or departure time
    allResults.sort((a, b) => {
      const timeA = a.scheduledTime || a.departure || '';
      const timeB = b.scheduledTime || b.departure || '';
      return timeA.localeCompare(timeB);
    });

    res.json(allResults);
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

