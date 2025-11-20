const express = require("express");
const router = express.Router();
const multer = require("multer");
const path = require("path");
const { register, login, getProfile, googleSignIn, updateProfile } = require("../controllers/authController");
const authMiddleware = require("../middleware/authMiddleware");

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

module.exports = router;
