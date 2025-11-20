// Initialize database with sample data
const mongoose = require('mongoose');
require('dotenv').config();

const User = require('./models/User');
const Bus = require('./models/Bus');
const Route = require('./models/Route');
const bcrypt = require('bcryptjs');

async function initDatabase() {
  try {
    console.log('🔍 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/waygo', {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log('✅ MongoDB Connected!');

    // Clear existing data (optional - comment out if you want to keep data)
    // await User.deleteMany({});
    // await Bus.deleteMany({});
    // await Route.deleteMany({});

    // Create admin user
    const adminExists = await User.findOne({ email: 'admin@waygo.com' });
    if (!adminExists) {
      const hashedPassword = await bcrypt.hash('admin123', 10);
      const admin = await User.create({
        userType: 'admin',
        userName: 'Admin User',
        phone: '+1234567890',
        email: 'admin@waygo.com',
        password: hashedPassword,
      });
      console.log('✅ Admin user created:', admin.email);
    } else {
      console.log('ℹ️  Admin user already exists');
    }

    // Create test driver
    const driverExists = await User.findOne({ email: 'driver@waygo.com' });
    if (!driverExists) {
      const hashedPassword = await bcrypt.hash('driver123', 10);
      const driver = await User.create({
        userType: 'driver',
        userName: 'Test Driver',
        phone: '+1234567891',
        email: 'driver@waygo.com',
        password: hashedPassword,
        licenseNumber: 'DL-12345',
      });
      console.log('✅ Test driver created:', driver.email);
    } else {
      console.log('ℹ️  Test driver already exists');
    }

    // Create test passenger
    const passengerExists = await User.findOne({ email: 'passenger@waygo.com' });
    if (!passengerExists) {
      const hashedPassword = await bcrypt.hash('passenger123', 10);
      const passenger = await User.create({
        userType: 'passenger',
        userName: 'Test Passenger',
        phone: '+1234567892',
        email: 'passenger@waygo.com',
        password: hashedPassword,
      });
      console.log('✅ Test passenger created:', passenger.email);
    } else {
      console.log('ℹ️  Test passenger already exists');
    }

    // Create sample buses
    const bus1 = await Bus.findOne({ busNumber: 'SP-1234' });
    if (!bus1) {
      await Bus.create({
        busNumber: 'SP-1234',
        busName: 'WayGo Deluxe',
        totalSeats: 40,
        busType: 'deluxe',
      });
      console.log('✅ Sample bus created: SP-1234');
    }

    const bus2 = await Bus.findOne({ busNumber: 'SP-5678' });
    if (!bus2) {
      await Bus.create({
        busNumber: 'SP-5678',
        busName: 'WayGo Express',
        totalSeats: 45,
        busType: 'standard',
      });
      console.log('✅ Sample bus created: SP-5678');
    }

    // Create sample routes
    const route1 = await Route.findOne({ start: 'Colombo', destination: 'Kandy' });
    if (!route1) {
      await Route.create({
        start: 'Colombo',
        destination: 'Kandy',
        departure: '08:30 AM',
        arrival: '12:15 PM',
        duration: '3h 45m',
        price: 500,
        isActive: true,
      });
      console.log('✅ Sample route created: Colombo → Kandy');
    }

    const route2 = await Route.findOne({ start: 'Galle', destination: 'Matara' });
    if (!route2) {
      await Route.create({
        start: 'Galle',
        destination: 'Matara',
        departure: '07:30 AM',
        arrival: '08:45 AM',
        duration: '1h 15m',
        price: 200,
        isActive: true,
      });
      console.log('✅ Sample route created: Galle → Matara');
    }

    console.log('\n✅ Database initialization completed!');
    console.log('\n📝 Test Credentials:');
    console.log('   Admin: admin@waygo.com / admin123');
    console.log('   Driver: driver@waygo.com / driver123');
    console.log('   Passenger: passenger@waygo.com / passenger123');
    
    await mongoose.connection.close();
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

initDatabase();

