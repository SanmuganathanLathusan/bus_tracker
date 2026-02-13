const express = require("express");
const router = express.Router();
const multer = require("multer");
const path = require("path");
const crypto = require("crypto");
const nodemailer = require("nodemailer");
const { register, login, getProfile, googleSignIn, updateProfile } = require("../controllers/authController");
const authMiddleware = require("../middleware/authMiddleware");
const User = require("../models/User"); // Make sure your User model is correct

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, "uploads/profiles/");
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1E9);
    cb(null, "profile-" + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({ storage });

// routes
router.post("/register", register);
router.post("/login", login);
router.post("/google-signin", googleSignIn);
router.get("/profile", authMiddleware, getProfile);
router.put("/profile", authMiddleware, upload.single("profileImage"), updateProfile);

// ===========================
// ✅ Real-time Forgot Password
// ===========================
router.post("/forgot-password", async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ message: "Email is required" });
    }

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    // Generate a secure token
    const resetToken = crypto.randomBytes(32).toString("hex");
    const resetTokenExpiry = Date.now() + 3600000; // 1 hour expiry

    // Save token & expiry to user
    user.resetPasswordToken = resetToken;
    user.resetPasswordExpires = resetTokenExpiry;
    await user.save();

    // Send email using nodemailer
    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: process.env.EMAIL_USER, // your email
        pass: process.env.EMAIL_PASS, // app password
      },
    });

    const resetUrl = `http://localhost:5501/reset-password.html?token=${resetToken}&email=${email}`;

    const mailOptions = {
      from: process.env.EMAIL_USER,
      to: email,
      subject: "WayGo App Password Reset",
      html: `
        <p>Hello,</p>
        <p>You requested a password reset. Click the link below to reset your password:</p>
        <a href="${resetUrl}">${resetUrl}</a>
        <p>This link will expire in 1 hour.</p>
      `,
    };

    await transporter.sendMail(mailOptions);

    res.status(200).json({
      message: "✅ Password reset link sent to your email!"
    });

  } catch (error) {
    console.error("Forgot password error:", error);
    res.status(500).json({ message: "Server error" });
  }
});

module.exports = router;
