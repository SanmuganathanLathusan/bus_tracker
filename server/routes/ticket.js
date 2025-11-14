const express = require("express");
const router = express.Router();
const Ticket = require("../models/Ticket");

// === BUY TICKET ===
router.post("/buy", async (req, res) => {
  try {
    const { userId, busId, route, price, seatNo } = req.body;

    const ticket = new Ticket({
      userId,
      busId,
      route,
      price,
      seatNo,
    });

    await ticket.save();

    res.status(200).json({
      success: true,
      message: "Ticket purchased successfully",
      ticket,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// === GET USER TICKETS ===
router.get("/user/:userId", async (req, res) => {
  try {
    const tickets = await Ticket.find({ userId: req.params.userId });
    res.json(tickets);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
