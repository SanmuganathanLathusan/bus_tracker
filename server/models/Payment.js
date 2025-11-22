const mongoose = require("mongoose");

const paymentSchema = new mongoose.Schema({
  reservationId: { type: mongoose.Schema.Types.ObjectId, ref: "Reservation", required: true },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  amount: { type: Number, required: true },
  method: { type: String, default: "card" },
  cardDetails: {
    last4: String,
    cardType: String,
  },
  status: { type: String, enum: ["pending", "success", "failed"], default: "pending" },
  transactionId: { type: String, unique: true },
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model("Payment", paymentSchema);
