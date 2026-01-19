import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const MyApp());
}

// =======================
// MOCK HOSPITAL SERVICES DB
// =======================
final Map<String, Map<String, dynamic>> hospitalServiceDB = {
  "Bharti Hospital": {
    "services": [
      "General OPD",
      "Emergency",
      "Blood Test",
      "General Test",
      "ICU",
    ],
    "timings": "OPD: 9 AM – 6 PM | Emergency: 24x7",
  },
  "Noble Hospital": {
    "services": [
      "General OPD",
      "Emergency",
      "Blood Test",
      "General Test",
      "MRI",
    ],
    "timings": "OPD: 9 AM – 10 PM | Emergency: 24x7",
  },
  "Ruby Hall Clinic": {
    "services": ["General OPD", "Emergency", "Blood Test", "General Test"],
    "timings": "24x7",
  },
};

// =======================
// APP ROOT
// =======================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PatientHomePage(),
    );
  }
}

// =======================
// MODEL
// =======================
class Clinic {
  final String name;
  final LatLng location;
  final List<String> services;
  final String timings;

  Clinic({
    required this.name,
    required this.location,
    required this.services,
    required this.timings,
  });
}

// =======================
// MAIN PAGE
// =======================
class PatientHomePage extends StatefulWidget {
  const PatientHomePage({super.key});

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  final MapController mapController = MapController();
  final TextEditingController searchController = TextEditingController();

  LatLng patientLocation = LatLng(18.5204, 73.8567); // Pune
  List<Clinic> clinics = [];
  List<dynamic> suggestions = [];

  @override
  void initState() {
    super.initState();
    fetchNearbyClinics();
  }

  // =======================
  // AUTOSUGGEST SEARCH
  // =======================
  Future<void> fetchSuggestions(String query) async {
    if (query.length < 3) {
      setState(() => suggestions = []);
      return;
    }

    final url = Uri.parse(
      "https://nominatim.openstreetmap.org/search"
      "?q=$query&format=json&limit=5",
    );

    final response = await http.get(
      url,
      headers: {"User-Agent": "drds-demo-app"},
    );

    if (response.statusCode == 200) {
      setState(() {
        suggestions = json.decode(response.body);
      });
    }
  }

  void selectSuggestion(dynamic place) {
    final lat = double.parse(place['lat']);
    final lon = double.parse(place['lon']);

    setState(() {
      patientLocation = LatLng(lat, lon);
      suggestions = [];
      searchController.text = place['display_name'];
    });

    mapController.move(patientLocation, 14.5);
    fetchNearbyClinics();
  }

  // =======================
  // LIVE LOCATION (WEB)
  // =======================
  void useLiveLocation() {
    html.window.navigator.geolocation!.getCurrentPosition().then((pos) {
      setState(() {
        patientLocation = LatLng(
          pos.coords!.latitude!.toDouble(),
          pos.coords!.longitude!.toDouble(),
        );
      });

      mapController.move(patientLocation, 14.5);
      fetchNearbyClinics();
    });
  }

  // =======================
  // FETCH CLINICS (NODE + WAY + RELATION)
  // =======================
  Future<void> fetchNearbyClinics() async {
    const radius = 1500;

    final query =
        """
    [out:json];
    (
      node["amenity"="hospital"](around:$radius,${patientLocation.latitude},${patientLocation.longitude});
      way["amenity"="hospital"](around:$radius,${patientLocation.latitude},${patientLocation.longitude});
      relation["amenity"="hospital"](around:$radius,${patientLocation.latitude},${patientLocation.longitude});

      node["amenity"="clinic"](around:$radius,${patientLocation.latitude},${patientLocation.longitude});
      way["amenity"="clinic"](around:$radius,${patientLocation.latitude},${patientLocation.longitude});
      relation["amenity"="clinic"](around:$radius,${patientLocation.latitude},${patientLocation.longitude});
    );
    out center tags;
    """;

    final response = await http.post(
      Uri.parse("https://overpass.kumi.systems/api/interpreter"),
      body: {"data": query},
    );

    if (response.statusCode != 200) return;

    final data = json.decode(response.body);

    List<Clinic> fetched = [];

    for (var e in data['elements']) {
      final lat = e['lat'] ?? e['center']?['lat'];
      final lon = e['lon'] ?? e['center']?['lon'];
      if (lat == null || lon == null) continue;

      final name = e['tags']?['name'] ?? "Unnamed Clinic";

      final serviceData =
          hospitalServiceDB[name] ??
          {
            "services": [
              "General OPD",
              "Emergency",
              "Blood Test",
              "General Test",
            ],
            "timings": "OPD: 9 AM – 6 PM | Emergency: 24x7",
          };

      fetched.add(
        Clinic(
          name: name,
          location: LatLng((lat as num).toDouble(), (lon as num).toDouble()),
          services: List<String>.from(serviceData["services"]),
          timings: serviceData["timings"],
        ),
      );
    }

    setState(() {
      clinics = fetched;
    });
  }

  // =======================
  // CLINIC DETAILS POPUP
  // =======================
  void showClinicDetails(Clinic clinic) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              clinic.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text("🕒 Timings: ${clinic.timings}"),
            const SizedBox(height: 12),
            const Text(
              "Services Available",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...clinic.services.map(
              (s) => ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(s),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =======================
  // UI
  // =======================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(center: patientLocation, zoom: 14.5),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: patientLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.person_pin_circle,
                      color: Colors.blue,
                      size: 40,
                    ),
                  ),
                  ...clinics.map(
                    (c) => Marker(
                      point: c.location,
                      width: 36,
                      height: 36,
                      child: GestureDetector(
                        onTap: () => showClinicDetails(c),
                        child: const Icon(
                          Icons.local_hospital,
                          color: Colors.red,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // SEARCH BAR
          Positioned(
            top: 20,
            left: 15,
            right: 15,
            child: Column(
              children: [
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: TextField(
                    controller: searchController,
                    onChanged: fetchSuggestions,
                    decoration: InputDecoration(
                      hintText: "Search clinic or area",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.my_location),
                        onPressed: useLiveLocation,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (suggestions.isNotEmpty)
                  Container(
                    color: Colors.white,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: suggestions.length,
                      itemBuilder: (_, i) => ListTile(
                        title: Text(suggestions[i]['display_name']),
                        onTap: () => selectSuggestion(suggestions[i]),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
