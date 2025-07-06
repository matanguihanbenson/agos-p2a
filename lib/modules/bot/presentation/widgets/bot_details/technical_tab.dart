import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'modern_info_row.dart';

class TechnicalTab extends StatelessWidget {
  final Map<String, dynamic>? realtime;
  final Map<String, dynamic> data;

  const TechnicalTab({Key? key, this.realtime, required this.data})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final model = data['model']?.toString();
    final serial = data['serial_number']?.toString();
    final fw = data['firmware_version']?.toString();
    final hw = data['hardware_version']?.toString();
    final uptime =
        realtime?['uptime']?.toString() ?? data['uptime']?.toString();
    final created = data['created_at'] as Timestamp?;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (model != null) ...[
            ModernInfoRow(Icons.precision_manufacturing, 'Model', model, cs),
            const SizedBox(height: 8),
          ],
          if (serial != null) ...[
            ModernInfoRow(Icons.numbers, 'Serial Number', serial, cs),
            const SizedBox(height: 8),
          ],
          if (fw != null) ...[
            ModernInfoRow(Icons.memory, 'Firmware', 'v$fw', cs),
            const SizedBox(height: 8),
          ],
          if (hw != null) ...[
            ModernInfoRow(Icons.developer_board, 'Hardware', 'v$hw', cs),
            const SizedBox(height: 8),
          ],
          if (uptime != null) ...[
            ModernInfoRow(Icons.timer, 'Uptime', uptime, cs),
            const SizedBox(height: 8),
          ],
          if (created != null)
            ModernInfoRow(
              Icons.add_circle_outline,
              'Created',
              _fmt(created),
              cs,
            ),
        ],
      ),
    );
  }

  String _fmt(Timestamp t) {
    final dt = t.toDate();
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
