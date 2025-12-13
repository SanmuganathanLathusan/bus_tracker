const Reservation = require("../models/Reservation");
const Route = require("../models/Route");
const Payment = require("../models/Payment");
const Bus = require("../models/Bus");
const Notification = require("../models/Notification");
const Assignment = require("../models/Assignment");
const { notifyDriverNewBooking } = require("../utils/notificationService");
const QRCode = require("qrcode");
const PDFDocument = require("pdfkit");
const crypto = require("crypto");

// CREATE RESERVATION (without payment)
exports.createReservation = async (req, res) => {
  try {
    const { routeId, seats, date } = req.body;
    const userId = req.user._id;

    if (!routeId || !seats || !Array.isArray(seats) || seats.length === 0) {
      return res.status(400).json({ error: "Route ID and seats are required" });
    }

    const route = await Route.findById(routeId);
    if (!route) {
      return res.status(404).json({ error: "Route not found" });
    }

    // Check if seats are already booked for the date
    const searchDate = new Date(date);
    searchDate.setHours(0, 0, 0, 0);

    const existingReservations = await Reservation.find({
      routeId,
      date: {
        $gte: searchDate,
        $lt: new Date(searchDate.getTime() + 24 * 60 * 60 * 1000),
      },
      status: { $in: ["reserved", "paid"] },
    });

    const bookedSeats = [];
    existingReservations.forEach(res => {
      bookedSeats.push(...res.seats);
    });

    const conflictingSeats = seats.filter(seat => bookedSeats.includes(seat));
    if (conflictingSeats.length > 0) {
      return res.status(400).json({ 
        error: `Seats ${conflictingSeats.join(", ")} are already booked` 
      });
    }

    const ticketId = `TKT-${Date.now()}-${crypto.randomBytes(4).toString("hex").toUpperCase()}`;

    let reservation = await Reservation.create({
      userId,
      routeId,
      busId: route.busId,
      seats,
      date: searchDate,
      status: "reserved",
      totalAmount: route.price * seats.length,
      ticketId,
    });

    // Populate data for notifications
    reservation = await reservation.populate([
      { path: "routeId", select: "start destination departure arrival busName price" },
      { path: "busId", select: "busNumber busName driverId" },
      { path: "userId", select: "userName email phone" },
    ]);

    // Determine the driver for this booking (assignment preferred, fallback to bus driver)
    let driverId = reservation.busId && reservation.busId.driverId ? reservation.busId.driverId : null;

    let assignment = null;
    const dayStartForAssignment = new Date(searchDate);
    dayStartForAssignment.setHours(0, 0, 0, 0);
    const dayEndForAssignment = new Date(dayStartForAssignment);
    dayEndForAssignment.setDate(dayEndForAssignment.getDate() + 1);

    assignment = await Assignment.findOne({
      routeId: reservation.routeId._id || reservation.routeId,
      scheduledDate: { $gte: dayStartForAssignment, $lt: dayEndForAssignment },
      status: "accepted",
    }).populate("driverId", "userName email");

    if (assignment && assignment.driverId) {
      driverId = assignment.driverId._id;
    }

    // Notify the specific driver only (if found)
    if (driverId) {
      try {
        notifyDriverNewBooking(driverId, reservation, assignment).catch(err => {
          console.error("Failed to send push notification to driver (reserved):", err);
        });
      } catch (notifError) {
        console.error("Failed to notify driver for reservation:", notifError);
      }
    }

    res.status(201).json({
      message: "Reservation created successfully",
      reservation
    });
  } catch (error) {
    console.error("Create reservation error:", error);
    res.status(500).json({ error: "Failed to create reservation" });
  }
};

// CONFIRM RESERVATION WITH PAYMENT (Stripe / card)
exports.confirmReservation = async (req, res) => {
  try {
    const { reservationId, cardDetails, paymentMethod, amount } = req.body;
    const userId = req.user._id;

    const reservation = await Reservation.findById(reservationId);
    if (!reservation) {
      return res.status(404).json({ error: "Reservation not found" });
    }

    if (reservation.userId.toString() !== userId.toString()) {
      return res.status(403).json({ error: "Unauthorized" });
    }

    // Create payment (works with either legacy cardDetails or new paymentMethod/amount)
    const transactionId = `TXN-${Date.now()}-${crypto.randomBytes(6).toString("hex").toUpperCase()}`;
    
    const payment = await Payment.create({
      reservationId,
      userId,
      amount: typeof amount === "number" ? amount : reservation.totalAmount,
      method: paymentMethod || "card",
      cardDetails: cardDetails && cardDetails.cardNumber
        ? {
            last4: cardDetails.cardNumber.slice(-4),
            cardType: cardDetails.cardType || "unknown",
          }
        : undefined,
      status: "success",
      transactionId,
    });

    // Update reservation status
    reservation.status = "paid";
    reservation.updatedAt = new Date();

    // Store QR payload (ticketId). The mobile app will render the QR image.
    const qrPayload = reservation.ticketId;
    reservation.qrCode = qrPayload;

    await reservation.save();

    // Populate route and bus to get driver info
    await reservation.populate([
      { path: "routeId", select: "start destination departure arrival busName" },
      { path: "busId", select: "busNumber busName driverId" },
      { path: "userId", select: "userName email phone" }
    ]);

    // Get driver from bus (legacy approach)
    let driverId = null;
    if (reservation.busId && reservation.busId.driverId) {
      driverId = reservation.busId.driverId;
    }

    // Find accepted assignment for this route and date (preferred approach)
    let assignment = null;
    const dayStart = new Date(reservation.date);
    dayStart.setHours(0, 0, 0, 0);
    const dayEnd = new Date(dayStart);
    dayEnd.setDate(dayEnd.getDate() + 1);

    assignment = await Assignment.findOne({
      routeId: reservation.routeId._id,
      scheduledDate: { $gte: dayStart, $lt: dayEnd },
      status: "accepted",
    }).populate("driverId", "userName email");

    if (assignment && assignment.driverId) {
      driverId = assignment.driverId._id;
    }

    // Send notification to passenger
    try {
      await Notification.create({
        userId: userId,
        userType: "passenger",
        type: "Info",
        title: "Payment Successful",
        message: `Your ticket for ${reservation.routeId?.start || 'N/A'} to ${reservation.routeId?.destination || 'N/A'} has been confirmed. Ticket ID: ${reservation.ticketId}`,
        icon: "check_circle",
        iconColor: "#4CAF50",
        isRead: false,
      });
    } catch (notifError) {
      console.error("Failed to create passenger notification:", notifError);
    }

    // Send notification to driver if driver exists
    if (driverId) {
      try {
        // Use enhanced notification service for push notifications
        notifyDriverNewBooking(driverId, reservation, assignment).catch(err => {
          console.error("Failed to send push notification to driver:", err);
        });
      } catch (notifError) {
        console.error("Failed to notify driver:", notifError);
      }
    }

    res.json({
      message: "Payment successful and ticket confirmed",
      reservation,
      payment,
      qrCode: reservation.qrCode,
    });
  } catch (error) {
    console.error("Confirm reservation error:", error);
    res.status(500).json({ error: "Failed to confirm reservation" });
  }
};

// DOWNLOAD TICKET AS PDF
exports.downloadTicket = async (req, res) => {
  try {
    const { id } = req.params;
    const requester = req.user;

    const reservation = await Reservation.findById(id)
      .populate("routeId", "start destination departure arrival busName")
      .populate("busId", "busNumber busName driverId")
      .populate("userId", "userName email phone");

    if (!reservation) {
      return res.status(404).json({ error: "Reservation not found" });
    }

    const isAdmin = requester.userType === "admin";
    const isPassengerOwner =
      reservation.userId && reservation.userId._id.toString() === requester._id.toString();
    const isDriver = requester.userType === "driver";

    if (!isAdmin && !isPassengerOwner && !isDriver) {
      return res.status(403).json({ error: "You do not have access to this ticket" });
    }

    if (isDriver && reservation.busId && reservation.busId.driverId) {
      if (reservation.busId.driverId.toString() !== requester._id.toString()) {
        return res.status(403).json({ error: "You are not assigned to this bus" });
      }
    }

    const route = reservation.routeId || {};
    const bus = reservation.busId || {};
    const passenger = reservation.userId || {};

    const pdf = new PDFDocument({ margin: 40 });
    const fileName = `WayGo-Ticket-${reservation.ticketId || reservation._id}.pdf`;
    res.setHeader("Content-Type", "application/pdf");
    res.setHeader("Content-Disposition", `attachment; filename="${fileName}"`);

    pdf.pipe(res);

    pdf
      .fontSize(22)
      .fillColor("#0C2442")
      .text("WayGo Travel", { align: "center" });

    pdf.moveDown(0.5);
    pdf
      .fontSize(14)
      .fillColor("#1F4E79")
      .text("Passenger Ticket", { align: "center" });

    pdf.moveDown();
    pdf.fontSize(12).fillColor("#000000");
    pdf.text(`Passenger: ${passenger.userName || "N/A"}`);
    pdf.text(`Email: ${passenger.email || "N/A"}`);
    pdf.text(`Phone: ${passenger.phone || "N/A"}`);

    pdf.moveDown();
    pdf.text(`Ticket ID: ${reservation.ticketId || "N/A"}`);
    pdf.text(`Route: ${route.start || "N/A"} → ${route.destination || "N/A"}`);
    pdf.text(`Bus: ${bus.busNumber || bus.busName || route.busName || "N/A"}`);

    const travelDate = new Date(reservation.date);
    pdf.text(
      `Date: ${travelDate.toLocaleDateString()} ${route.departure ? "- " + route.departure : ""}`
    );
    pdf.text(`Seats: ${reservation.seats.join(", ")}`);
    pdf.text(`Amount: LKR ${reservation.totalAmount?.toFixed(2) || "0.00"}`);

    pdf.moveDown();
    pdf.moveTo(pdf.x, pdf.y).lineTo(pdf.page.width - pdf.page.margins.right, pdf.y).stroke();
    pdf.moveDown();

    pdf
      .fontSize(12)
      .fillColor("#0C2442")
      .text("Scan at boarding for verification", { align: "center" });

    const qrValue = reservation.qrCode || reservation.ticketId || reservation._id.toString();
    const qrDataUrl = await QRCode.toDataURL(qrValue, { width: 300 });
    const base64Data = qrDataUrl.replace(/^data:image\/png;base64,/, "");
    const qrBuffer = Buffer.from(base64Data, "base64");

    const qrWidth = 140;
    const qrX = pdf.page.width / 2 - qrWidth / 2;
    pdf.image(qrBuffer, qrX, pdf.y + 10, { width: qrWidth });

    pdf.moveDown(6);
    pdf
      .fontSize(10)
      .fillColor("#4F4F4F")
      .text("WayGo © " + new Date().getFullYear(), { align: "center" });

    pdf.end();
  } catch (error) {
    console.error("Download ticket error:", error);
    if (!res.headersSent) {
      res.status(500).json({ error: "Failed to generate ticket" });
    }
  }
};

// GET USER RESERVATIONS
exports.getUserReservations = async (req, res) => {
  try {
    const userId = req.user._id;

    const reservations = await Reservation.find({ userId })
      .populate("routeId", "start destination departure arrival busName price")
      .populate("busId", "busNumber busName")
      .sort({ createdAt: -1 })
      .select("-__v");

    res.json(reservations);
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch reservations" });
  }
};

// GET RESERVATION BY ID
exports.getReservationById = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user._id;

    const reservation = await Reservation.findById(id)
      .populate("routeId", "start destination departure arrival busName price")
      .populate("busId", "busNumber busName")
      .populate("userId", "userName email phone");

    if (!reservation) {
      return res.status(404).json({ error: "Reservation not found" });
    }

    // Check if user has access
    const reservationOwnerId =
      reservation.userId && reservation.userId._id
        ? reservation.userId._id.toString()
        : reservation.userId.toString();

    if (req.user.userType !== "admin" && reservationOwnerId !== userId.toString()) {
      return res.status(403).json({ error: "Unauthorized" });
    }

    res.json(reservation);
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch reservation" });
  }
};

// DOWNLOAD TICKET AS PDF
exports.downloadReservationTicket = async (req, res) => {
  try {
    const { id } = req.params;
    const reservation = await Reservation.findById(id)
      .populate("routeId", "start destination departure arrival busName")
      .populate("busId", "busNumber busName")
      .populate("userId", "userName email phone");

    if (!reservation) {
      return res.status(404).json({ error: "Reservation not found" });
    }

    const isOwner =
      reservation.userId &&
      reservation.userId._id &&
      reservation.userId._id.toString() === req.user._id.toString();
    const isAdmin = req.user.userType === "admin";

    if (!isOwner && !isAdmin) {
      return res.status(403).json({ error: "Unauthorized" });
    }

    if (reservation.status !== "paid") {
      return res.status(400).json({
        error: "Ticket is not confirmed. Complete payment first.",
      });
    }

    const ticketId = reservation.ticketId || reservation._id.toString();
    const filename = `ticket_${ticketId}.pdf`;

    res.setHeader("Content-Type", "application/pdf");
    res.setHeader(
      "Content-Disposition",
      `attachment; filename="${filename}"`
    );

    const doc = new PDFDocument({ size: "A4", margin: 50 });
    doc.pipe(res);

    doc
      .fontSize(26)
      .fillColor("#0C2442")
      .text("WayGo E-Ticket", { align: "center" });
    doc.moveDown();

    doc.fontSize(16).fillColor("#000000").text(`Ticket ID: ${ticketId}`);
    doc.moveDown(0.5);

    doc.fontSize(14).text("Passenger Details", { underline: true });
    doc
      .fontSize(12)
      .text(`Name: ${reservation.userId?.userName || "N/A"}`)
      .text(`Email: ${reservation.userId?.email || "N/A"}`)
      .text(`Phone: ${reservation.userId?.phone || "N/A"}`);
    doc.moveDown();

    doc.fontSize(14).text("Route Details", { underline: true });
    const route = reservation.routeId || {};
    doc
      .fontSize(12)
      .text(`From: ${route.start || "N/A"}`)
      .text(`To: ${route.destination || "N/A"}`)
      .text(`Departure: ${route.departure || "N/A"}`)
      .text(`Arrival: ${route.arrival || "N/A"}`);
    doc.moveDown();

    doc.fontSize(14).text("Bus Details", { underline: true });
    doc
      .fontSize(12)
      .text(
        `Bus Name: ${reservation.busId?.busName || route.busName || "N/A"}`
      )
      .text(`Bus Number: ${reservation.busId?.busNumber || "N/A"}`);
    doc.moveDown();

    doc.fontSize(14).text("Reservation", { underline: true });
    const travelDate = new Date(reservation.date).toLocaleDateString();
    doc
      .fontSize(12)
      .text(`Travel Date: ${travelDate}`)
      .text(`Seats: ${reservation.seats.join(", ") || "N/A"}`)
      .text(`Amount: Rs. ${reservation.totalAmount || 0}`);
    doc.moveDown();

    const qrPayload = reservation.qrCode || ticketId;
    if (qrPayload) {
      const qrDataUrl = await QRCode.toDataURL(qrPayload);
      const qrBase64 = qrDataUrl.replace(/^data:image\/png;base64,/, "");
      const qrBuffer = Buffer.from(qrBase64, "base64");

      doc
        .fontSize(12)
        .text("Scan this QR at boarding:", { align: "center" })
        .moveDown(0.5);
      doc.image(qrBuffer, doc.page.width / 2 - 70, doc.y, {
        width: 140,
        height: 140,
      });
      doc.moveDown(8);
    }

    doc
      .fontSize(10)
      .fillColor("#555555")
      .text(
        "Please arrive at the boarding point 15 minutes early. Contact WayGo support for any assistance.",
        { align: "center" }
      );

    doc.end();
  } catch (error) {
    console.error("Download ticket error:", error);
    if (!res.headersSent) {
      res.status(500).json({ error: "Failed to generate ticket" });
    } else {
      res.end();
    }
  }
};

// VALIDATE TICKET (driver/admin)
exports.validateTicket = async (req, res) => {
  try {
    const { ticketId } = req.body;

    const reservation = await Reservation.findOne({ ticketId, status: "paid" })
      .populate("routeId", "start destination departure arrival")
      .populate("userId", "userName email phone")
      .populate("busId", "busNumber busName");

    if (!reservation) {
      return res.status(404).json({ error: "Invalid ticket" });
    }

    res.json({
      valid: true,
      reservation
    });
  } catch (error) {
    res.status(500).json({ error: "Failed to validate ticket" });
  }
};

// GET BOOKED SEATS FOR A ROUTE ON A DATE
exports.getBookedSeats = async (req, res) => {
  try {
    const { routeId, date } = req.query;

    if (!routeId || !date) {
      return res.status(400).json({ error: "Route ID and date are required" });
    }

    const searchDate = new Date(date);
    searchDate.setHours(0, 0, 0, 0);

    const reservations = await Reservation.find({
      routeId,
      date: {
        $gte: searchDate,
        $lt: new Date(searchDate.getTime() + 24 * 60 * 60 * 1000),
      },
      status: { $in: ["reserved", "paid"] },
    });

    const bookedSeats = [];
    reservations.forEach(res => {
      bookedSeats.push(...res.seats);
    });

    res.json({
      bookedSeats: [...new Set(bookedSeats)],
      count: bookedSeats.length
    });
  } catch (error) {
    console.error("Get booked seats error:", error);
    res.status(500).json({ error: "Failed to get booked seats" });
  }
};

