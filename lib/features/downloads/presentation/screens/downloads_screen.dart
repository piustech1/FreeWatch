import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconly/iconly.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/downloaded_movie.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/frosted_empty_state.dart';
import '../../../../shared/widgets/glass_dialog.dart';
import '../../../home/providers/home_providers.dart';
import '../../../movie_detail/presentation/screens/movie_detail_screen.dart';
import '../providers/downloads_provider.dart';

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(downloadsProvider.notifier).reloadDownloads();
    });
  }

  void _openMovieDetail(BuildContext context, DownloadedMovie item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MovieDetailScreen(movie: item.toMovie()),
      ),
    );
  }

  void _confirmDelete(BuildContext context, DownloadedMovie item) {
    GlassDialog.show(
      context,
      title: 'Delete Download?',
      message: 'Are you sure you want to delete "${item.title}" from your device storage? You can re-download it anytime.',
      confirmText: 'Delete',
      confirmColor: const Color(0xFFEF4444),
      onConfirm: () {
        ref.read(downloadsProvider.notifier).removeDownload(item.id);
        AppToast.show(
          context,
          'Deleted "${item.title}" from storage',
          isSuccess: false,
        );
      },
    );
  }

  void _confirmClearAll(BuildContext context) {
    GlassDialog.show(
      context,
      title: 'Clear All Downloads?',
      message: 'This will permanently delete all downloaded movies from your device storage to free up space.',
      confirmText: 'Clear All',
      confirmColor: const Color(0xFFEF4444),
      onConfirm: () {
        ref.read(downloadsProvider.notifier).clearAllDownloads();
        AppToast.show(
          context,
          'All downloaded movies cleared',
          isSuccess: false,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final downloads = ref.watch(downloadsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        bottom: false,
        child: downloads.isEmpty
            ? _buildEmptyState(context, ref)
            : ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
                children: [

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
                        onTap: () => _confirmClearAll(context),
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
                    (item) => _buildDownloadItemCard(context, item),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDownloadItemCard(
    BuildContext context,
    DownloadedMovie item,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: item.isDownloading ? null : () => _openMovieDetail(context, item),
        behavior: HitTestBehavior.opaque,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              height: 94,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // Movie Poster with Play / Downloading Overlay
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 56,
                          height: 74,
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
                          color: Colors.black.withOpacity(0.65),
                          shape: BoxShape.circle,
                        ),
                        child: item.isDownloading
                            ? const Center(
                                child: SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                                  ),
                                ),
                              )
                            : (item.isPaused || item.isFailed || item.downloadProgress < 1.0)
                                ? GestureDetector(
                                    onTap: () {
                                      ref.read(downloadsProvider.notifier).resumeDownload(item.id);
                                      AppToast.show(context, 'Resuming download for "${item.title}"', isSuccess: true);
                                    },
                                    child: const Icon(
                                      Icons.refresh_rounded,
                                      color: Color(0xFFF59E0B),
                                      size: 18,
                                    ),
                                  )
                                : const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 14),

                  // Metadata Info & Download Progress
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
                        const SizedBox(height: 8),
                        if (item.isDownloading) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: item.downloadProgress,
                              minHeight: 4,
                              backgroundColor: Colors.white.withOpacity(0.12),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Downloading ${(item.downloadProgress * 100).toInt()}%',
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ] else if (item.isPaused || item.isFailed || item.downloadProgress < 1.0) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: item.downloadProgress,
                              minHeight: 4,
                              backgroundColor: Colors.white.withOpacity(0.12),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.pause_circle_filled_rounded,
                                color: Color(0xFFF59E0B),
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Paused ${(item.downloadProgress * 100).toInt()}% • Tap to Resume',
                                style: const TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
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
                      ],
                    ),
                  ),

                  // Actions: Pause / Resume + Delete
                  if (item.isDownloading)
                    GestureDetector(
                      onTap: () {
                        ref.read(downloadsProvider.notifier).pauseDownload(item.id);
                        AppToast.show(context, 'Paused download for "${item.title}"');
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.pause_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    )
                  else if (item.isPaused || item.isFailed || item.downloadProgress < 1.0)
                    GestureDetector(
                      onTap: () {
                        ref.read(downloadsProvider.notifier).resumeDownload(item.id);
                        AppToast.show(context, 'Resuming download for "${item.title}"', isSuccess: true);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E).withOpacity(0.20),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.45), width: 0.8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_arrow_rounded, color: Color(0xFF22C55E), size: 14),
                              SizedBox(width: 2),
                              Text(
                                'Resume',
                                style: TextStyle(
                                  color: Color(0xFF22C55E),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Delete Action Button
                  GestureDetector(
                    onTap: () => _confirmDelete(context, item),
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
    return FrostedEmptyState(
      svgPath: 'assets/images/empty_downloads.svg',
      title: 'No Downloaded Movies',
      message:
          'Download your favorite Luganda dubbed movies and series to watch them offline anytime without internet.',
      actionText: 'Explore Movies',
      onActionTap: () => navigateToBottomNavTab(context, ref, 0),
    );
  }
}
