const express = require("express");
const router = express.Router();
const multer = require("multer");
const path = require("path");
const authMiddleware = require("../middleware/authMiddleware");
const {
  createReport,
  submitReport,
  getDriverReports,
  getReportById,
  getAllReports,
  resolveReport
} = require("../controllers/maintenanceController");

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, "uploads/maintenance/");
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1E9);
    cb(null, "maintenance-" + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({ storage });

// All routes require authentication
router.use(authMiddleware);

// Driver routes
router.post("/", upload.single("image"), createReport);
router.post("/:reportId/submit", submitReport);
router.get("/my-reports", getDriverReports);
router.get("/:id", getReportById);

// Admin routes
router.get("/admin/all", getAllReports);
router.put("/admin/:id/resolve", resolveReport);

module.exports = router;

