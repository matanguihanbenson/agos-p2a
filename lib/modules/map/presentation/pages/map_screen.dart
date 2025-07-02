import 'package:flutter/material.dart';
import 'package:agos/modules/map/presentation/widgets/bot_tracking_map.dart';
import 'package:agos/modules/map/presentation/widgets/trash_detection_map.dart';
import 'package:agos/modules/map/presentation/widgets/trash_heatmap.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  int _selectedView = 0;

  final _views = const [BotTrackingMap(), TrashDetectionMap(), TrashHeatmap()];

  final _titles = ['Bot Tracker', 'Trash Filter View', 'Pollution Heatmap'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedView]),
        actions: [
          PopupMenuButton<int>(
            onSelected: (index) => setState(() => _selectedView = index),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 0, child: Text('Bot Tracker')),
              const PopupMenuItem(value: 1, child: Text('Trash Filter View')),
              const PopupMenuItem(value: 2, child: Text('Heatmap View')),
            ],
          ),
        ],
      ),
      body: _views[_selectedView],
    );
  }
}
