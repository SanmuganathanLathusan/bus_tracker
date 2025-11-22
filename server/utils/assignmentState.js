const Assignment = require("../models/Assignment");
const Bus = require("../models/Bus");
const User = require("../models/User");

const ACTIVE_ASSIGNMENT_STATUSES = ["pending", "accepted"];

const hasActiveDriverAssignment = async (driverId, excludeAssignmentId) => {
  if (!driverId) return false;

  const query = {
    driverId,
    status: { $in: ACTIVE_ASSIGNMENT_STATUSES },
  };

  if (excludeAssignmentId) {
    query._id = { $ne: excludeAssignmentId };
  }

  return Assignment.exists(query);
};

const hasActiveBusAssignment = async (busId, excludeAssignmentId) => {
  if (!busId) return false;

  const query = {
    busId,
    status: { $in: ACTIVE_ASSIGNMENT_STATUSES },
  };

  if (excludeAssignmentId) {
    query._id = { $ne: excludeAssignmentId };
  }

  return Assignment.exists(query);
};

const markDriverAssigned = async (driverId, assignmentId) => {
  if (!driverId || !assignmentId) return;

  await User.findByIdAndUpdate(driverId, {
    currentAssignmentId: assignmentId,
    dutyStatus: "assigned",
  });
};

const releaseDriverIfIdle = async (driverId, excludeAssignmentId) => {
  if (!driverId) return;

  const hasActive = await hasActiveDriverAssignment(driverId, excludeAssignmentId);
  if (hasActive) return;

  await User.findOneAndUpdate(
    { _id: driverId, dutyStatus: "assigned" },
    {
      currentAssignmentId: null,
      dutyStatus: "available",
    }
  );
};

const markBusAssigned = async (busId, assignmentId, scheduledDate) => {
  if (!busId || !assignmentId) return;

  await Bus.findByIdAndUpdate(busId, {
    currentAssignmentId: assignmentId,
    currentAssignmentDate: scheduledDate || new Date(),
    assignmentStatus: "assigned",
  });
};

const releaseBusIfIdle = async (busId, excludeAssignmentId) => {
  if (!busId) return;

  const hasActive = await hasActiveBusAssignment(busId, excludeAssignmentId);
  if (hasActive) return;

  await Bus.findOneAndUpdate(
    { _id: busId, assignmentStatus: "assigned" },
    {
      currentAssignmentId: null,
      currentAssignmentDate: null,
      assignmentStatus: "available",
    }
  );
};

module.exports = {
  markDriverAssigned,
  releaseDriverIfIdle,
  markBusAssigned,
  releaseBusIfIdle,
};


