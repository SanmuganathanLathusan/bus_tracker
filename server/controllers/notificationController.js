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
    const { type, isRead } = req.query;

    const query = {
      $or: [
        { userId },
        { userType: req.user.userType },
        { userType: "all" }
      ]
    };

    if (type) query.type = type;
    if (isRead !== undefined) query.isRead = isRead === "true";

    const notifications = await Notification.find(query)
      .sort({ createdAt: -1 })
      .limit(50)
      .select("-__v");

    // Count unread
    const unreadCount = await Notification.countDocuments({
      ...query,
      isRead: false
    });

    res.json({
      notifications,
      unreadCount
    });
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch notifications" });
  }
};

// MARK AS READ
exports.markAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user._id;

    const notification = await Notification.findOne({
      _id: id,
      $or: [
        { userId },
        { userType: req.user.userType },
        { userType: "all" }
      ]
    });

    if (!notification) {
      return res.status(404).json({ error: "Notification not found" });
    }

    notification.isRead = true;
    await notification.save();

    res.json({
      message: "Notification marked as read",
      notification
    });
  } catch (error) {
    res.status(500).json({ error: "Failed to mark notification as read" });
  }
};

// MARK ALL AS READ
exports.markAllAsRead = async (req, res) => {
  try {
    const userId = req.user._id;

    await Notification.updateMany(
      {
        $or: [
          { userId },
          { userType: req.user.userType },
          { userType: "all" }
        ],
        isRead: false
      },
      { isRead: true }
    );

    res.json({ message: "All notifications marked as read" });
  } catch (error) {
    res.status(500).json({ error: "Failed to mark all as read" });
  }
};

// DELETE NOTIFICATION
exports.deleteNotification = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user._id;

    const notification = await Notification.findOne({
      _id: id,
      $or: [
        { userId },
        { userType: req.user.userType },
        { userType: "all" }
      ]
    });

    if (!notification) {
      return res.status(404).json({ error: "Notification not found" });
    }

    await Notification.findByIdAndDelete(id);

    res.json({ message: "Notification deleted successfully" });
  } catch (error) {
    res.status(500).json({ error: "Failed to delete notification" });
  }
};

