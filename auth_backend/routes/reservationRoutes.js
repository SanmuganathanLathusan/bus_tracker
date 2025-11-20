const express = require("express");
const router = express.Router();
const authMiddleware = require("../middleware/authMiddleware");
const {
  createReservation,
  confirmReservation,
  getUserReservations,
  getReservationById,
  downloadReservationTicket,
  validateTicket,
  getBookedSeats
} = require("../controllers/reservationController");

// Get booked seats (public - for seat selection)
router.get("/booked-seats", getBookedSeats);

// All other routes require authentication
router.use(authMiddleware);

// Create reservation (without payment)
router.post("/", createReservation);

// Confirm reservation with payment
router.post("/confirm", confirmReservation);

// Get user's reservations
router.get("/my-reservations", getUserReservations);

// Download ticket PDF
router.get("/:id/download", downloadReservationTicket);

// Get reservation by ID
router.get("/:id", getReservationById);

// Validate ticket (driver/admin)
router.post("/validate", validateTicket);

module.exports = router;
