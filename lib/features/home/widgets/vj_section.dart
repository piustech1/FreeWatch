import 'package:flutter/material.dart';
import '../../../data/models/vj.dart';
import 'vj_card.dart';

/// Horizontally scrolling row of Available VJs with interlocking panoramic cards.
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Available VJs',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              GestureDetector(
                onTap: onSeeAll,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Text(
                    'See all',
                    style: TextStyle(
                      color: Color(0xFFC084FC),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Horizontally Scrolling Interlocking Panoramic VJ Cards ──────────
        SizedBox(
          height: 125,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            physics: const BouncingScrollPhysics(),
            itemCount: vjs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final vj = vjs[index];
              return VjCard(
                vj: vj,
                index: index,
                onTap: () => onVjTap?.call(vj),
              );
            },
          ),
        ),
      ],
    );
  }
}
