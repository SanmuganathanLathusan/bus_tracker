import 'package:flutter/material.dart';
import 'package:waygo/utils/app_colors.dart';
import 'package:waygo/utils/app_text_styles.dart';

typedef SeatSelectionChanged = void Function(List<int> selectedSeats);

class SeatLayout extends StatefulWidget {
  final int totalSeats;
  final List<int> bookedSeats;
  final SeatSelectionChanged? onSelectionChanged;

  const SeatLayout({
    super.key,
    required this.totalSeats,
    this.bookedSeats = const [],
    this.onSelectionChanged,
  });

  @override
  State<SeatLayout> createState() => _SeatLayoutState();
}

class _SeatLayoutState extends State<SeatLayout> {
  final List<int> selected = [];

  bool _isBooked(int n) => widget.bookedSeats.contains(n);
  bool _isSelected(int n) => selected.contains(n);

  void _toggle(int n) {
    if (_isBooked(n)) return;
    setState(() {
      if (_isSelected(n)) {
        selected.remove(n);
      } else {
        selected.add(n);
      }
      widget.onSelectionChanged?.call(List<int>.from(selected));
    });
  }

  // Tunable layout params
  static const double _tileSize = 48.0;
  static const double _seatSpacing = 10.0;
  static const double _aisleWidth =
      24.0; // fixed aisle width between left & right blocks
  static const double _trailingPadding = 20.0; // increased slightly for safety
  static const double _safetyBuffer = 4.0; // avoids tiny sub-pixel overflow

  // Compute a consistent content width used by all rows (so they align)
  double _rowContentWidth() {
    final leftBlockWidth = 2 * _tileSize + _seatSpacing; // 2 seats + gap
    final rightBlockWidth =
        3 * _tileSize + 2 * _seatSpacing; // 3 seats + 2 gaps
    return leftBlockWidth +
        _aisleWidth +
        rightBlockWidth +
        _trailingPadding +
        _safetyBuffer;
  }

  Widget seatTile(int seatNumber) {
    final booked = _isBooked(seatNumber);
    final chosen = _isSelected(seatNumber);

    Color bg;
    Color borderColor;
    Color textColor;

    if (booked) {
      bg = AppColors.accentWarning;
      borderColor = AppColors.accentWarningDark;
      textColor = AppColors.textDark;
    } else if (chosen) {
      bg = AppColors.accentSuccess;
      borderColor = AppColors.accentSuccessDark;
      textColor = AppColors.textLight;
    } else {
      bg = AppColors.waygoWhite;
      borderColor = AppColors.borderLight;
      textColor = AppColors.textDark;
    }

    return GestureDetector(
      onTap: booked ? null : () => _toggle(seatNumber),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: _tileSize,
        width: _tileSize,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Stack(
          children: [
            // Seat back
            Positioned(
              top: 4,
              left: 8,
              right: 8,
              child: Container(
                height: _tileSize * 0.55,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
              ),
            ),

            // Armrests
            Positioned(
              top: 8,
              left: 2,
              child: Container(
                height: _tileSize * 0.35,
                width: 6,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 2,
              child: Container(
                height: _tileSize * 0.35,
                width: 6,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Seat bottom
            Positioned(
              bottom: 4,
              left: 10,
              right: 10,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Seat number
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '$seatNumber',
                  style: AppTextStyles.body.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // build rows while using a rowWidth provided by the parent (so alignment is consistent)
  List<Widget> buildRows(BuildContext context, double rowWidth) {
    final rows = <Widget>[];

    // convenience measurements
    final leftBlockWidth = 2 * _tileSize + _seatSpacing; // width of left block
    // width of right block

    // Main 9 rows: 2 seats left + 3 seats right
    for (int row = 0; row < 9; row++) {
      int leftStart = row * 5 + 1; // 1,6,11,...
      int rightStart = row * 5 + 3; // 3,8,13,...

      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Container(
            width: rowWidth,
            // Use alignment to keep left side anchored
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left block (2 seats)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    seatTile(leftStart),
                    SizedBox(width: _seatSpacing),
                    seatTile(leftStart + 1),
                  ],
                ),

                // Aisle spacer (fixed)
                SizedBox(width: _aisleWidth),

                // Right block (3 seats)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    seatTile(rightStart),
                    SizedBox(width: _seatSpacing),
                    seatTile(rightStart + 1),
                    SizedBox(width: _seatSpacing),
                    seatTile(rightStart + 2),
                  ],
                ),

                // trailing fixed padding to keep content inside width
                SizedBox(width: _trailingPadding),
              ],
            ),
          ),
        ),
      );
    }

    // Rear Section Row 1 (46–48): align under the right block (same content width)
    rows.add(
      Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Container(
          width: rowWidth,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Empty left block area so the 46-48 align under the right block
              SizedBox(width: leftBlockWidth),
              // aisle
              SizedBox(width: _aisleWidth),
              // place 3 seats (46-48) under the right block
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  seatTile(46),
                  SizedBox(width: _seatSpacing),
                  seatTile(47),
                  SizedBox(width: _seatSpacing),
                  seatTile(48),
                ],
              ),
              SizedBox(width: _trailingPadding),
            ],
          ),
        ),
      ),
    );

    // Rear Section Row 2: 6 seats (49–54) — center the six seats inside the same content width
    // This positions the back 6-seat group so their spacing lines up with the columns above.
    rows.add(
      Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 12),
        child: Container(
          width: rowWidth,
          child: Column(
            children: [
              const Divider(thickness: 1, height: 16),
              const SizedBox(height: 8),
              // Compute left padding so the 6 seats align visually with the grid:
              // We center the 6-seat group's total width within (leftBlock + aisle + rightBlock).
              Builder(
                builder: (context) {
                  final groupWidth = 6 * _tileSize + 5 * _seatSpacing;
                  // Available area where columns sit (exclude trailing padding)
                  final availableWidth = rowWidth - _trailingPadding;
                  // center the group in the available width
                  final leftPad = (availableWidth - groupWidth) / 2;
                  return Padding(
                    padding: EdgeInsets.only(left: leftPad > 0 ? leftPad : 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        seatTile(49),
                        SizedBox(width: _seatSpacing),
                        seatTile(50),
                        SizedBox(width: _seatSpacing),
                        seatTile(51),
                        SizedBox(width: _seatSpacing),
                        seatTile(52),
                        SizedBox(width: _seatSpacing),
                        seatTile(53),
                        SizedBox(width: _seatSpacing),
                        seatTile(54),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Back Row',
                style: AppTextStyles.body.copyWith(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder to decide whether the seat map needs horizontal scrolling.
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final contentWidth = _rowContentWidth();

        // If contentWidth > viewportWidth -> we need horizontal scrolling; otherwise stretch to viewport.
        final rowWidth = contentWidth > viewportWidth
            ? contentWidth
            : viewportWidth;

        return Column(
          children: [
            // Legend
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _legendItem(
                    AppColors.waygoWhite,
                    'Available',
                    AppColors.borderLight,
                  ),
                  _legendItem(
                    AppColors.accentWarning,
                    'Booked',
                    AppColors.accentWarningDark,
                  ),
                  _legendItem(
                    AppColors.accentSuccess,
                    'Selected',
                    AppColors.accentSuccessDark,
                  ),
                ],
              ),
            ),

            const Divider(height: 1),
            const SizedBox(height: 16),

            // Driver section indicator
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.accentPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.accentPrimary.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.drive_eta, size: 18, color: AppColors.accentDark),
                  const SizedBox(width: 8),
                  Text(
                    'Driver',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.accentDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Seat layout grid — single synchronized horizontal scroller when needed
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                trackVisibility: false,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  // If rowWidth == viewportWidth, scrolling is harmless but not needed.
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: rowWidth),
                    child: SingleChildScrollView(
                      // vertical scroll for rows; the rows themselves have the same width
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: buildRows(context, rowWidth),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _legendItem(Color color, String label, Color borderColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor, width: 2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
