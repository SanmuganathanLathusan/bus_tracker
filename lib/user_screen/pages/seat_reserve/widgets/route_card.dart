import 'package:flutter/material.dart';
import 'package:waygo/utils/app_colors.dart';
import 'package:waygo/utils/app_text_styles.dart';

class RouteCard extends StatelessWidget {
  final String start;
  final String destination;
  final String departure;
  final String arrival;
  final String duration;
  final String bus;
  final VoidCallback onTap;

  const RouteCard({
    super.key,
    required this.start,
    required this.destination,
    required this.departure,
    required this.arrival,
    required this.duration,
    required this.bus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color.fromARGB(160, 229, 237, 239).withOpacity(0.65),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color.fromARGB(255, 7, 15, 17).withOpacity(0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.waygoDarkBlue.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: icon block
            Container(
              height: 45,
              width: 45,
              decoration: BoxDecoration(
                color: AppColors.waygoDarkBlue.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.directions_bus,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),

            // Middle: route details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$start → $destination",
                    style: AppTextStyles.subHeading.copyWith(
                      color: AppColors.waygoDarkBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$bus • $duration",
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.waygoDarkBlue.withOpacity(0.85),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "🕒 $departure → $arrival",
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.waygoDarkBlue.withOpacity(0.75),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // Right arrow
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.waygoDarkBlue,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
