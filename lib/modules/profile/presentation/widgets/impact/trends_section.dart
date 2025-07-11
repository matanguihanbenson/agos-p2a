import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class TrendsSection extends StatefulWidget {
  @override
  State<TrendsSection> createState() => _TrendsSectionState();
}

class _TrendsSectionState extends State<TrendsSection> {
  String selectedPeriod = 'Week';
  final List<String> periods = ['Week', 'Month', 'Year'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trends Over Time',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Performance Analytics',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedPeriod,
                  icon: Icon(Icons.keyboard_arrow_down, size: 16),
                  style: theme.textTheme.bodySmall,
                  items: periods.map((period) {
                    return DropdownMenuItem(value: period, child: Text(period));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedPeriod = value!);
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Water Quality Chart
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.water_drop,
                            color: Colors.blue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Water Quality Index (0-10)',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'pH, Turbidity',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: LineChart(_buildWaterQualityChart()),
                ),
                const SizedBox(height: 12),
                Text(
                  _getWaterQualityInsight(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Trash Collection Chart
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.delete_sweep,
                            color: Colors.green,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Trash Removed (kg)',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Cleanup Progress',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: LineChart(_buildTrashCollectionChart()),
                ),
                const SizedBox(height: 12),
                Text(
                  _getTrashCollectionInsight(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  LineChartData _buildWaterQualityChart() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1);
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              return Text(
                _getBottomTitle(value.toInt()),
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              );
            },
            reservedSize: 32,
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: _getMaxX().toDouble(),
      minY: 0,
      maxY: 10,
      lineBarsData: [
        LineChartBarData(
          spots: _getWaterQualitySpots(),
          isCurved: true,
          gradient: LinearGradient(
            colors: [Colors.blue.withOpacity(0.8), Colors.blue],
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.blue,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue.withOpacity(0.2),
                Colors.blue.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  LineChartData _buildTrashCollectionChart() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: _getTrashInterval(),
        getDrawingHorizontalLine: (value) {
          return FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1);
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              return Text(
                _getBottomTitle(value.toInt()),
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: _getTrashInterval(),
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}kg',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              );
            },
            reservedSize: 50,
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: _getMaxX().toDouble(),
      minY: 0,
      maxY: _getTrashMaxY(),
      lineBarsData: [
        LineChartBarData(
          spots: _getTrashCollectionSpots(),
          isCurved: true,
          gradient: LinearGradient(
            colors: [Colors.green.withOpacity(0.8), Colors.green],
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.green,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.green.withOpacity(0.2),
                Colors.green.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<FlSpot> _getWaterQualitySpots() {
    switch (selectedPeriod) {
      case 'Week':
        return [
          FlSpot(0, 7.2),
          FlSpot(1, 7.5),
          FlSpot(2, 7.8),
          FlSpot(3, 7.6),
          FlSpot(4, 8.1),
          FlSpot(5, 8.3),
          FlSpot(6, 8.0),
        ];
      case 'Month':
        return [FlSpot(0, 7.0), FlSpot(1, 7.3), FlSpot(2, 7.8), FlSpot(3, 8.0)];
      case 'Year':
        return [
          FlSpot(0, 6.8),
          FlSpot(1, 7.2),
          FlSpot(2, 7.8),
          FlSpot(3, 8.1),
          FlSpot(4, 8.3),
          FlSpot(5, 8.5),
          FlSpot(6, 8.2),
          FlSpot(7, 8.4),
          FlSpot(8, 8.6),
          FlSpot(9, 8.3),
          FlSpot(10, 8.1),
          FlSpot(11, 8.0),
        ];
      default:
        return [];
    }
  }

  List<FlSpot> _getTrashCollectionSpots() {
    switch (selectedPeriod) {
      case 'Week':
        return [
          FlSpot(0, 45),
          FlSpot(1, 52),
          FlSpot(2, 48),
          FlSpot(3, 61),
          FlSpot(4, 58),
          FlSpot(5, 67),
          FlSpot(6, 72),
        ];
      case 'Month':
        return [FlSpot(0, 180), FlSpot(1, 220), FlSpot(2, 280), FlSpot(3, 320)];
      case 'Year':
        return [
          FlSpot(0, 720),
          FlSpot(1, 850),
          FlSpot(2, 920),
          FlSpot(3, 1050),
          FlSpot(4, 1180),
          FlSpot(5, 1320),
          FlSpot(6, 1250),
          FlSpot(7, 1400),
          FlSpot(8, 1380),
          FlSpot(9, 1450),
          FlSpot(10, 1520),
          FlSpot(11, 1600),
        ];
      default:
        return [];
    }
  }

  String _getBottomTitle(int value) {
    switch (selectedPeriod) {
      case 'Week':
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return value < days.length ? days[value] : '';
      case 'Month':
        const weeks = ['W1', 'W2', 'W3', 'W4'];
        return value < weeks.length ? weeks[value] : '';
      case 'Year':
        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        return value < months.length ? months[value] : '';
      default:
        return '';
    }
  }

  int _getMaxX() {
    switch (selectedPeriod) {
      case 'Week':
        return 6;
      case 'Month':
        return 3;
      case 'Year':
        return 11;
      default:
        return 6;
    }
  }

  String _getWaterQualityInsight() {
    switch (selectedPeriod) {
      case 'Week':
        return 'Water quality improved by 11% across monitored rivers this week. Average pH levels stabilizing.';
      case 'Month':
        return 'Monthly average shows 14% improvement across all deployment sites. Best results in River Delta zones.';
      case 'Year':
        return 'Annual data shows 18% improvement across 12 monitored rivers. Turbidity reduced significantly.';
      default:
        return '';
    }
  }

  String _getTrashCollectionInsight() {
    switch (selectedPeriod) {
      case 'Week':
        return '25% increase in trash removal efficiency across all active deployment sites.';
      case 'Month':
        return 'Monthly removal target exceeded by 78%. Successfully collected 320kg from inland waterways.';
      case 'Year':
        return 'Annual collection shows 122% improvement. Total waste removed: 15.2 tons from river systems.';
      default:
        return '';
    }
  }

  double _getTrashMaxY() {
    switch (selectedPeriod) {
      case 'Week':
        return 100;
      case 'Month':
        return 400;
      case 'Year':
        return 2000;
      default:
        return 100;
    }
  }

  double _getTrashInterval() {
    switch (selectedPeriod) {
      case 'Week':
        return 20;
      case 'Month':
        return 100;
      case 'Year':
        return 400;
      default:
        return 20;
    }
  }
}
