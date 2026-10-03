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

/// Shimmer skeleton loader for the entire Movie Detail screen matching the extended backdrop hero layout
class MovieDetailShimmer extends StatelessWidget {
  const MovieDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF141722),
      highlightColor: const Color(0xFF222838),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Extended Backdrop Hero Skeleton
            Container(
              height: 440,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              color: const Color(0xFF141722),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top action row (back circle & rating pill)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFF222838),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 72,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF222838),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ],
                  ),

                  // Bottom content layered on backdrop
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Release date
                      Container(
                        width: 90,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF222838),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Movie Logo & VJ Badge
                      Row(
                        children: [
                          Container(
                            width: 140,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFF222838),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 105,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF222838),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Metadata Pills
                      Row(
                        children: [
                          for (final w in [70.0, 85.0, 58.0, 64.0]) ...[
                            Container(
                              width: w,
                              height: 28,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF222838),
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Rectangular Play Button
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF222838),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Cast Section Skeleton
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF222838),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      5,
                      (_) => Column(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: const BoxDecoration(
                              color: Color(0xFF222838),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 45,
                            height: 9,
                            decoration: BoxDecoration(
                              color: const Color(0xFF222838),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Synopsis Glass Card Skeleton
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 75,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF222838),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    height: 84,
                    decoration: BoxDecoration(
                      color: const Color(0xFF222838),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ],
              ),
            ),

            // 4. Related Movies Skeleton
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 110,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF222838),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(
                      3,
                      (_) => Container(
                        width: 100,
                        height: 140,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF222838),
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
