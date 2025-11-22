const express = require("express");
const router = express.Router();
const authMiddleware = require("../middleware/authMiddleware");
const {
  getNews,
  getAllNews,
  createNews,
  updateNews,
  deleteNews,
  getNewsById
} = require("../controllers/newsController");

// Public route - get published news (for passengers)
router.get("/", getNews);

// Admin routes
router.get("/admin/all", authMiddleware, getAllNews);
router.get("/admin/:id", authMiddleware, getNewsById);
router.post("/admin", authMiddleware, createNews);
router.put("/admin/:id", authMiddleware, updateNews);
router.delete("/admin/:id", authMiddleware, deleteNews);

module.exports = router;

