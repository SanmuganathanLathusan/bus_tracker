const Maintenance = require("../models/Maintenance");
const Bus = require("../models/Bus");

// CREATE MAINTENANCE REPORT
exports.createReport = async (req, res) => {
  try {
    const driverId = req.user._id;
    const { busId, issueType, description } = req.body;
    const imageUrl = req.file ? req.file.path : undefined;

    const bus = await Bus.findById(busId);
    if (!bus || bus.driverId.toString() !== driverId.toString()) {
      return res.status(403).json({ error: "Unauthorized" });
    }

    const report = await Maintenance.create({
      driverId,
      busId,
      issueType,
      description,
      imageUrl,
      status: "unsent",
    });

    res.status(201).json({
      message: "Maintenance report created successfully",
      report
    });
  } catch (error) {
    res.status(500).json({ error: "Failed to create maintenance report" });
  }
};

// SUBMIT REPORT TO ADMIN
exports.submitReport = async (req, res) => {
  try {
    const { reportId } = req.params;
    const driverId = req.user._id;

    const report = await Maintenance.findOne({ _id: reportId, driverId });
    if (!report) {
      return res.status(404).json({ error: "Report not found" });
    }

    report.status = "pending";
    await report.save();

    res.json({
      message: "Report submitted to admin successfully",
      report
    });
  } catch (error) {
    res.status(500).json({ error: "Failed to submit report" });
  }
};

// GET DRIVER REPORTS
exports.getDriverReports = async (req, res) => {
  try {
    const driverId = req.user._id;

    const reports = await Maintenance.find({ driverId })
      .populate("busId", "busNumber busName")
      .populate("resolvedBy", "userName")
      .sort({ createdAt: -1 })
      .select("-__v");

    res.json(reports);
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch reports" });
  }
};

// GET REPORT BY ID
exports.getReportById = async (req, res) => {
  try {
    const { id } = req.params;
    const driverId = req.user._id;

    const report = await Maintenance.findById(id)
      .populate("busId", "busNumber busName")
      .populate("driverId", "userName email")
      .populate("resolvedBy", "userName");

    if (!report) {
      return res.status(404).json({ error: "Report not found" });
    }

    // Check authorization
    if (req.user.userType !== "admin" && report.driverId.toString() !== driverId.toString()) {
      return res.status(403).json({ error: "Unauthorized" });
    }

    res.json(report);
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch report" });
  }
};

// GET ALL REPORTS (admin)
exports.getAllReports = async (req, res) => {
  try {
    const { status } = req.query;

    const query = {};
    if (status) {
      query.status = status;
    }

    const reports = await Maintenance.find(query)
      .populate("busId", "busNumber busName")
      .populate("driverId", "userName email")
      .populate("resolvedBy", "userName")
      .sort({ createdAt: -1 })
      .select("-__v");

    res.json(reports);
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch reports" });
  }
};

// RESOLVE REPORT (admin)
exports.resolveReport = async (req, res) => {
  try {
    const { id } = req.params;

    const report = await Maintenance.findById(id);
    if (!report) {
      return res.status(404).json({ error: "Report not found" });
    }

    report.status = "resolved";
    report.resolvedBy = req.user._id;
    report.resolvedAt = new Date();
    await report.save();

    res.json({
      message: "Report resolved successfully",
      report
    });
  } catch (error) {
    res.status(500).json({ error: "Failed to resolve report" });
  }
};

