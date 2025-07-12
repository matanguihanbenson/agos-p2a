import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

import '../../../../core/services/location_service.dart';
import '../../../../core/services/geocoding_service.dart';
import 'map_location_picker.dart';

class EditScheduleScreen extends StatefulWidget {
  final Map<String, dynamic> schedule;

  const EditScheduleScreen({super.key, required this.schedule});

  @override
  State<EditScheduleScreen> createState() => _EditScheduleScreenState();
}

class _EditScheduleScreenState extends State<EditScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _radiusController = TextEditingController();

  late String _botId;
  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;
  late double _latitude;
  late double _longitude;
  late double _dockingLatitude;
  late double _dockingLongitude;

  bool _isLoading = false;
  bool _isGettingLocation = false;
  String? _operationAreaAddress;
  String? _dockingPointAddress;
  bool _isGeocodingOperationArea = false;
  bool _isGeocodingDockingPoint = false;

  Timer? _operationAreaDebounceTimer;
  Timer? _dockingPointDebounceTimer;

  @override
  void initState() {
    super.initState();
    _initializeFields();
    // Load initial addresses
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateOperationAreaAddress();
      _updateDockingPointAddress();
    });
  }

  void _initializeFields() {
    final schedule = widget.schedule;
    _botId = schedule['bot_id'];

    final startDateTime = schedule['deployment_start'] as DateTime;
    _startDate = DateTime(
      startDateTime.year,
      startDateTime.month,
      startDateTime.day,
    );
    _startTime = TimeOfDay.fromDateTime(startDateTime);

    final endDateTime = schedule['deployment_end'] as DateTime;
    _endDate = DateTime(endDateTime.year, endDateTime.month, endDateTime.day);
    _endTime = TimeOfDay.fromDateTime(endDateTime);

    _latitude = schedule['area_center']['latitude'];
    _longitude = schedule['area_center']['longitude'];

    // Initialize docking point (fallback to area center if not exists)
    final dockingPoint = schedule['docking_point'];
    if (dockingPoint != null) {
      _dockingLatitude = dockingPoint['latitude'];
      _dockingLongitude = dockingPoint['longitude'];
    } else {
      _dockingLatitude = _latitude;
      _dockingLongitude = _longitude;
    }

    _notesController.text = schedule['notes'] ?? '';
    _radiusController.text = schedule['area_radius_m'].toString();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _radiusController.dispose();
    _operationAreaDebounceTimer?.cancel();
    _dockingPointDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Edit Schedule'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveSchedule,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBotInfo(theme),
              const SizedBox(height: 32),
              _buildDateTimeSection(theme),
              const SizedBox(height: 32),
              _buildLocationSection(theme),
              const SizedBox(height: 32),
              _buildDockingPointSection(theme),
              const SizedBox(height: 32),
              _buildNotesSection(theme),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBotInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.directions_boat,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            'Editing schedule for $_botId',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deployment Schedule',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                'Start Date',
                _startDate,
                (date) => setState(() => _startDate = date),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTimeField(
                'Start Time',
                _startTime,
                (time) => setState(() => _startTime = time),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                'End Date',
                _endDate,
                (date) => setState(() => _endDate = date),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTimeField(
                'End Time',
                _endTime,
                (time) => setState(() => _endTime = time),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Duration: ${_calculateDuration()}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Operation Area',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _selectOperationAreaOnMap,
              icon: const Icon(Icons.map, size: 16),
              label: const Text('Select on Map'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: ValueKey(_latitude),
                initialValue: _latitude.toStringAsFixed(6),
                decoration: InputDecoration(
                  labelText: 'Latitude',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (value) {
                  final lat = double.tryParse(value);
                  if (lat != null) {
                    _latitude = lat;
                    setState(() {
                      _operationAreaAddress = null;
                    });
                    _debouncedUpdateOperationAreaAddress();
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final lat = double.tryParse(value);
                  if (lat == null || lat < -90 || lat > 90) {
                    return 'Invalid';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                key: ValueKey(_longitude),
                initialValue: _longitude.toStringAsFixed(6),
                decoration: InputDecoration(
                  labelText: 'Longitude',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (value) {
                  final lng = double.tryParse(value);
                  if (lng != null) {
                    _longitude = lng;
                    setState(() {
                      _operationAreaAddress = null;
                    });
                    _debouncedUpdateOperationAreaAddress();
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final lng = double.tryParse(value);
                  if (lng == null || lng < -180 || lng > 180) {
                    return 'Invalid';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildAddressDisplay(
          _operationAreaAddress,
          _isGeocodingOperationArea,
          _updateOperationAreaAddress,
          theme,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _radiusController,
          decoration: InputDecoration(
            labelText: 'Coverage Radius (meters)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            suffixText: 'm',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter coverage radius';
            }
            final radius = int.tryParse(value);
            if (radius == null || radius <= 0) {
              return 'Please enter a valid radius';
            }
            if (radius > 1000) {
              return 'Maximum radius is 1000m';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDockingPointSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Docking Point',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _selectDockingPointOnMap,
              icon: const Icon(Icons.map, size: 16),
              label: const Text('Select on Map'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Location where the bot will return after completing the schedule',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: ValueKey(_dockingLatitude),
                initialValue: _dockingLatitude.toStringAsFixed(6),
                decoration: InputDecoration(
                  labelText: 'Docking Latitude',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (value) {
                  final lat = double.tryParse(value);
                  if (lat != null) {
                    _dockingLatitude = lat;
                    setState(() {
                      _dockingPointAddress = null;
                    });
                    _debouncedUpdateDockingPointAddress();
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final lat = double.tryParse(value);
                  if (lat == null || lat < -90 || lat > 90) {
                    return 'Invalid';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                key: ValueKey(_dockingLongitude),
                initialValue: _dockingLongitude.toStringAsFixed(6),
                decoration: InputDecoration(
                  labelText: 'Docking Longitude',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (value) {
                  final lng = double.tryParse(value);
                  if (lng != null) {
                    _dockingLongitude = lng;
                    setState(() {
                      _dockingPointAddress = null;
                    });
                    _debouncedUpdateDockingPointAddress();
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final lng = double.tryParse(value);
                  if (lng == null || lng < -180 || lng > 180) {
                    return 'Invalid';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildAddressDisplay(
          _dockingPointAddress,
          _isGeocodingDockingPoint,
          _updateDockingPointAddress,
          theme,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isGettingLocation
                ? null
                : _useCurrentLocationForDocking,
            icon: _isGettingLocation
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location, size: 18),
            label: Text(
              _isGettingLocation
                  ? 'Getting Location...'
                  : 'Use Current Location',
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Notes',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _notesController,
          decoration: InputDecoration(
            labelText: 'Notes (optional)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            hintText: 'Add any special instructions...',
          ),
          maxLines: 3,
          maxLength: 500,
        ),
      ],
    );
  }

  Widget _buildAddressDisplay(
    String? address,
    bool isLoading,
    VoidCallback onRefresh,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          if (isLoading)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            )
          else
            Icon(
              address != null ? Icons.place : Icons.place_outlined,
              size: 16,
              color: address != null
                  ? theme.colorScheme.primary
                  : Colors.grey.shade600,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isLoading
                  ? 'Loading address...'
                  : address ?? 'Address not available',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isLoading
                    ? theme.colorScheme.primary
                    : address != null
                    ? theme.colorScheme.onSurfaceVariant
                    : Colors.grey.shade600,
                fontStyle: address == null && !isLoading
                    ? FontStyle.italic
                    : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!isLoading) ...[
            const SizedBox(width: 8),
            if (address != null)
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: address));
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Address copied to clipboard'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                tooltip: 'Copy address',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            IconButton(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, size: 16),
              tooltip: 'Refresh address',
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateField(
    String label,
    DateTime date,
    Function(DateTime) onChanged,
  ) {
    return InkWell(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (selectedDate != null) {
          onChanged(selectedDate);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        child: Text(
          '${date.day}/${date.month}/${date.year}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  Widget _buildTimeField(
    String label,
    TimeOfDay time,
    Function(TimeOfDay) onChanged,
  ) {
    return InkWell(
      onTap: () async {
        final selectedTime = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (selectedTime != null) {
          onChanged(selectedTime);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        child: Text(
          time.format(context),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  String _calculateDuration() {
    final startDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endDateTime = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (endDateTime.isBefore(startDateTime)) {
      return 'Invalid time range';
    }

    final duration = endDateTime.difference(startDateTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  void _debouncedUpdateOperationAreaAddress() {
    _operationAreaDebounceTimer?.cancel();
    _operationAreaDebounceTimer = Timer(const Duration(milliseconds: 800), () {
      _updateOperationAreaAddress();
    });
  }

  void _debouncedUpdateDockingPointAddress() {
    _dockingPointDebounceTimer?.cancel();
    _dockingPointDebounceTimer = Timer(const Duration(milliseconds: 800), () {
      _updateDockingPointAddress();
    });
  }

  Future<void> _updateOperationAreaAddress() async {
    if (!mounted) return;

    setState(() {
      _isGeocodingOperationArea = true;
    });

    try {
      final address = await GeocodingService.reverseGeocode(
        _latitude,
        _longitude,
      );
      if (mounted) {
        setState(() {
          _operationAreaAddress = address != null
              ? GeocodingService.formatAddress(address)
              : null;
          _isGeocodingOperationArea = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get operation area address: $e');
      }
      if (mounted) {
        setState(() {
          _operationAreaAddress = null;
          _isGeocodingOperationArea = false;
        });
      }
    }
  }

  Future<void> _updateDockingPointAddress() async {
    if (!mounted) return;

    setState(() {
      _isGeocodingDockingPoint = true;
    });

    try {
      final address = await GeocodingService.reverseGeocode(
        _dockingLatitude,
        _dockingLongitude,
      );
      if (mounted) {
        setState(() {
          _dockingPointAddress = address != null
              ? GeocodingService.formatAddress(address)
              : null;
          _isGeocodingDockingPoint = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get docking point address: $e');
      }
      if (mounted) {
        setState(() {
          _dockingPointAddress = null;
          _isGeocodingDockingPoint = false;
        });
      }
    }
  }

  Future<void> _selectOperationAreaOnMap() async {
    final radius = int.tryParse(_radiusController.text) ?? 100;

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationPicker(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
          coverageRadius: radius,
          title: 'Select Operation Area',
          showCoverageCircle: true,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _latitude = result['latitude']!;
        _longitude = result['longitude']!;
        _operationAreaAddress = result['address'];
        if (result['radius'] != null) {
          _radiusController.text = result['radius'].toString();
        }
      });

      // Update address if not provided by map picker
      if (_operationAreaAddress == null) {
        _updateOperationAreaAddress();
      }
    }
  }

  Future<void> _selectDockingPointOnMap() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationPicker(
          initialLatitude: _dockingLatitude,
          initialLongitude: _dockingLongitude,
          coverageRadius: 0,
          title: 'Select Docking Point',
          showCoverageCircle: false,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _dockingLatitude = result['latitude']!;
        _dockingLongitude = result['longitude']!;
        _dockingPointAddress = result['address'];
      });

      // Update address if not provided by map picker
      if (_dockingPointAddress == null) {
        _updateDockingPointAddress();
      }
    }
  }

  Future<void> _useCurrentLocationForDocking() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      final position = await LocationService.instance.getCurrentLocation(
        forceRefresh: true,
      );

      if (position != null) {
        setState(() {
          _dockingLatitude = position.latitude;
          _dockingLongitude = position.longitude;
          _dockingPointAddress = null;
        });

        // Update address for new location
        _updateDockingPointAddress();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Current location set as docking point with ${position.accuracy.toStringAsFixed(0)}m accuracy',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to get location';

        if (e.toString().contains('permissions')) {
          errorMessage =
              'Location permission required. Please grant location access.';
        } else if (e.toString().contains('disabled')) {
          errorMessage =
              'Location services disabled. Please enable in device settings.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () {
                if (e.toString().contains('permissions')) {
                  LocationService.instance.openAppSettings();
                } else {
                  LocationService.instance.openLocationSettings();
                }
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final startDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endDateTime = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement save functionality
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update schedule: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
