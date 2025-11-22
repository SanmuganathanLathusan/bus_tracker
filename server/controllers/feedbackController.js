const Feedback = require("../models/Feedback");

// CREATE FEEDBACK
exports.createFeedback = async (req, res) => {
  try {
    const userId = req.user._id;
    const { type, subject, message } = req.body;

    const feedback = await Feedback.create({
      userId,
      userType: req.user.userType,
      type,
      subject,
      message,
      status: "pending",
    });

    res.status(201).json({
      message: "Feedback submitted successfully",
      feedback
    });
  } catch (error) {
    res.status(500).json({ error: "Failed to submit feedback" });
  }
};

// GET USER FEEDBACK
exports.getUserFeedback = async (req, res) => {
  try {
    const userId = req.user._id;

    const feedbacks = await Feedback.find({ userId })
      .sort({ createdAt: -1 })
      .select("-__v");

    res.json(feedbacks);
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch feedback" });
  }
};

// GET ALL FEEDBACK (admin)
exports.getAllFeedback = async (req, res) => {
  try {
    const { userType, status, type } = req.query;

    const query = {};
    if (userType) query.userType = userType;
    if (status) query.status = status;
    if (type) query.type = type;

    const feedbacks = await Feedback.find(query)
      .populate("userId", "userName email phone userType")
      .populate("reviewedBy", "userName")
      .sort({ createdAt: -1 })
      .select("-__v");

    res.json(feedbacks);
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch feedback" });
  }
};

// GET FEEDBACK BY ID
exports.getFeedbackById = async (req, res) => {
  try {
    const { id } = req.params;

    const feedback = await Feedback.findById(id)
      .populate("userId", "userName email phone userType")
      .populate("reviewedBy", "userName");

    if (!feedback) {
      return res.status(404).json({ error: "Feedback not found" });
    }

    // Check authorization
    if (req.user.userType !== "admin" && feedback.userId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ error: "Unauthorized" });
    }

    res.json(feedback);
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch feedback" });
  }
};

// REVIEW FEEDBACK (admin)
exports.reviewFeedback = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    const feedback = await Feedback.findById(id);
    if (!feedback) {
      return res.status(404).json({ error: "Feedback not found" });
    }

    feedback.status = status;
    feedback.reviewedBy = req.user._id;
    feedback.reviewedAt = new Date();
    await feedback.save();

    res.json({
      message: "Feedback reviewed successfully",
      feedback
    });
  } catch (error) {
    res.status(500).json({ error: "Failed to review feedback" });
  }
};

