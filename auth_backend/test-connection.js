// Quick test script to verify backend setup
const mongoose = require('mongoose');
require('dotenv').config();

async function testConnection() {
  console.log('🔍 Testing MongoDB connection...');
  console.log('📍 MongoDB URI:', process.env.MONGODB_URI || 'Not set');
  
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/waygo', {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log('✅ MongoDB Connected Successfully!');
    
    // Test database operations
    const collections = await mongoose.connection.db.listCollections().toArray();
    console.log('📦 Collections found:', collections.length);
    
    if (collections.length > 0) {
      console.log('   Collections:', collections.map(c => c.name).join(', '));
    }
    
    await mongoose.connection.close();
    console.log('✅ Test completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Connection failed:', error.message);
    console.log('\n💡 Troubleshooting:');
    console.log('   1. Make sure MongoDB is running');
    console.log('   2. Check MONGODB_URI in .env file');
    console.log('   3. Try: mongosh (to test MongoDB directly)');
    process.exit(1);
  }
}

testConnection();

