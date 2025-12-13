const Notification = require("../models/Notification");

// CREATE NOTIFICATION
exports.createNotification = async (req, res) => {
  try {
    const { userId, userType, type, title, message, icon, iconColor } = req.body;

    const notification = await Notification.create({
      userId,
      userType: userType || "all",
      type,
      title,
      message,
      icon,
      iconColor,
      isRead: false,
    });

    res.status(201).json({
      message: "Notification created successfully",
      notification
    });
  } catch (error) {
    res.status(500).json({ error: "Failed to create notification" });
  }
};

// GET USER NOTIFICATIONS
exports.getUserNotifications = async (req, res) => {
  try {
    const userId = req.user._id;
    const userType = req.user.userType;
    const { type, isRead } = req.query;

    console.log(`📬 Fetching notifications for user: ${userId} (${userType})`);

    // Build query to get:
    // 1. Notifications specifically for this user (userId matches)
    // 2. Notifications for this user type (e.g., all drivers)
    // 3. Notifications for everyone (userType: "all")
    const query = {
      $or: [
        { userId },
        { userType: userType },
        { userType: "all" }
      ]
    };

    // Apply filters
    if (type) query.type = type;
    if (isRead !== undefined) query.isRead = isRead === "true";

    const notifications = await Notification.find(query)
      .sort({ createdAt: -1 })
      .limit(50)
      .select("-__v");

    // Count unread notifications for this user
    const unreadCount = await Notification.countDocuments({
      $or: [
        { userId, isRead: false },
        { userType: userType, isRead: false },
        { userType: "all", isRead: false }
      ]
    });

    console.log(`✅ Found ${notifications.length} notifications (${unreadCount} unread) for user ${userId}`);

    res.json({
      notifications,
      unreadCount
    });
  } catch (error) {
    console.error("❌ Get notifications error:", error);
    res.status(500).json({ error: "Failed to fetch notifications" });
  }
};

// MARK AS READ
exports.markAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user._id;
    const userType = req.user.userType;

    // Find notification that belongs to this user
    const notification = await Notification.findOne({
      _id: id,
      $or: [
        { userId },
        { userType: userType },
        { userType: "all" }
      ]
    });

    if (!notification) {
      return res.status(404).json({ error: "Notification not found or access denied" });
    }

    notification.isRead = true;
    await notification.save();

    console.log(`✅ Notification ${id} marked as read by user ${userId}`);

    res.json({
      message: "Notification marked as read",
      notification
    });
  } catch (error) {
    console.error("❌ Mark as read error:", error);
    res.status(500).json({ error: "Failed to mark notification as read" });
  }
};

// MARK ALL AS READ
exports.markAllAsRead = async (req, res) => {
  try {
    const userId = req.user._id;
    const userType = req.user.userType;

    const result = await Notification.updateMany(
      {
        $or: [
          { userId },
          { userType: userType },
          { userType: "all" }
        ],
        isRead: false
      },
      { isRead: true }
    );

    console.log(`✅ Marked ${result.modifiedCount} notifications as read for user ${userId}`);

    res.json({ 
      message: "All notifications marked as read",
      count: result.modifiedCount
    });
  } catch (error) {
    console.error("❌ Mark all as read error:", error);
    res.status(500).json({ error: "Failed to mark all as read" });
  }
};

// DELETE NOTIFICATION
exports.deleteNotification = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user._id;
    const userType = req.user.userType;

    // Find notification that belongs to this user
    const notification = await Notification.findOne({
      _id: id,
      $or: [
        { userId },
        { userType: userType },
        { userType: "all" }
      ]
    });

    if (!notification) {
      return res.status(404).json({ error: "Notification not found or access denied" });
    }

    await Notification.findByIdAndDelete(id);

    console.log(`✅ Notification ${id} deleted by user ${userId}`);

    res.json({ message: "Notification deleted successfully" });
  } catch (error) {
    console.error("❌ Delete notification error:", error);
    res.status(500).json({ error: "Failed to delete notification" });
  }
};

