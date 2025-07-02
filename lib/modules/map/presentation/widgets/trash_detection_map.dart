import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class TrashDetectionMap extends StatefulWidget {
  const TrashDetectionMap({super.key});

  @override
  State<TrashDetectionMap> createState() => _TrashDetectionMapState();
}

class _TrashDetectionMapState extends State<TrashDetectionMap> {
  final MapController _mapController = MapController();
  List<Marker> _trashMarkers = [];
  Map<String, int> _trashTypeCounts = {};

  String? _selectedCountry;
  String? _selectedRegion;
  String? _selectedProvince;
  String? _selectedCity;
  String? _selectedBarangay;

  List<String> _countries = [];
  List<String> _regions = [];
  List<String> _provinces = [];
  List<String> _cities = [];
  List<String> _barangays = [];

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  void _loadCountries() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('detections')
        .get();
    final allData = snapshot.docs.map((e) => e.data()).toList();
    final countrySet = <String>{};

    for (var doc in allData) {
      if (doc.containsKey('country')) countrySet.add(doc['country']);
    }

    setState(() => _countries = countrySet.toList()..sort());
  }

  void _onFilterChange() async {
    await _loadNextFilterOptions();

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
      'detections',
    );

    if (_selectedCountry != null) {
      query = query.where('country', isEqualTo: _selectedCountry);
    }
    if (_selectedRegion != null) {
      query = query.where('region', isEqualTo: _selectedRegion);
    }
    if (_selectedProvince != null) {
      query = query.where('province', isEqualTo: _selectedProvince);
    }
    if (_selectedCity != null) {
      query = query.where('city', isEqualTo: _selectedCity);
    }
    if (_selectedBarangay != null) {
      query = query.where('barangay', isEqualTo: _selectedBarangay);
    }

    final results = await query.get();

    final markers = <Marker>[];
    final typeCounts = <String, int>{};

    for (var doc in results.docs) {
      final data = doc.data();
      final type = data['trashType'] ?? 'unknown';
      final lat = data['location']['lat'];
      final lng = data['location']['lng'];

      typeCounts[type] = (typeCounts[type] ?? 0) + 1;

      if (_selectedCity != null || _selectedBarangay != null) {
        markers.add(
          Marker(
            point: LatLng(lat.toDouble(), lng.toDouble()),
            width: 40,
            height: 40,
            child: Tooltip(
              message: type,
              child: const Icon(Icons.delete, size: 30, color: Colors.red),
            ),
          ),
        );
      }
    }

    if (markers.isNotEmpty) {
      _mapController.move(markers.first.point, 15);
    }

    setState(() {
      _trashMarkers = markers;
      _trashTypeCounts = typeCounts;
    });
  }

  Future<void> _loadNextFilterOptions() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('detections')
        .get();
    final allData = snapshot.docs.map((e) => e.data()).toList();

    final regionSet = <String>{};
    final provinceSet = <String>{};
    final citySet = <String>{};
    final barangaySet = <String>{};

    for (var doc in allData) {
      if (_selectedCountry != null && doc['country'] != _selectedCountry)
        continue;
      if (_selectedRegion != null && doc['region'] != _selectedRegion) continue;
      if (_selectedProvince != null && doc['province'] != _selectedProvince)
        continue;
      if (_selectedCity != null && doc['city'] != _selectedCity) continue;

      if (doc.containsKey('region')) regionSet.add(doc['region']);
      if (doc.containsKey('province')) provinceSet.add(doc['province']);
      if (doc.containsKey('city')) citySet.add(doc['city']);
      if (doc.containsKey('barangay')) barangaySet.add(doc['barangay']);
    }

    setState(() {
      _regions = regionSet.toList()..sort();
      _provinces = provinceSet.toList()..sort();
      _cities = citySet.toList()..sort();
      _barangays = barangaySet.toList()..sort();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            spacing: 8,
            children: [
              DropdownButton<String>(
                hint: const Text('Country'),
                value: _selectedCountry,
                items: _countries
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCountry = value;
                    _selectedRegion = null;
                    _selectedProvince = null;
                    _selectedCity = null;
                    _selectedBarangay = null;
                  });
                  _onFilterChange();
                },
              ),
              if (_regions.isNotEmpty)
                DropdownButton<String>(
                  hint: const Text('Region'),
                  value: _selectedRegion,
                  items: _regions
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRegion = value;
                      _selectedProvince = null;
                      _selectedCity = null;
                      _selectedBarangay = null;
                    });
                    _onFilterChange();
                  },
                ),
              if (_provinces.isNotEmpty)
                DropdownButton<String>(
                  hint: const Text('Province'),
                  value: _selectedProvince,
                  items: _provinces
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProvince = value;
                      _selectedCity = null;
                      _selectedBarangay = null;
                    });
                    _onFilterChange();
                  },
                ),
              if (_cities.isNotEmpty)
                DropdownButton<String>(
                  hint: const Text('City'),
                  value: _selectedCity,
                  items: _cities
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCity = value;
                      _selectedBarangay = null;
                    });
                    _onFilterChange();
                  },
                ),
              if (_barangays.isNotEmpty)
                DropdownButton<String>(
                  hint: const Text('Barangay'),
                  value: _selectedBarangay,
                  items: _barangays
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedBarangay = value);
                    _onFilterChange();
                  },
                ),
            ],
          ),
        ),
        if (_trashTypeCounts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'No trash data available for this area.',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: _trashTypeCounts.entries
                  .map(
                    (e) => Text(
                      '${e.key}: ${e.value}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  )
                  .toList(),
            ),
          ),
        Expanded(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(13.413, 121.180),
              initialZoom: 11,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: ['a', 'b', 'c'],
              ),
              MarkerLayer(markers: _trashMarkers),
            ],
          ),
        ),
      ],
    );
  }
}
