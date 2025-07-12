import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/geocoding_service.dart';

class LocationDisplayWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final int? radius;
  final String title;
  final IconData icon;
  final VoidCallback? onEdit;
  final bool showRadius;

  const LocationDisplayWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    this.radius,
    required this.title,
    required this.icon,
    this.onEdit,
    this.showRadius = false,
  });

  @override
  State<LocationDisplayWidget> createState() => _LocationDisplayWidgetState();
}

class _LocationDisplayWidgetState extends State<LocationDisplayWidget> {
  String? _address;
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  @override
  void didUpdateWidget(LocationDisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      _loadAddress();
    }
  }

  Future<void> _loadAddress() async {
    setState(() {
      _isLoadingAddress = true;
      _address = null;
    });

    try {
      final address = await GeocodingService.reverseGeocode(
        widget.latitude,
        widget.longitude,
      );

      if (mounted) {
        setState(() {
          _address = address != null
              ? GeocodingService.formatAddress(address)
              : null;
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAddress = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(widget.icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (widget.onEdit != null)
                IconButton(
                  onPressed: widget.onEdit,
                  icon: const Icon(Icons.edit, size: 18),
                  tooltip: 'Edit location',
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Coordinates
          Row(
            children: [
              Expanded(
                child: _buildInfoRow(
                  'Lat',
                  widget.latitude.toStringAsFixed(6),
                  theme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoRow(
                  'Lng',
                  widget.longitude.toStringAsFixed(6),
                  theme,
                ),
              ),
            ],
          ),

          if (widget.showRadius && widget.radius != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              'Radius',
              '${widget.radius}m',
              theme,
              icon: Icons.radio_button_unchecked,
            ),
          ],

          const SizedBox(height: 12),

          // Address
          if (_isLoadingAddress)
            Row(
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Loading address...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            )
          else if (_address != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.place, size: 16, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _address!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _address!));
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Address copied to clipboard'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy, size: 14),
                            label: const Text('Copy'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              minimumSize: const Size(0, 32),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _loadAddress,
                            icon: const Icon(Icons.refresh, size: 14),
                            label: const Text('Refresh'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              minimumSize: const Size(0, 32),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Icon(
                  Icons.place_outlined,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  'Address not available',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                TextButton.icon(
                  onPressed: _loadAddress,
                  icon: const Icon(Icons.refresh, size: 14),
                  label: const Text('Retry'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    ThemeData theme, {
    IconData? icon,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: theme.colorScheme.outline),
          const SizedBox(width: 4),
        ],
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
