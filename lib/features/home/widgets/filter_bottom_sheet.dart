import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Filters modal bottom sheet matching Phone 2 in the design screenshot
class FilterBottomSheet extends StatefulWidget {
  final VoidCallback? onApply;

  const FilterBottomSheet({super.key, this.onApply});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterBottomSheet(),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String _selectedContent = 'Movies';
  final Set<String> _selectedGenres = {'Adventure', 'Comedy', 'Fantasy'};
  String _selectedSort = 'Popularity';
  RangeValues _yearRange = const RangeValues(2022, 2025);
  double _minRating = 7.0;
  bool _isGenresExpanded = false;

  final List<String> _contentTypes = ['Movies', 'Series', 'TV shows', 'View all'];
  final List<String> _allGenres = [
    'Action',
    'Adventure',
    'Comedy',
    'Fantasy',
    'Crime',
    'Drama',
    'Horror',
    'Sci-Fi',
    'Animation',
    'Thriller',
    'Mystery',
    'Romance',
  ];

  final List<String> _sortOptions = [
    'Popularity',
    'Latest Release',
    'Top Rated',
    'Title (A-Z)',
  ];

  void _clearAll() {
    setState(() {
      _selectedContent = 'Movies';
      _selectedGenres.clear();
      _selectedSort = 'Popularity';
      _yearRange = const RangeValues(2020, 2025);
      _minRating = 5.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayedGenres = _isGenresExpanded
        ? _allGenres
        : _allGenres.take(7).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF14161F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ── Drag Handle ──────────────────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Header: Filters, Clear all, X button ─────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 20, 16),
            child: Row(
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _clearAll,
                  child: const Text(
                    'Clear all',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textPrimary,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.divider, height: 1),

          // ── Scrollable Filter Options ────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: [
                // ── Content section ────────────────────────────────────────
                const Text(
                  'Content',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _contentTypes.map((type) {
                    final isSelected = _selectedContent == type;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedContent = type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.chipSelected
                              : AppColors.chipUnselected,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.chipTextSelected
                                : AppColors.chipTextUnselected,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // ── Genres section ─────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Geners',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _isGenresExpanded = !_isGenresExpanded),
                      child: Text(
                        _isGenresExpanded ? 'Collapse' : 'Expand',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: displayedGenres.map((genre) {
                    final isSelected = _selectedGenres.contains(genre);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedGenres.remove(genre);
                          } else {
                            _selectedGenres.add(genre);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.chipSelected
                              : AppColors.chipUnselected,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          genre,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.chipTextSelected
                                : AppColors.chipTextUnselected,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // ── Sort By section ────────────────────────────────────────
                const Text(
                  'Sort by',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.chipUnselected,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSort,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E212B),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                      ),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      items: _sortOptions
                          .map((opt) => DropdownMenuItem(
                                value: opt,
                                child: Text(opt),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedSort = val);
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Year section ───────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Year',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${_yearRange.start.round()} – ${_yearRange.end.round()}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                RangeSlider(
                  values: _yearRange,
                  min: 2010,
                  max: 2026,
                  divisions: 16,
                  activeColor: AppColors.textPrimary,
                  inactiveColor: AppColors.chipUnselected,
                  onChanged: (values) => setState(() => _yearRange = values),
                ),

                const SizedBox(height: 16),

                // ── Rating section ─────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Rating',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppColors.star, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${_minRating.toStringAsFixed(1)}+',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Slider(
                  value: _minRating,
                  min: 0,
                  max: 10,
                  divisions: 20,
                  activeColor: AppColors.textPrimary,
                  inactiveColor: AppColors.chipUnselected,
                  onChanged: (val) => setState(() => _minRating = val),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),

          // ── Bottom Button: "452 results" ─────────────────────────────────
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: AppColors.background,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onApply?.call();
                  },
                  child: const Text(
                    '452 results',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
