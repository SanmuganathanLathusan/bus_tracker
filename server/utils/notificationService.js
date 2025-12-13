const { getMessaging } = require("../config/firebase");
const Notification = require("../models/Notification");
const User = require("../models/User");

/**
 * Send push notification via FCM
 * @param {String|Array} tokens - FCM token(s)
 * @param {Object} notification - { title, body, imageUrl }
 * @param {Object} data - Additional data payload
 */
const sendPushNotification = async (tokens, notification, data = {}) => {
  const messaging = getMessaging();
  
  if (!messaging) {
    console.warn("Firebase messaging not available. Skipping push notification.");
    return { success: false, error: "Firebase not configured" };
  }

  try {
    const tokensArray = Array.isArray(tokens) ? tokens : [tokens];
    const validTokens = tokensArray.filter(t => t && t.trim());

    if (validTokens.length === 0) {
      console.warn("No valid FCM tokens provided");
      return { success: false, error: "No valid tokens" };
    }

    const message = {
      notification: {
        title: notification.title,
        body: notification.body,
        ...(notification.imageUrl && { imageUrl: notification.imageUrl }),
      },
      data: {
        ...data,
        timestamp: new Date().toISOString(),
      },
      android: {
        priority: "high",
        notification: {
          sound: "default",
          channelId: "assignments",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    };

    let response;
    if (validTokens.length === 1) {
      response = await messaging.send({
        ...message,
        token: validTokens[0],
      });
      console.log("✅ Push notification sent:", response);
    } else {
      response = await messaging.sendEachForMulticast({
        ...message,
        tokens: validTokens,
      });
      console.log(`✅ Push notifications sent: ${response.successCount}/${validTokens.length}`);
    }

    return { success: true, response };
  } catch (error) {
    console.error("❌ Error sending push notification:", error);
    return { success: false, error: error.message };
  }
};

/**
 * Create notification record and send push notification to a user
 */
const notifyUser = async (userId, notificationData) => {
  try {
    // Create notification record
    const notification = await Notification.create({
      userId,
      userType: notificationData.userType || "driver",
      type: notificationData.type || "Info",
      title: notificationData.title,
      message: notificationData.message,
      icon: notificationData.icon,
      iconColor: notificationData.iconColor,
      assignmentId: notificationData.assignmentId,
      reservationId: notificationData.reservationId,
      routeId: notificationData.routeId,
      metadata: notificationData.metadata,
      isRead: false,
    });

    // Get user's FCM tokens
    const user = await User.findById(userId).select("fcmToken fcmTokens");
    if (!user) {
      console.warn(`User ${userId} not found`);
      return { notification, pushSent: false };
    }

    // Collect all valid tokens
    const tokens = [];
    if (user.fcmToken) tokens.push(user.fcmToken);
    if (user.fcmTokens && user.fcmTokens.length > 0) {
      tokens.push(...user.fcmTokens);
    }

    if (tokens.length === 0) {
      console.warn(`No FCM tokens for user ${userId}`);
      return { notification, pushSent: false };
    }

    // Send push notification
    const pushResult = await sendPushNotification(
      tokens,
      {
        title: notificationData.title,
        body: notificationData.message,
      },
      {
        notificationId: notification._id.toString(),
        type: notificationData.type || "Info",
        assignmentId: notificationData.assignmentId?.toString() || "",
        reservationId: notificationData.reservationId?.toString() || "",
        routeId: notificationData.routeId?.toString() || "",
      }
    );

    return {
      notification,
      pushSent: pushResult.success,
      pushResponse: pushResult.response,
    };
  } catch (error) {
    console.error("Error in notifyUser:", error);
    throw error;
  }
};

/**
 * Notify driver about new assignment
 */
const notifyDriverAssignment = async (driverId, assignment) => {
  const route = assignment.routeId;
  const routeText = route?.start && route?.destination 
    ? `${route.start} → ${route.destination}`
    : "New route";

  const dateStr = new Date(assignment.scheduledDate).toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
  });

  return notifyUser(driverId, {
    userType: "driver",
    type: "Alert",
    title: "New Assignment",
    message: `You have been assigned to ${routeText} on ${dateStr} at ${assignment.scheduledTime}`,
    icon: "assignment",
    iconColor: "#2196F3",
    assignmentId: assignment._id,
    routeId: assignment.routeId?._id || assignment.routeId,
    metadata: {
      scheduledDate: assignment.scheduledDate,
      scheduledTime: assignment.scheduledTime,
      busId: assignment.busId?.toString(),
    },
  });
};

/**
 * Notify driver about new passenger booking
 */
const notifyDriverNewBooking = async (driverId, reservation, assignment) => {
  const passenger = reservation.userId;
  const passengerName = passenger?.userName || "A passenger";
  const seats = Array.isArray(reservation.seats) 
    ? reservation.seats.join(", ") 
    : reservation.seats;

  return notifyUser(driverId, {
    userType: "driver",
    type: "Info",
    title: "New Booking",
    message: `${passengerName} booked seat(s) ${seats} for your upcoming trip`,
    icon: "person_add",
    iconColor: "#4CAF50",
    assignmentId: assignment?._id,
    reservationId: reservation._id,
    routeId: reservation.routeId,
    metadata: {
      passengerName,
      seats: reservation.seats,
      ticketId: reservation.ticketId,
    },
  });
};

/**
 * Notify driver about booking cancellation
 */
const notifyDriverCancellation = async (driverId, reservation, assignment) => {
  const passenger = reservation.userId;
  const passengerName = passenger?.userName || "A passenger";
  const seats = Array.isArray(reservation.seats)
    ? reservation.seats.join(", ")
    : reservation.seats;

  return notifyUser(driverId, {
    userType: "driver",
    type: "Update",
    title: "Booking Cancelled",
    message: `${passengerName} cancelled seat(s) ${seats}`,
    icon: "person_remove",
    iconColor: "#FF9800",
    assignmentId: assignment?._id,
    reservationId: reservation._id,
    routeId: reservation.routeId,
    metadata: {
      passengerName,
      seats: reservation.seats,
    },
  });
};

module.exports = {
  sendPushNotification,
  notifyUser,
  notifyDriverAssignment,
  notifyDriverNewBooking,
  notifyDriverCancellation,
};
