const jwt = require("jsonwebtoken");
const User = require("../models/User");

const JWT_SECRET = process.env.JWT_SECRET || "mysecretkey";

const authMiddleware = async (req, res, next) => {
  try {
    // 1. Check if Authorization header exists
    const authHeader = req.header("Authorization");
    console.log("🔐 Auth Header:", authHeader ? "Present" : "Missing");
    
    if (!authHeader) {
      console.log("❌ No Authorization header");
      return res.status(401).json({ error: "Access denied. No token provided." });
    }

    // 2. Extract token
    const token = authHeader.replace("Bearer ", "");
    console.log("🔐 Token extracted:", token ? `${token.substring(0, 20)}...` : "Empty");
    
    if (!token) {
      console.log("❌ Token is empty after Bearer removal");
      return res.status(401).json({ error: "Access denied. No token provided." });
    }

    // 3. Verify token
    console.log("🔐 Verifying token with JWT_SECRET...");
    let decoded;
    try {
      decoded = jwt.verify(token, JWT_SECRET);
      console.log("✅ Token verified successfully. User ID:", decoded.id);
      console.log("🕐 Token expires at:", new Date(decoded.exp * 1000).toISOString());
    } catch (jwtError) {
      console.log("❌ JWT Verification failed:", jwtError.message);
      console.log("🔍 Error name:", jwtError.name);
      
      // Specific JWT errors with helpful messages
      if (jwtError.name === "TokenExpiredError") {
        console.log("⏰ Token expired at:", new Date(jwtError.expiredAt).toISOString());
        return res.status(401).json({ 
          error: "Token expired. Please login again.",
          code: "TOKEN_EXPIRED"
        });
      }
      if (jwtError.name === "JsonWebTokenError") {
        return res.status(401).json({ 
          error: "Invalid token format.",
          code: "INVALID_TOKEN"
        });
      }
      if (jwtError.name === "NotBeforeError") {
        return res.status(401).json({ 
          error: "Token not yet valid.",
          code: "TOKEN_NOT_ACTIVE"
        });
      }
      return res.status(401).json({ 
        error: "Invalid token.",
        code: "TOKEN_ERROR"
      });
    }

    // 4. Find user
    console.log("🔍 Looking up user:", decoded.id);
    const user = await User.findById(decoded.id).select("-password");
    
    if (!user) {
      console.log("❌ User not found in database:", decoded.id);
      return res.status(401).json({ 
        error: "Invalid token. User not found.",
        code: "USER_NOT_FOUND"
      });
    }

    console.log("✅ User found:", user.email || user._id);
    
    // 5. Attach user to request
    req.user = user;
    next();
    
  } catch (error) {
    console.error("❌ Auth Middleware Error:", error);
    res.status(401).json({ 
      error: "Invalid token.",
      code: "AUTH_ERROR",
      details: process.env.NODE_ENV === "development" ? error.message : undefined
    });
  }
};

module.exports = authMiddleware;