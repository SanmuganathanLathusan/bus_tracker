const mongoose = require("mongoose");

const newsSchema = new mongoose.Schema({
  title: { type: String, required: true },
  description: { type: String, required: true },
  imageUrl: { type: String },
  type: { type: String, enum: ["Info", "Warning", "Offer"], default: "Info" },
  status: { type: String, enum: ["Draft", "Published", "Active"], default: "Draft" },
  postedBy: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  publishDate: { type: Date },
  expiryDate: { type: Date },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model("News", newsSchema);

