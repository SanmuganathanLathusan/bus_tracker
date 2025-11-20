const User = require("../models/User");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const { OAuth2Client } = require("google-auth-library");

const JWT_SECRET = process.env.JWT_SECRET || "mysecretkey";

// SIGN UP
exports.register = async (req, res) => {
  try {
    const { userType, userName, phone, email, password } = req.body;
    console.log("user", userName);
    
    if (!userType || !["passenger", "driver", "admin"].includes(userType)) {
      return res.status(400).json({ error: "User type must be passenger, driver, or admin" });
    }

    const existingUser = await User.findOne({ email });
    if (existingUser) return res.status(400).json({ error: "Email already registered" });

    const hashedPassword = await bcrypt.hash(password, 10);

    const user = await User.create({
      userType,
      userName,
      phone,
      email,
      password: hashedPassword
    });

    res.status(201).json({
      message: "User registered successfully",
      user: {
        id: user._id,
        userType: user.userType,
        userName: user.userName,
        email: user.email
      }
    });
  } catch (error) {
    res.status(500).json({ error: "Registration failed" });
  }
};

// SIGN IN
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email });
    if (!user) return res.status(401).json({ error: "Invalid credentials" });

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(401).json({ error: "Invalid credentials" });

    const token = jwt.sign(
      { id: user._id, userType: user.userType, email: user.email },
      JWT_SECRET,
      { expiresIn: "24h" }
    );

    // Determine dashboard route based on user type
    let dashboardRoute;
    switch (user.userType) {
      case "passenger":
        dashboardRoute = "/passenger-dashboard";
        break;
      case "driver":
        dashboardRoute = "/driver-dashboard";
        break;
      case "admin":
        dashboardRoute = "/admin-dashboard";
        break;
      default:
        dashboardRoute = "/dashboard";
    }

    res.json({
      token,
      user: {
        id: user._id,
        userType: user.userType,
        userName: user.userName,
        email: user.email
      },
      redirect: dashboardRoute
    });
  } catch (error) {
    res.status(500).json({ error: "Login failed" });
  }
};

// GET USER PROFILE
exports.getProfile = async (req, res) => {
  try {
    const user = req.user;
    res.json({
      user: {
        id: user._id,
        userType: user.userType,
        userName: user.userName,
        email: user.email,
        phone: user.phone,
        profileImage: user.profileImage
      }
    });
  } catch (error) {
    res.status(500).json({ error: "Failed to get profile" });
  }
};

// GOOGLE SIGN IN
exports.googleSignIn = async (req, res) => {
  try {
    const { googleToken, userType } = req.body;
    
    if (!googleToken) {
      return res.status(400).json({ error: "Google token is required" });
    }

    // Verify Google token
    const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);
    
    const ticket = await client.verifyIdToken({
      idToken: googleToken,
      audience: process.env.GOOGLE_CLIENT_ID,
    });
    
    const payload = ticket.getPayload();
    const { email, name, picture, sub: googleId } = payload;

    // Find or create user
    let user = await User.findOne({ email });
    
    if (!user) {
      // Create new user
      user = await User.create({
        email,
        userName: name,
        userType: userType || "passenger",
        phone: "", // Google doesn't provide phone
        googleId,
        isGoogleUser: true,
        profileImage: picture,
        password: "" // No password for Google users
      });
    } else {
      // Update existing user with Google info if needed
      if (!user.googleId) {
        user.googleId = googleId;
        user.isGoogleUser = true;
        if (!user.profileImage) user.profileImage = picture;
        await user.save();
      }
    }

    const token = jwt.sign(
      { id: user._id, userType: user.userType, email: user.email },
      JWT_SECRET,
      { expiresIn: "24h" }
    );

    let dashboardRoute;
    switch (user.userType) {
      case "passenger":
        dashboardRoute = "/passenger-dashboard";
        break;
      case "driver":
        dashboardRoute = "/driver-dashboard";
        break;
      case "admin":
        dashboardRoute = "/admin-dashboard";
        break;
      default:
        dashboardRoute = "/dashboard";
    }

    res.json({
      token,
      user: {
        id: user._id,
        userType: user.userType,
        userName: user.userName,
        email: user.email,
        profileImage: user.profileImage
      },
      redirect: dashboardRoute
    });
  } catch (error) {
    console.error("Google sign in error:", error);
    res.status(500).json({ error: "Google sign in failed" });
  }
};

// UPDATE PROFILE
exports.updateProfile = async (req, res) => {
  try {
    const userId = req.user._id;
    const { userName, phone } = req.body;
    const profileImage = req.file ? req.file.path : undefined;

    const updateData = {};
    if (userName) updateData.userName = userName;
    if (phone) updateData.phone = phone;
    if (profileImage) updateData.profileImage = profileImage;

    const user = await User.findByIdAndUpdate(
      userId,
      updateData,
      { new: true }
    ).select("-password");

    res.json({
      message: "Profile updated successfully",
      user
    });
  } catch (error) {
    res.status(500).json({ error: "Failed to update profile" });
  }
};
