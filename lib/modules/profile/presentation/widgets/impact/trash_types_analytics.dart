import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class TrashTypesAnalytics extends StatefulWidget {
  final String? selectedArea;
  final String selectedTrendPeriod;

  const TrashTypesAnalytics({
    super.key,
    this.selectedArea,
    required this.selectedTrendPeriod,
  });

  @override
  State<TrashTypesAnalytics> createState() => _TrashTypesAnalyticsState();
}

class _TrashTypesAnalyticsState extends State<TrashTypesAnalytics> {
  bool _showLegend = false;
  int _currentPage = 0;
  static const int _itemsPerPage = 6; // Show 6 items per page
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trashData = _getTrashTypesData();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with legend toggle
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.category,
                    color: Colors.purple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Trash Types',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'breakdown',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.normal,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                // Legend toggle button
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showLegend = !_showLegend;
                    });
                  },
                  icon: Icon(
                    _showLegend ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  tooltip: _showLegend ? 'Hide Legend' : 'Show Legend',
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Context info
            Text(
              '${_getTrendPeriodDescription(widget.selectedTrendPeriod)} • ${_getAreaLabel(widget.selectedArea)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 11,
              ),
            ),

            const SizedBox(height: 16),

            // Full-width chart
            SizedBox(
              height: 200, // Fixed height for chart
              width: double.infinity,
              child: PieChart(
                PieChartData(
                  sections: _buildPieChartSections(trashData),
                  centerSpaceRadius: 60, // Larger center space for full-width
                  sectionsSpace: 2,
                  pieTouchData: PieTouchData(
                    enabled: true,
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      // Add haptic feedback or other interactions
                    },
                  ),
                ),
              ),
            ),

            // Animated legend
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                margin: const EdgeInsets.only(top: 16),
                child: _buildLegendSection(theme, trashData),
              ),
              crossFadeState: _showLegend
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),

            const SizedBox(height: 12),

            // Summary stats - unchanged
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      theme,
                      'Most Common',
                      _getMostCommonTypeShort(trashData),
                      Icons.trending_up,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      theme,
                      'Types',
                      '${trashData.length}',
                      Icons.category,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      theme,
                      'Items',
                      '${_getTotalItems(trashData)}',
                      Icons.inventory,
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

  Widget _buildLegendSection(
    ThemeData theme,
    List<Map<String, dynamic>> trashData,
  ) {
    final totalPages = (trashData.length / _itemsPerPage).ceil();
    final hasMultiplePages = totalPages > 1;

    return Column(
      children: [
        // Legend header with item count
        Row(
          children: [
            Icon(
              Icons.list,
              size: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            const SizedBox(width: 6),
            Text(
              'Breakdown Details',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (hasMultiplePages)
              Text(
                '${_currentPage + 1} of $totalPages',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 11,
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Legend content with fixed height container
        SizedBox(
          height: _calculateLegendHeight(trashData, totalPages),
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: totalPages,
            itemBuilder: (context, pageIndex) {
              return _buildLegendPage(theme, trashData, pageIndex);
            },
          ),
        ),

        // Page indicators (only show if multiple pages)
        if (hasMultiplePages) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Previous button
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    onPressed: _currentPage > 0
                        ? () {
                            setState(() {
                              _currentPage--;
                            });
                            _pageController.animateToPage(
                              _currentPage,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    icon: Icon(
                      Icons.chevron_left,
                      size: 16,
                      color: _currentPage > 0
                          ? theme.colorScheme.onSurface.withOpacity(0.7)
                          : theme.colorScheme.onSurface.withOpacity(0.3),
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),

                // Page dots with constraints
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 80),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(totalPages, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: index == _currentPage
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),
                ),

                // Next button
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    onPressed: _currentPage < totalPages - 1
                        ? () {
                            setState(() {
                              _currentPage++;
                            });
                            _pageController.animateToPage(
                              _currentPage,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    icon: Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: _currentPage < totalPages - 1
                          ? theme.colorScheme.onSurface.withOpacity(0.7)
                          : theme.colorScheme.onSurface.withOpacity(0.3),
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLegendPage(
    ThemeData theme,
    List<Map<String, dynamic>> trashData,
    int pageIndex,
  ) {
    final startIndex = pageIndex * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, trashData.length);
    final pageItems = trashData.sublist(startIndex, endIndex);

    return Column(
      children: [
        // Grid layout for better organization
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 4.5, // Wider ratio for horizontal layout
            crossAxisSpacing: 8,
            mainAxisSpacing: 6,
          ),
          itemCount: pageItems.length,
          itemBuilder: (context, index) {
            final item = pageItems[index];
            return _buildCompactLegendItem(
              theme,
              item['type'] as String,
              item['percentage'] as double,
              item['color'] as Color,
              item['count'] as int,
            );
          },
        ),
      ],
    );
  }

  double _calculateLegendHeight(
    List<Map<String, dynamic>> trashData,
    int totalPages,
  ) {
    // Calculate height based on maximum items per page to prevent overflow
    const maxItemsPerPage = _itemsPerPage;
    final maxRows = (maxItemsPerPage / 2).ceil();
    const itemHeight = 32.0;
    const spacing = 6.0;

    return (maxRows * itemHeight) + ((maxRows - 1) * spacing) + 16;
  }

  Widget _buildCompactLegendItem(
    ThemeData theme,
    String type,
    double percentage,
    Color color,
    int count,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ), // More compact
      decoration: BoxDecoration(
        color: color.withOpacity(0.08), // Softer background
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              type,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 10, // Smaller for better fit
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getTrashTypesData() {
    // Sample data based on selected area and time period
    // In real app, this would come from your data source
    return [
      {
        'type': 'Plastic Bottles',
        'percentage': 25.0,
        'count': 45,
        'color': Colors.blue,
      },
      {
        'type': 'Plastic Bags',
        'percentage': 24.0,
        'count': 43,
        'color': Colors.green,
      },
      {
        'type': 'Food Containers',
        'percentage': 18.0,
        'count': 32,
        'color': Colors.orange,
      },
      {
        'type': 'Cigarette Butts',
        'percentage': 15.0,
        'count': 27,
        'color': Colors.red,
      },
      {
        'type': 'Paper/Cardboard',
        'percentage': 10.0,
        'count': 18,
        'color': Colors.brown,
      },
      {
        'type': 'Metal Cans',
        'percentage': 5.0,
        'count': 9,
        'color': Colors.grey[600]!,
      },
      {'type': 'Others', 'percentage': 3.0, 'count': 6, 'color': Colors.grey},
    ];
  }

  List<PieChartSectionData> _buildPieChartSections(
    List<Map<String, dynamic>> data,
  ) {
    return data.map((item) {
      return PieChartSectionData(
        color: item['color'] as Color,
        value: item['percentage'] as double,
        title: '${(item['percentage'] as double).toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegendItem(
    ThemeData theme,
    String type,
    double percentage,
    Color color,
    int count,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5), // Reduced spacing
      child: Row(
        children: [
          Container(
            width: 8, // Smaller indicator
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6), // Reduced spacing
          Expanded(
            child: Text(
              type,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 11, // Smaller font
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${percentage.toStringAsFixed(0)}%', // No decimal for cleaner look
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12, // Smaller icon
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                  fontSize: 10, // Smaller font
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2), // Reduced spacing
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _getMostCommonTypeShort(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 'N/A';

    final mostCommon = data.reduce(
      (a, b) =>
          (a['percentage'] as double) > (b['percentage'] as double) ? a : b,
    );

    String type = mostCommon['type'] as String;
    // Shorten long names
    if (type.length > 12) {
      return type.split(' ').first; // Take first word if too long
    }
    return type;
  }

  int _getTotalItems(List<Map<String, dynamic>> data) {
    return data.fold(0, (sum, item) => sum + (item['count'] as int));
  }

  String _getTrendPeriodDescription(String period) {
    switch (period) {
      case 'day':
        return 'Last 7 days';
      case 'week':
        return 'Last 8 weeks';
      case 'month':
        return 'Last 12 months';
      case 'year':
        return 'Last 5 years';
      default:
        return 'Last 7 days';
    }
  }

  String _getAreaLabel(String? area) {
    if (area == null) return 'all areas';
    return area
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) =>
              word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '',
        )
        .join(' ');
  }
}
