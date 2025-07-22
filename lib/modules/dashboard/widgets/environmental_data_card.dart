import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

class EnvironmentalDataCard extends StatefulWidget {
  final String userRole;
  const EnvironmentalDataCard({super.key, required this.userRole});

  @override
  State<EnvironmentalDataCard> createState() => _EnvironmentalDataCardState();
}

class _EnvironmentalDataCardState extends State<EnvironmentalDataCard> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inMinutes < 1) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(8), // Reduced from 12
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.08)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.primary,
          ), // Reduced from 18
          const SizedBox(height: 4), // Reduced from 6
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 13, // Reduced from 14
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 9, // Reduced from 10
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int totalPages, int currentPage, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: index == currentPage
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // NOTE: Replace these hardcoded values with data from your database!
    final riverLocations = [
      {
        'id': 'calapan_river',
        'river': 'Calapan River',
        'location': 'Calapan City Public Market area',
        'ph': 6.8,
        'trashCount': 127,
        'temperature': 29.5,
        'turbidity': 85.2,
        'lastUpdate': DateTime.now().subtract(const Duration(minutes: 5)),
        'color': Colors.red,
        'percentage': 35,
        'waterQuality': 'Poor',
      },
      {
        'id': 'bucayao_river',
        'river': 'Bucayao River',
        'location': 'Barangay Bucayao, Calapan City',
        'ph': 7.2,
        'trashCount': 43,
        'temperature': 28.1,
        'turbidity': 42.6,
        'lastUpdate': DateTime.now().subtract(const Duration(minutes: 8)),
        'color': Colors.orange,
        'percentage': 65,
        'waterQuality': 'Fair',
      },
      {
        'id': 'panggalaan_river',
        'river': 'Panggalaan River',
        'location': 'Barangay Panggalaan, Calapan City',
        'ph': 7.6,
        'trashCount': 18,
        'temperature': 27.8,
        'turbidity': 18.4,
        'lastUpdate': DateTime.now().subtract(const Duration(minutes: 3)),
        'color': Colors.green,
        'percentage': 85,
        'waterQuality': 'Good',
      },
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calapan City Rivers',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Real-time Water Quality & Trash Monitoring',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Live Data',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20), // Reduced from 24
          // Horizontal PageView for rivers
          SizedBox(
            height: 340, // Reduced from 360
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: riverLocations.length,
              itemBuilder: (context, index) {
                final river = riverLocations[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(14), // Reduced from 16
                  decoration: BoxDecoration(
                    color: theme.colorScheme.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // River header
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: river['color'] as Color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  river['river'] as String,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 15,
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  river['location'] as String,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: (river['color'] as Color).withOpacity(
                                0.12,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              river['waterQuality'] as String,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: river['color'] as Color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14), // Reduced from 16
                      // Main metrics in 2x2 grid
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricItem(
                              icon: Icons.water_drop_outlined,
                              label: 'pH Level',
                              value: '${river['ph']}',
                              theme: theme,
                            ),
                          ),
                          const SizedBox(width: 8), // Reduced from 10
                          Expanded(
                            child: _buildMetricItem(
                              icon: Icons.delete_outline,
                              label: 'Trash Items',
                              value: '${river['trashCount']}',
                              theme: theme,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6), // Reduced from 8
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricItem(
                              icon: Icons.thermostat_outlined,
                              label: 'Temperature',
                              value: '${river['temperature']}°C',
                              theme: theme,
                            ),
                          ),
                          const SizedBox(width: 8), // Reduced from 10
                          Expanded(
                            child: _buildMetricItem(
                              icon: Icons.opacity_rounded,
                              label: 'Turbidity',
                              value: '${river['turbidity']} NTU',
                              theme: theme,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12), // Reduced from 16
                      // Quality progress bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Water Quality Score',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${river['percentage']}%',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  color: river['color'] as Color,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4), // Reduced from 6
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.outline.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: (river['percentage'] as int) / 100,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: river['color'] as Color,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8), // Reduced from 10
                      // Last update timestamp
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Updated ${_getTimeAgo(river['lastUpdate'] as DateTime)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12), // Reduced from 16
          // Page indicator
          _buildPageIndicator(riverLocations.length, _currentPage, theme),
        ],
      ),
    );
  }
}
