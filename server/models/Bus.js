const mongoose = require('mongoose');

const busSchema = new mongoose.Schema({
  name: { type: String, required: true },
  latitude: { type: Number, required: true },
  longitude: { type: Number, required: true },
  routeNumber: { type: String, required: true },
  lastUpdated: { type: Date, default: Date.now },
});

module.exports = mongoose.model('Bus', busSchema);
