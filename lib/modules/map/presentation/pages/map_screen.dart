import 'package:flutter/material.dart';
import 'package:agos/modules/map/presentation/widgets/bot_tracking_map.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Bot Tracker')
      ),
      body: const BotTrackingMap(),
    );
  }
}
