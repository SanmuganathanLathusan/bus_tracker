const Payment = require("../models/Payment");
const Reservation = require("../models/Reservation");

// GET PAYMENT BY ID
exports.getPaymentById = async (req, res) => {
  try {
    const { id } = req.params;

    const payment = await Payment.findById(id)
      .populate("reservationId")
      .populate("userId", "userName email");

    if (!payment) {
      return res.status(404).json({ error: "Payment not found" });
    }

    res.json(payment);
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch payment" });
  }
};

// GET USER PAYMENTS
exports.getUserPayments = async (req, res) => {
  try {
    const userId = req.user._id;

    const payments = await Payment.find({ userId })
      .populate("reservationId")
      .sort({ createdAt: -1 })
      .select("-__v");

    res.json(payments);
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch payments" });
  }
};

