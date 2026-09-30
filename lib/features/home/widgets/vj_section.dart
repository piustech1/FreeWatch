import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/vj.dart';
import 'vj_card.dart';

/// Horizontally scrolling row of VJ cards matching the requested rectangular design
class VjSection extends StatelessWidget {
  final List<Vj> vjs;
  final void Function(Vj vj)? onVjTap;
  final VoidCallback? onSeeAll;

  const VjSection({
    super.key,
    required this.vjs,
    this.onVjTap,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    if (vjs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section Header ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Available Vj\'s',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              GestureDetector(
                onTap: onSeeAll,
                child: const Text(
                  'See all',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Horizontally Scrolling Rectangular VJ Cards ─────────────────────
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            physics: const BouncingScrollPhysics(),
            itemCount: vjs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final vj = vjs[index];
              return VjCard(
                vj: vj,
                onTap: () => onVjTap?.call(vj),
              );
            },
          ),
        ),
      ],
    );
  }
}
