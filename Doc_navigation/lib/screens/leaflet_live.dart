import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;
import 'dart:async';

class LeafletLive extends StatefulWidget {
  const LeafletLive({Key? key}) : super(key: key);

  @override
  State<LeafletLive> createState() => _LeafletLiveState();
}

class _LeafletLiveState extends State<LeafletLive> {
  final MapController _mapController = MapController();

  LatLng _currentLocation = const LatLng(18.5204, 73.8567);
  double _currentZoom = 13.0;
  bool _isLoadingLocation = false;
  bool _isNavigating = false;

  final List<Marker> _markers = [];
  final List<Marker> _hospitalMarkers = [];
  List<LatLng> _routePoints = [];

  String? _routeDistance;
  String? _routeDuration;
  LatLng? _selectedHospital;

  final Map<String, Map<String, dynamic>> _hospitals = {
    'Ruby Hall Clinic': {
      'location': LatLng(18.5204, 73.8567),
      'type': 'Multi-specialty',
      'address': 'Grant Road, Pune'
    },
    'Sahyadri Hospital': {
      'location': LatLng(18.5314, 73.8446),
      'type': 'Super-specialty',
      'address': 'Deccan Gymkhana, Pune'
    },
    'Jahangir Hospital': {
      'location': LatLng(18.5444, 73.8222),
      'type': 'Multi-specialty',
      'address': 'Sassoon Road, Pune'
    },
    'Deenanath Mangeshkar Hospital': {
      'location': LatLng(18.5104, 73.8667),
      'type': 'Multi-specialty',
      'address': 'Erandwane, Pune'
    },
    'Bharti Hospital': {
      'location': LatLng(18.5594, 73.7781),
      'type': 'General Hospital',
      'address': 'Katraj, Pune'
    },
    'Noble Hospital': {
      'location': LatLng(18.5089, 73.9260),
      'type': 'Multi-specialty',
      'address': 'Hadapsar, Pune'
    },
    'Sassoon Hospital': {
      'location': LatLng(18.5304, 73.8567),
      'type': 'Government Hospital',
      'address': 'Near Railway Station, Pune'
    },
    'KEM Hospital': {
      'location': LatLng(18.5074, 73.8077),
      'type': 'Government Hospital',
      'address': 'Rasta Peth, Pune'
    },
  };

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadAllHospitals();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final position =
          await html.window.navigator.geolocation.getCurrentPosition();

      final lat = position.coords?.latitude;
      final lng = position.coords?.longitude;

      if (lat != null && lng != null) {
        setState(() {
          _currentLocation = LatLng(lat.toDouble(), lng.toDouble());
          _isLoadingLocation = false;
        });

        _mapController.move(_currentLocation, 15);
        _addCurrentLocationMarker();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Live location detected!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Location access denied. Using Pune as default.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );

      _addCurrentLocationMarker();
    }
  }

  void _addCurrentLocationMarker() {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          point: _currentLocation,
          width: 80,
          height: 80,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child:
                    const Icon(Icons.navigation, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'You',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _loadAllHospitals() {
    setState(() {
      _hospitalMarkers.clear();

      _hospitals.forEach((name, data) {
        _hospitalMarkers.add(
          Marker(
            point: data['location'],
            width: 80,
            height: 80,
            child: GestureDetector(
              onTap: () => _showHospitalOptions(name, data),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.local_hospital,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red, width: 1),
                    ),
                    child: Text(
                      name.split(' ').first,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      });
    });
  }

  // 🚗 GET ROUTE USING OSRM (FREE - FOLLOWS ROADS!)
  Future<void> _getRoute(LatLng destination) async {
    setState(() {
      _isNavigating = true;
      _routePoints.clear();
    });

    try {
      // OSRM API - FREE and follows actual roads!
      final url = Uri.parse('https://router.project-osrm.org/route/v1/driving/'
          '${_currentLocation.longitude},${_currentLocation.latitude};'
          '${destination.longitude},${destination.latitude}'
          '?overview=full&geometries=geojson');

      print('🔍 Requesting route: $url');

      final response = await http.get(url);

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print('✅ Route data received');

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry']['coordinates'] as List;

          setState(() {
            // Convert coordinates to LatLng (OSRM returns [lng, lat])
            _routePoints = geometry
                .map<LatLng>(
                    (coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
                .toList();

            // Get distance and duration
            final distanceMeters = route['distance'];
            final durationSeconds = route['duration'];

            _routeDistance = '${(distanceMeters / 1000).toStringAsFixed(2)} km';
            _routeDuration = _formatDuration(durationSeconds.toInt());
            _isNavigating = false;
          });

          print('🗺️ Route points: ${_routePoints.length}');

          _fitRouteBounds();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('🗺️ Route found: $_routeDistance in $_routeDuration'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          throw Exception('No routes found');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Route error: $e');

      setState(() {
        _routePoints = [_currentLocation, destination];
        _isNavigating = false;

        const distance = Distance();
        final km =
            distance.as(LengthUnit.Kilometer, _currentLocation, destination);
        _routeDistance = '${km.toStringAsFixed(2)} km';
        _routeDuration = _estimateDuration(km);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Routing failed: $e\nShowing straight line'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) {
      return '$minutes mins';
    } else {
      final hours = (minutes / 60).floor();
      final remainingMins = minutes % 60;
      return '$hours hr ${remainingMins > 0 ? '$remainingMins mins' : ''}';
    }
  }

  String _estimateDuration(double km) {
    final minutes = (km / 30 * 60).round();
    return _formatDuration(minutes * 60);
  }

  void _fitRouteBounds() {
    if (_routePoints.isEmpty) return;

    double minLat = _routePoints.first.latitude;
    double maxLat = _routePoints.first.latitude;
    double minLng = _routePoints.first.longitude;
    double maxLng = _routePoints.first.longitude;

    for (var point in _routePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  void _showHospitalOptions(String name, Map<String, dynamic> data) {
    final location = data['location'] as LatLng;

    const distance = Distance();
    final km = distance.as(LengthUnit.Kilometer, _currentLocation, location);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.local_hospital, color: Colors.red, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Text(name, style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(Icons.category, 'Type', data['type']),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on, 'Address', data['address']),
            const SizedBox(height: 8),
            _buildInfoRow(
                Icons.straighten, 'Distance', '${km.toStringAsFixed(2)} km'),
            const SizedBox(height: 8),
            _buildInfoRow(
                Icons.access_time, 'Est. Time', _estimateDuration(km)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _startNavigation(name, location);
            },
            icon: const Icon(Icons.navigation),
            label: const Text('Navigate'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.blue),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  Future<void> _startNavigation(String hospitalName, LatLng destination) async {
    setState(() {
      _selectedHospital = destination;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🧭 Calculating road route to $hospitalName...'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );

    await _getRoute(destination);
  }

  void _clearRoute() {
    setState(() {
      _routePoints.clear();
      _selectedHospital = null;
      _routeDistance = null;
      _routeDuration = null;
    });

    _mapController.move(_currentLocation, 13);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DRDS Live Navigation'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (_routePoints.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Clear route',
              onPressed: _clearRoute,
            ),
          IconButton(
            icon: _isLoadingLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.my_location),
            tooltip: 'Update location',
            onPressed: _isLoadingLocation ? null : _getCurrentLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 13,
              onPositionChanged: (position, hasGesture) {
                setState(() {
                  _currentZoom = position.zoom ?? _currentZoom;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.drds.navigation',
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 6.0,
                      color: Colors.blue,
                      borderStrokeWidth: 3.0,
                      borderColor: Colors.white,
                    ),
                  ],
                ),
              MarkerLayer(markers: [..._markers, ..._hospitalMarkers]),
            ],
          ),
          if (_routePoints.isNotEmpty && _routeDistance != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.route,
                                color: Colors.blue, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              _routeDistance!,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                color: Colors.green, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              _routeDuration!,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '🚴 Follow the blue route on roads',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1,
                    );
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    );
                  },
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
          if (_isNavigating)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Calculating road route...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _routePoints.isEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showHospitalList(),
              icon: const Icon(Icons.local_hospital),
              label: const Text('Hospitals'),
              backgroundColor: Colors.red,
            )
          : null,
    );
  }

  void _showHospitalList() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Nearby Hospitals',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _hospitals.length,
                itemBuilder: (context, index) {
                  final name = _hospitals.keys.elementAt(index);
                  final data = _hospitals[name]!;
                  final location = data['location'] as LatLng;

                  const distance = Distance();
                  final km = distance.as(
                      LengthUnit.Kilometer, _currentLocation, location);

                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.red,
                        child: Icon(Icons.local_hospital, color: Colors.white),
                      ),
                      title: Text(name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle:
                          Text('${data['type']} • ${km.toStringAsFixed(2)} km'),
                      trailing:
                          const Icon(Icons.navigation, color: Colors.blue),
                      onTap: () {
                        Navigator.pop(context);
                        _showHospitalOptions(name, data);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
