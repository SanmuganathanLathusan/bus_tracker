import 'package:flutter/material.dart';
import 'package:waygo/utils/app_colors.dart';
import 'package:waygo/utils/app_text_styles.dart';
import '../widgets/chart_widget.dart';

class PerformancePage extends StatelessWidget {
  const PerformancePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 150, 208, 245),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Title ---
            Text("Performance Analytics", style: AppTextStyles.heading),
            const SizedBox(height: 16),

            // --- Stats Row 1 ---
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: "Trips Completed",
                    value: "3",
                    icon: Icons.directions_bus,
                    color: AppColors.accentPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    title: "Punctuality",
                    value: "95%",
                    icon: Icons.schedule,
                    color: AppColors.accentSuccess,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // --- Stats Row 2 ---
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: "Average Rating",
                    value: "4.7⭐",
                    icon: Icons.star,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    title: "Distance Travelled",
                    value: "248 km",
                    icon: Icons.map,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- Chart Section ---
            Text("Weekly Performance", style: AppTextStyles.subHeading),
            const SizedBox(height: 10),
            Card(
              elevation: 3,
              shadowColor: AppColors.shadowLight,
              color: AppColors.backgroundSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(height: 200, child: ChartWidget()),
              ),
            ),

            const SizedBox(height: 24),

            // --- Ratings Section ---
            Text("Recent Ratings", style: AppTextStyles.subHeading),
            const SizedBox(height: 10),

            _buildRatingCard(
              passenger: "Alice Johnson",
              rating: 5,
              comment: "Great driver, very punctual!",
              date: "Oct 30, 2025",
            ),
            _buildRatingCard(
              passenger: "John Silva",
              rating: 4,
              comment: "Good service, bus was clean.",
              date: "Oct 29, 2025",
            ),
            _buildRatingCard(
              passenger: "Nimal Fernando",
              rating: 5,
              comment: "Excellent driving, felt safe.",
              date: "Oct 28, 2025",
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shadowColor: AppColors.shadowLight,
      color: AppColors.backgroundSecondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: AppTextStyles.bodySmall)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.title.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingCard({
    required String passenger,
    required int rating,
    required String comment,
    required String date,
  }) {
    return Card(
      elevation: 2,
      shadowColor: AppColors.shadowLight,
      color: AppColors.backgroundSecondary,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header (Passenger + Stars) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(passenger, style: AppTextStyles.subHeading),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.orange,
                      size: 16,
                    );
                  }),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // --- Comment ---
            Text(comment, style: AppTextStyles.bodySmall),
            const SizedBox(height: 8),

            // --- Date ---
            Text(date, style: AppTextStyles.caption.copyWith(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
