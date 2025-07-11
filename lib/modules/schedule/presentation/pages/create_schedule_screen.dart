import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import 'map_location_picker.dart';

class CreateScheduleScreen extends StatefulWidget {
  const CreateScheduleScreen({super.key});

  @override
  State<CreateScheduleScreen> createState() => _CreateScheduleScreenState();
}

class _CreateScheduleScreenState extends State<CreateScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _radiusController = TextEditingController(text: '100');

  String? _selectedBotId;
  DateTime _startDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _endTime = TimeOfDay.now();
  double _latitude = 14.5995;
  double _longitude = 120.9842;
  double _dockingLatitude = 14.5995;
  double _dockingLongitude = 120.9842;

  bool _isLoading = false;
  bool _isGettingLocation = false;

  // Mock available bots - replace with actual data
  final List<String> _availableBots = [
    'BOT-001',
    'BOT-002',
    'BOT-003',
    'BOT-004',
    'BOT-005',
  ];

  @override
  void initState() {
    super.initState();
    _initializeDefaultTimes();
  }

  void _initializeDefaultTimes() {
    final now = DateTime.now();
    final startDateTime = now.add(const Duration(hours: 1));
    final endDateTime = startDateTime.add(const Duration(hours: 2));

    _startDate = DateTime(
      startDateTime.year,
      startDateTime.month,
      startDateTime.day,
    );
    _startTime = TimeOfDay.fromDateTime(startDateTime);
    _endDate = DateTime(endDateTime.year, endDateTime.month, endDateTime.day);
    _endTime = TimeOfDay.fromDateTime(endDateTime);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Create Schedule'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createSchedule,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create'),
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
              _buildBotSelectionSection(theme),
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

  Widget _buildBotSelectionSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bot Selection',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedBotId,
          decoration: InputDecoration(
            labelText: 'Select Bot',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            prefixIcon: const Icon(Icons.directions_boat),
          ),
          items: _availableBots.map((botId) {
            return DropdownMenuItem(value: botId, child: Text(botId));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedBotId = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a bot';
            }
            return null;
          },
        ),
        if (_selectedBotId != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Bot $_selectedBotId is available for deployment',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
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
                  if (lat != null) _latitude = lat;
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
                  if (lng != null) _longitude = lng;
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
            helperText: 'Recommended: 50-200m for optimal coverage',
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
                  if (lat != null) _dockingLatitude = lat;
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
                  if (lng != null) _dockingLongitude = lng;
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
            hintText: 'Add any special instructions or deployment details...',
          ),
          maxLines: 3,
          maxLength: 500,
        ),
      ],
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
        if (result['radius'] != null) {
          _radiusController.text = result['radius'].toString();
        }
      });
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
      });
    }
  }

  Future<void> _useCurrentLocationForDocking() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied';
      }

      Position position = await Geolocator.getCurrentPosition();

      setState(() {
        _dockingLatitude = position.latitude;
        _dockingLongitude = position.longitude;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Current location set as docking point'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  Future<void> _createSchedule() async {
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

    if (startDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start time must be in the future')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement create functionality
      final scheduleData = {
        'bot_id': _selectedBotId,
        'deployment_start': startDateTime,
        'deployment_end': endDateTime,
        'area_center': {'latitude': _latitude, 'longitude': _longitude},
        'area_radius_m': int.parse(_radiusController.text),
        'docking_point': {
          'latitude': _dockingLatitude,
          'longitude': _dockingLongitude,
        },
        'notes': _notesController.text.trim(),
        'status': 'scheduled',
        'created_at': DateTime.now(),
      };

      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create schedule: $e')),
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
