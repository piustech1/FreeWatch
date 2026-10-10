import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/vj.dart';
import '../../../movie_grid/presentation/screens/movie_grid_screen.dart';
import '../../widgets/vj_card.dart';

/// Fullscreen vertical presentation of all Available VJs in the application.
class AllVjsScreen extends StatelessWidget {
  final List<Vj> vjs;

  const AllVjsScreen({
    super.key,
    required this.vjs,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Top Header / App Bar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                          width: 0.8,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available VJs',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Select a translator to view their translated movies',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC084FC).withOpacity(0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFC084FC).withOpacity(0.30),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      '${vjs.length} VJs',
                      style: const TextStyle(
                        color: Color(0xFFC084FC),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(
              color: Colors.white10,
              height: 1,
              thickness: 0.8,
            ),

            // ── Vertical Presentation of VJ Cards ─────────────────────────────
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                physics: const BouncingScrollPhysics(),
                itemCount: vjs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final vj = vjs[index];
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return VjCard(
                        vj: vj,
                        index: index,
                        width: constraints.maxWidth,
                        height: 116,
                        onTap: () {
                          Navigator.of(context).push(
                            MovieGridScreen.routeForVj(vj: vj),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
