const admin = require("firebase-admin");

let firebaseInitialized = false;

const initializeFirebase = () => {
  if (firebaseInitialized) {
    return admin;
  }

  try {
    // Check if service account path is provided in environment
    const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
    
    if (serviceAccountPath) {
      const serviceAccount = require(serviceAccountPath);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      console.log("✅ Firebase Admin SDK initialized with service account");
    } else if (process.env.FIREBASE_PROJECT_ID) {
      // Fallback: Initialize with minimal config (for testing)
      admin.initializeApp({
        credential: admin.credential.applicationDefault(),
        projectId: process.env.FIREBASE_PROJECT_ID,
      });
      console.log("✅ Firebase Admin SDK initialized with default credentials");
    } else {
      console.warn("⚠️  Firebase not configured. Push notifications will be disabled.");
      console.warn("   Set FIREBASE_SERVICE_ACCOUNT_PATH or FIREBASE_PROJECT_ID in .env");
    }
    
    firebaseInitialized = true;
  } catch (error) {
    console.error("❌ Firebase initialization error:", error.message);
    console.warn("⚠️  Push notifications will be disabled.");
  }

  return admin;
};

const getMessaging = () => {
  if (!firebaseInitialized) {
    initializeFirebase();
  }
  
  try {
    return admin.messaging();
  } catch (error) {
    console.warn("Firebase messaging not available:", error.message);
    return null;
  }
};

module.exports = {
  initializeFirebase,
  getMessaging,
  admin,
};
