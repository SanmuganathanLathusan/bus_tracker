const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    const mongoURI = process.env.MONGODB_URI || 'mongodb://localhost:27017/waygo';
    console.log('🔍 Connecting to MongoDB...');
    
    await mongoose.connect(mongoURI);
    console.log("✅ MongoDB Connected Successfully!");
    console.log(`📍 Database: ${mongoose.connection.name}`);
  } catch (error) {
    console.error("❌ MongoDB Connection Failed:", error.message);
    console.log('\n💡 Troubleshooting:');
    console.log('   1. Make sure MongoDB is running');
    console.log('   2. Check MONGODB_URI in .env file');
    console.log('   3. Try: mongosh (to test MongoDB directly)');
    console.log('   4. Run: npm run test-connection');
    process.exit(1);
  }
};

module.exports = connectDB;
