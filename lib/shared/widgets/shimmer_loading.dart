import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';

/// Shimmer placeholder for a movie poster card
class MovieCardShimmer extends StatelessWidget {
  final double width;
  final double height;

  const MovieCardShimmer({
    super.key,
    this.width = 120,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.card,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// Shimmer placeholder for the hero banner matching the 5-card stretched deck layout
class HeroBannerShimmer extends StatelessWidget {
  const HeroBannerShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final step = ((screenWidth - 20 - 45) / 4.0).clamp(74.0, 96.0);

    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 5-Card Stacked Deck Shimmer
          SizedBox(
            height: 248,
            width: double.infinity,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Stack 4
                Positioned(
                  left: 20 + step * 4,
                  top: 0,
                  child: Container(
                    width: 162 * 0.71,
                    height: 242 * 0.71,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                // Stack 3
                Positioned(
                  left: 20 + step * 3,
                  top: 0,
                  child: Container(
                    width: 162 * 0.78,
                    height: 242 * 0.78,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                ),
                // Stack 2
                Positioned(
                  left: 20 + step * 2,
                  top: 0,
                  child: Container(
                    width: 162 * 0.85,
                    height: 242 * 0.85,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                // Stack 1
                Positioned(
                  left: 20 + step,
                  top: 0,
                  child: Container(
                    width: 162 * 0.92,
                    height: 242 * 0.92,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(19),
                    ),
                  ),
                ),
                // Active Front Card
                Positioned(
                  left: 20,
                  top: 0,
                  child: Container(
                    width: 162,
                    height: 242,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Bottom Info Row Shimmer (Logo + Subtitle left, Avatar right)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 26,
                        width: 140,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 12,
                        width: 100,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal row of movie card shimmers
class MovieRowShimmer extends StatelessWidget {
  const MovieRowShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => const MovieCardShimmer(
          width: 120,
          height: 180,
        ),
      ),
    );
  }
}
