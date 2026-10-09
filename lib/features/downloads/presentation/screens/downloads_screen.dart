import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconly/iconly.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/downloaded_movie.dart';
import '../../../home/providers/home_providers.dart';
import '../../../movie_detail/presentation/screens/movie_detail_screen.dart';
import '../providers/downloads_provider.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  void _openMovieDetail(BuildContext context, DownloadedMovie item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MovieDetailScreen(movie: item.toMovie()),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, DownloadedMovie item) {
    showDialog<void>(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF161922).withOpacity(0.92),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.12), width: 0.8),
          ),
          title: const Text(
            'Delete Download?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${item.title}" from your device storage? You can re-download it anytime.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.80),
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white.withOpacity(0.70)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                ref.read(downloadsProvider.notifier).removeDownload(item.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: const Duration(milliseconds: 1500),
                    backgroundColor: const Color(0xFF1F2430),
                    content: Text(
                      'Deleted "${item.title}" from storage',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF161922).withOpacity(0.92),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.12), width: 0.8),
          ),
          title: const Text(
            'Clear All Downloads?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'This will permanently delete all downloaded movies from your device storage to free up space.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.80),
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white.withOpacity(0.70)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                ref.read(downloadsProvider.notifier).clearAllDownloads();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    duration: Duration(milliseconds: 1500),
                    backgroundColor: Color(0xFF1F2430),
                    content: Text(
                      'All downloaded movies cleared',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Clear All',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(downloadsProvider);
    final notifier = ref.read(downloadsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        bottom: false,
        child: downloads.isEmpty
            ? _buildEmptyState(context, ref)
            : ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
                children: [
                  // ── Storage Overview Card ─────────────────────────────────
                  _buildStorageCard(context, ref, downloads.length, notifier.formattedTotalStorage),

                  const SizedBox(height: 18),

                  // ── Section Title & Clear All ─────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            IconlyBold.download,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Downloaded Movies (${downloads.length})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => _confirmClearAll(context, ref),
                        child: Text(
                          'Clear All',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.55),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ── Downloaded Movies List ────────────────────────────────
                  ...downloads.map(
                    (item) => _buildDownloadItemCard(context, ref, item),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStorageCard(
    BuildContext context,
    WidgetRef ref,
    int count,
    String totalStorage,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          IconlyBold.download,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Offline Storage',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$count ${count == 1 ? "movie" : "movies"} available offline',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.14),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      totalStorage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 0.35,
                  minHeight: 5,
                  backgroundColor: Colors.white.withOpacity(0.10),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Stored on Internal Device',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.50),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    'Retained until deleted',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.50),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadItemCard(
    BuildContext context,
    WidgetRef ref,
    DownloadedMovie item,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: () => _openMovieDetail(context, item),
        behavior: HitTestBehavior.opaque,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              height: 104,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.10),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  // Movie Poster with Play Overlay
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 64,
                          height: 84,
                          child: CachedNetworkImage(
                            imageUrl: item.posterUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Shimmer.fromColors(
                              baseColor: const Color(0xFF1E222D),
                              highlightColor: const Color(0xFF2C3242),
                              child: Container(color: const Color(0xFF1E222D)),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: const Color(0xFF1E222D),
                              child: const Icon(Icons.movie_rounded, color: Colors.white30),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.60),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.35), width: 0.8),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 14),

                  // Metadata Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            if (item.vjName != null && item.vjName!.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C3AED).withOpacity(0.30),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.vjName!,
                                  style: const TextStyle(
                                    color: Color(0xFFC084FC),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF222838),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.quality,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.70),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF22C55E),
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.formattedFileSize,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.65),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '•  Offline Ready',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.40),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Delete Action Button
                  GestureDetector(
                    onTap: () => _confirmDelete(context, ref, item),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white.withOpacity(0.45),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: const Color(0xFF1E222D).withOpacity(0.80),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
              ),
              child: const Icon(
                IconlyBold.download,
                color: Color(0xFFF97316),
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Downloaded Movies',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Download your favorite movies and series to watch them offline anytime without internet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => navigateToBottomNavTab(context, ref, 0),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Explore Movies',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
