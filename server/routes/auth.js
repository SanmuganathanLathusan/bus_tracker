const express = require("express");
const router = express.Router();
const bcrypt = require("bcryptjs");
const User = require("../models/User");
const nodemailer = require("nodemailer");

// Temporary store for verification codes (for demo)
const codes = {};

// -------------------- Nodemailer Transporter --------------------
const transporter = nodemailer.createTransport({
  service: "gmail",   // ✅ must be "gmail"
  auth: {
    user: "waygoapp123@gmail.com",   // your Gmail
    pass: "dkakfgclwptxgmra",        // 16-char App Password (no spaces)
  },
});

// -------------------- Register --------------------
router.post("/register", async (req, res) => {
  const { name, email, password } = req.body;

  try {
    const existingUser = await User.findOne({ email });
    if (existingUser)
      return res.status(400).json({ message: "User already exists" });

    const hashedPassword = await bcrypt.hash(password, 10);
    const user = new User({ name, email, password: hashedPassword });
    await user.save();

    res.status(201).json({ message: "Registration successful!" });
  } catch (err) {
    console.error("Register error:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// -------------------- Login --------------------
router.post("/login", async (req, res) => {
  const { email, password } = req.body;

  try {
    const user = await User.findOne({ email });
    if (!user)
      return res.status(400).json({ message: "Invalid email or password" });

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch)
      return res.status(400).json({ message: "Invalid email or password" });

    res.status(200).json({
      message: "Login successful!",
      userId: user._id,
      name: user.name,
    });
  } catch (err) {
    console.error("Login error:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// -------------------- Forgot Password --------------------
router.post("/forgot-password", async (req, res) => {
  const { email } = req.body;

  try {
    const user = await User.findOne({ email });
    if (!user)
      return res.status(404).json({ message: "User with this email not found" });

    // Generate 6-digit code
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    codes[email] = code;

    // Send email
    await transporter.sendMail({
      from: '"Way_go App" <waygoapp123@gmail.com>',
      to: email,
      subject: "Way_go Password Reset Code",
      text: `Hello ${user.name},\n\nYour password reset code is: ${code}\n\nIf you did not request this, ignore this email.`,
    });

    res.status(200).json({ message: "Verification code sent to your email" });
  } catch (err) {
    console.error("Forgot Password error:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// -------------------- Verify Code --------------------
router.post("/verify-code", (req, res) => {
  const { email, code } = req.body;

  if (codes[email] && codes[email] === code) {
    return res.status(200).json({ message: "Code verified successfully" });
  } else {
    return res.status(400).json({ message: "Invalid or expired code" });
  }
});

// -------------------- Reset Password --------------------
router.post("/reset-password", async (req, res) => {
  const { email, newPassword } = req.body;

  try {
    const user = await User.findOne({ email });
    if (!user)
      return res.status(404).json({ message: "User not found" });

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    user.password = hashedPassword;
    await user.save();

    delete codes[email]; // Remove used code
    res.status(200).json({ message: "Password reset successful!" });
  } catch (err) {
    console.error("Reset Password error:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

module.exports = router;
