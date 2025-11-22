import 'package:flutter/material.dart';
import './passenger_model.dart';

class PassengerTile extends StatelessWidget {
  final Passenger passenger;
  final Function(PassengerStatus) onStatusChanged;

  const PassengerTile({
    Key? key,
    required this.passenger,
    required this.onStatusChanged,
  }) : super(key: key);

  Color _getBookingColor(BookingType type) {
    switch (type) {
      case BookingType.paid:
        return Colors.green.shade100;
      case BookingType.reserved:
        return Colors.orange.shade100;
      case BookingType.none:
        return Colors.grey.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBoarded = passenger.status == PassengerStatus.boarded;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // --- Seat Number ---
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      passenger.seat,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // --- Passenger Info ---
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        passenger.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Ticket: ${passenger.ticketId}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getBookingColor(passenger.bookingType),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          passenger.bookingLabel,
                          style: TextStyle(
                            color: passenger.bookingType == BookingType.paid
                                ? Colors.green.shade800
                                : passenger.bookingType == BookingType.reserved
                                ? Colors.orange.shade800
                                : Colors.grey.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // --- Boarding Status ---
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isBoarded
                        ? Colors.green.shade100
                        : Colors.yellow.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isBoarded ? "✅ Boarded" : "⏳ Not Boarded",
                    style: TextStyle(
                      color: isBoarded
                          ? Colors.green.shade800
                          : Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // --- Buttons ---
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Passenger Details"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Name: ${passenger.name}"),
                              Text("Seat: ${passenger.seat}"),
                              Text("Ticket ID: ${passenger.ticketId}"),
                              Text("Booking: ${passenger.bookingLabel}"),
                              Text("Status: ${passenger.status.name}"),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Close"),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text("View Details"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onStatusChanged(
                      isBoarded
                          ? PassengerStatus.notBoarded
                          : PassengerStatus.boarded,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isBoarded ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isBoarded ? "Mark Absent" : "Mark Boarded"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
