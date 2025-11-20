const Pricing = require("../models/Pricing");
const Route = require("../models/Route");

// GET ALL PRICINGS
exports.getAllPricings = async (req, res) => {
  try {
    const pricings = await Pricing.find({ isActive: true })
      .populate("routeId", "start destination departure arrival")
      .sort({ createdAt: -1 })
      .select("-__v");

    res.json(pricings);
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch pricings" });
  }
};

// CREATE PRICING
exports.createPricing = async (req, res) => {
  try {
    const { routeId, start, destination, price } = req.body;

    // Also update route price
    await Route.findByIdAndUpdate(routeId, { price });

    const pricing = await Pricing.create({
      routeId,
      start,
      destination,
      price,
    });

    res.status(201).json({
      message: "Pricing created successfully",
      pricing
    });
  } catch (error) {
    res.status(500).json({ error: "Failed to create pricing" });
  }
};

// UPDATE PRICING
exports.updatePricing = async (req, res) => {
  try {
    const { id } = req.params;
    const { price } = req.body;

    const pricing = await Pricing.findById(id);
    if (!pricing) {
      return res.status(404).json({ error: "Pricing not found" });
    }

    pricing.price = price;
    pricing.updatedAt = new Date();
    await pricing.save();

    // Update route price
    await Route.findByIdAndUpdate(pricing.routeId, { price });

    res.json({
      message: "Pricing updated successfully",
      pricing
    });
  } catch (error) {
    res.status(500).json({ error: "Failed to update pricing" });
  }
};

// DELETE PRICING
exports.deletePricing = async (req, res) => {
  try {
    const { id } = req.params;

    const pricing = await Pricing.findByIdAndUpdate(
      id,
      { isActive: false },
      { new: true }
    );

    if (!pricing) {
      return res.status(404).json({ error: "Pricing not found" });
    }

    res.json({ message: "Pricing deleted successfully" });
  } catch (error) {
    res.status(500).json({ error: "Failed to delete pricing" });
  }
};

// GET PRICING STATISTICS
exports.getPricingStats = async (req, res) => {
  try {
    const totalRoutes = await Route.countDocuments({ isActive: true });
    const totalPricings = await Pricing.countDocuments({ isActive: true });
    const averagePrice = await Pricing.aggregate([
      { $match: { isActive: true } },
      { $group: { _id: null, avg: { $avg: "$price" } } }
    ]);

    res.json({
      totalRoutes,
      totalPricings,
      averagePrice: averagePrice[0]?.avg || 0,
    });
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch pricing statistics" });
  }
};

