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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.mic_external_on_rounded,
                    size: 22,
                    color: Color(0xFFC084FC),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Available VJs',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onSeeAll,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC084FC).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFC084FC).withOpacity(0.25),
                      width: 0.8,
                    ),
                  ),
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      color: Color(0xFFC084FC),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
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
