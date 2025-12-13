const News = require("../models/News");

// GET ALL NEWS (for passengers - only published/active)
exports.getNews = async (req, res) => {
  try {
    const now = new Date();
    // Set to end of today to include all of today's news
    const endOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);
    // Set to start of today for expiry comparison
    const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    
    console.log("🔵 Fetching news for passengers...");
    console.log("🔵 Now:", now.toISOString());
    console.log("🔵 End of today:", endOfToday.toISOString());
    
    const news = await News.find({
      status: { $in: ["Published", "Active"] },
      $and: [
        {
          // Show if expiryDate is null, or if it hasn't expired yet
          $or: [
            { expiryDate: null },
            { expiryDate: { $gte: startOfToday } }
          ]
        },
        {
          // Show if publishDate is null, or if it's today or in the past
          $or: [
            { publishDate: null },
            { publishDate: { $lte: endOfToday } }
          ]
        }
      ]
    })
    .sort({ createdAt: -1 })
    .populate("postedBy", "userName")
    .select("-__v");

    console.log(`🔵 Found ${news.length} news items with status Published/Active`);

    // Format for Flutter app
    const formattedNews = news.map(item => ({
      _id: item._id,
      title: item.title,
      description: item.description,
      imageUrl: item.imageUrl || '',
      type: item.type,
      status: item.status,
      date: item.createdAt,
      publishDate: item.publishDate,
      expiryDate: item.expiryDate,
      postedBy: item.postedBy ? item.postedBy.userName : 'Admin'
    }));

    res.json(formattedNews);
  } catch (error) {
    console.error("❌ Get news error:", error);
    res.status(500).json({ error: "Failed to fetch news" });
  }
};

// GET ALL NEWS (for admin - all statuses)
exports.getAllNews = async (req, res) => {
  try {
    const news = await News.find()
      .sort({ createdAt: -1 })
      .populate("postedBy", "userName")
      .select("-__v");

    res.json(news);
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch news" });
  }
};

// CREATE NEWS (admin only)
exports.createNews = async (req, res) => {
  try {
    const { title, description, imageUrl, type, status, publishDate, expiryDate } = req.body;

    const newsStatus = status || "Published"; // Default to Published so it appears to passengers
    const newsPublishDate = publishDate ? new Date(publishDate) : null;
    const newsExpiryDate = expiryDate ? new Date(expiryDate) : null;

    console.log("🔵 Creating news:", {
      title,
      status: newsStatus,
      publishDate: newsPublishDate,
      expiryDate: newsExpiryDate
    });

    const news = await News.create({
      title,
      description,
      imageUrl,
      type: type || "Info",
      status: newsStatus,
      postedBy: req.user._id,
      // If publishDate is provided, use it; otherwise keep it null so query matches null condition
      publishDate: newsPublishDate,
      expiryDate: newsExpiryDate,
    });

    console.log("✅ News created successfully:", news._id);

    res.status(201).json({
      message: "News created successfully",
      news
    });
  } catch (error) {
    console.error("❌ Create news error:", error);
    res.status(500).json({ error: "Failed to create news" });
  }
};

// UPDATE NEWS (admin only)
exports.updateNews = async (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, imageUrl, type, status, publishDate, expiryDate } = req.body;

    const news = await News.findByIdAndUpdate(
      id,
      {
        title,
        description,
        imageUrl,
        type,
        status,
        publishDate: publishDate ? new Date(publishDate) : undefined,
        expiryDate: expiryDate ? new Date(expiryDate) : undefined,
        updatedAt: new Date(),
      },
      { new: true }
    );

    if (!news) {
      return res.status(404).json({ error: "News not found" });
    }

    res.json({
      message: "News updated successfully",
      news
    });
  } catch (error) {
    res.status(500).json({ error: "Failed to update news" });
  }
};

// DELETE NEWS (admin only)
exports.deleteNews = async (req, res) => {
  try {
    const { id } = req.params;

    const news = await News.findByIdAndDelete(id);

    if (!news) {
      return res.status(404).json({ error: "News not found" });
    }

    res.json({ message: "News deleted successfully" });
  } catch (error) {
    res.status(500).json({ error: "Failed to delete news" });
  }
};

// GET NEWS BY ID (for admin to view details)
exports.getNewsById = async (req, res) => {
  try {
    const { id } = req.params;

    const news = await News.findById(id)
      .populate("postedBy", "userName email")
      .select("-__v");

    if (!news) {
      return res.status(404).json({ error: "News not found" });
    }

    res.json(news);
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch news" });
  }
};

