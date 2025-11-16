// server/routes/bus.js
const express = require('express');
const { updateBusLocation, getBusLocation } = require('../controllers/busController');

const router = express.Router();

router.post('/location', updateBusLocation);   // POST for updating location
router.get('/:busId', getBusLocation);         // GET for fetching bus location

module.exports = router;
