const Route = require("../models/Route");

// Search routes by start, destination, and date
exports.searchRoutes = async (req, res) => {
  try {
    const { start, destination, date } = req.query;

    // Build query
    let query = { isActive: true };
    if (start) query.start = new RegExp(start, "i");
    if (destination) query.destination = new RegExp(destination, "i");

    // Find routes
    const routes = await Route.find(query).sort({ createdAt: -1 });

    // For each route, get assignments for the specified date
    const results = [];
    for (const route of routes) {
      results.push({
        route: route.toObject(),
      });
    }

    res.json(results);
  } catch (error) {
    console.error("Search routes error:", error);
    res.status(500).json({ error: "Failed to search routes" });
  }
};

// Get all routes
exports.getAllRoutes = async (req, res) => {
  try {
    const routes = await Route.find({ isActive: true })
      .sort({ createdAt: -1 });
    
    res.json(routes);
  } catch (error) {
    console.error("Get all routes error:", error);
    res.status(500).json({ error: "Failed to fetch routes" });
  }
};

// Get route by ID
exports.getRouteById = async (req, res) => {
  try {
    const { id } = req.params;
    const route = await Route.findById(id);
    
    if (!route) {
      return res.status(404).json({ error: "Route not found" });
    }
    
    res.json(route);
  } catch (error) {
    console.error("Get route by ID error:", error);
    res.status(500).json({ error: "Failed to fetch route" });
  }
};

// Create route (admin only)
exports.createRoute = async (req, res) => {
  try {
    const routeData = req.body;
    const route = new Route(routeData);
    await route.save();
    
    res.status(201).json(route);
  } catch (error) {
    console.error("Create route error:", error);
    res.status(500).json({ error: "Failed to create route" });
  }
};

// Update route (admin only)
exports.updateRoute = async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;
    
    const route = await Route.findByIdAndUpdate(id, updateData, {
      new: true,
      runValidators: true,
    });
    
    if (!route) {
      return res.status(404).json({ error: "Route not found" });
    }
    
    res.json(route);
  } catch (error) {
    console.error("Update route error:", error);
    res.status(500).json({ error: "Failed to update route" });
  }
};

// Delete route (admin only)
exports.deleteRoute = async (req, res) => {
  try {
    const { id } = req.params;
    
    const route = await Route.findByIdAndUpdate(
      id,
      { isActive: false },
      { new: true }
    );
    
    if (!route) {
      return res.status(404).json({ error: "Route not found" });
    }
    
    res.json({ message: "Route deactivated successfully" });
  } catch (error) {
    console.error("Delete route error:", error);
    res.status(500).json({ error: "Failed to delete route" });
  }
};

// Get route prices by type for ticket prices page
exports.getRoutePricesByType = async (req, res) => {
  try {
    const routes = await Route.find({ isActive: true })
      .select("routeNumber start destination price priceDeluxe priceLuxury")
      .sort({ start: 1, destination: 1 });

    res.json(routes);
  } catch (error) {
    console.error("Get route prices error:", error);
    res.status(500).json({ error: "Failed to fetch route prices" });
  }
};