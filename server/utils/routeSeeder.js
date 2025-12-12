// Utility script to seed route path data
// Run this script to populate route paths in the database

const mongoose = require('mongoose');
const Route = require('../models/Route');
require('dotenv').config();

// Connect to MongoDB
mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/waygo', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

// Sample route paths for major cities in Sri Lanka
const routePaths = [
  {
    start: 'Colombo',
    destination: 'Kandy',
    path: [
      { lat: 6.9271, lng: 79.8612 }, // Colombo
      { lat: 7.0803, lng: 80.0704 }, // Kadawatha
      { lat: 7.1571, lng: 80.1102 }, // Kadawala
      { lat: 7.2083, lng: 79.8358 }, // Negombo
      { lat: 7.2906, lng: 80.6337 }, // Kandy
    ]
  },
  {
    start: 'Colombo',
    destination: 'Galle',
    path: [
      { lat: 6.9271, lng: 79.8612 }, // Colombo
      { lat: 6.7138, lng: 79.9072 }, // Panadura
      { lat: 6.5773, lng: 79.9884 }, // Kalutara
      { lat: 6.4278, lng: 80.0115 }, // Beruwala
      { lat: 6.2333, lng: 80.0500 }, // Aluthgama
      { lat: 6.0329, lng: 80.2170 }, // Galle
    ]
  },
  {
    start: 'Kandy',
    destination: 'Jaffna',
    path: [
      { lat: 7.2906, lng: 80.6337 }, // Kandy
      { lat: 7.8731, lng: 80.7718 }, // Central Hill Country
      { lat: 8.3114, lng: 80.4037 }, // Anuradhapura
      { lat: 8.7679, lng: 80.4840 }, // Vavuniya
      { lat: 9.6615, lng: 80.0255 }, // Jaffna
    ]
  },
  {
    start: 'Colombo',
    destination: 'Matara',
    path: [
      { lat: 6.9271, lng: 79.8612 }, // Colombo
      { lat: 6.7138, lng: 79.9072 }, // Panadura
      { lat: 6.5773, lng: 79.9884 }, // Kalutara
      { lat: 6.4278, lng: 80.0115 }, // Beruwala
      { lat: 6.2333, lng: 80.0500 }, // Aluthgama
      { lat: 6.0329, lng: 80.2170 }, // Galle
      { lat: 5.9549, lng: 80.5550 }, // Matara
    ]
  }
];

async function seedRoutePaths() {
  try {
    console.log('Seeding route paths...');
    
    for (const routePath of routePaths) {
      // Find route by start and destination
      const route = await Route.findOne({
        start: routePath.start,
        destination: routePath.destination
      });
      
      if (route) {
        // Update route with path data
        route.path = routePath.path;
        await route.save();
        console.log(`Updated path for route: ${routePath.start} → ${routePath.destination}`);
      } else {
        console.log(`Route not found: ${routePath.start} → ${routePath.destination}`);
      }
    }
    
    console.log('Route path seeding completed!');
    process.exit(0);
  } catch (error) {
    console.error('Error seeding route paths:', error);
    process.exit(1);
  }
}

// Run the seeder
seedRoutePaths();