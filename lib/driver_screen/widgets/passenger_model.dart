enum PassengerStatus { boarded, notBoarded }

enum BookingType { paid, reserved, none }

class Passenger {
  final String ticketId;
  final String name;
  final String seat;
  final PassengerStatus status;
  final BookingType bookingType;
  final String? reservationId;

  Passenger({
    required this.ticketId,
    required this.name,
    required this.seat,
    required this.status,
    required this.bookingType,
    this.reservationId,
  });

  Passenger copyWith({PassengerStatus? status, BookingType? bookingType, String? reservationId}) {
    return Passenger(
      ticketId: ticketId,
      name: name,
      seat: seat,
      status: status ?? this.status,
      bookingType: bookingType ?? this.bookingType,
      reservationId: reservationId ?? this.reservationId,
    );
  }

  String get bookingLabel {
    switch (bookingType) {
      case BookingType.paid:
        return "Paid Ticket";
      case BookingType.reserved:
        return "Reserved (Unpaid)";
      case BookingType.none:
        return "No Booking";
    }
  }

  String get bookingColorHex {
    switch (bookingType) {
      case BookingType.paid:
        return "#2E7D32"; // Green
      case BookingType.reserved:
        return "#FB8C00"; // Orange
      case BookingType.none:
        return "#9E9E9E"; // Grey
    }
  }
}
