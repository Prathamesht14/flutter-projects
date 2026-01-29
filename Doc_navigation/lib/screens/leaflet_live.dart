import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';

class LeafletLiveTrackingPage extends StatefulWidget {
  const LeafletLiveTrackingPage({super.key});

  @override
  State<LeafletLiveTrackingPage> createState() =>
      _LeafletLiveTrackingPageState();
}

class _LeafletLiveTrackingPageState extends State<LeafletLiveTrackingPage> {
  final String viewType = 'leaflet-map-view';

  @override
  void initState() {
    super.initState();

    ui.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      // MAP CONTAINER
      final mapDiv = html.DivElement()
        ..id = 'map'
        ..style.width = '100%'
        ..style.height = '100vh';

      // ADD JS AFTER DOM ATTACH
      Future.delayed(const Duration(milliseconds: 100), () {
        final script = html.ScriptElement()
          ..type = 'text/javascript'
          ..text = '''
              const map = L.map('map').setView([18.5204, 73.8567], 14);

              L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                maxZoom: 19,
                attribution: '© OpenStreetMap contributors'
              }).addTo(map);

              // Patient marker
              L.marker([18.5204, 73.8567])
                .addTo(map)
                .bindPopup("🧑‍🦱 Patient Location")
                .openPopup();

              // Doctor route
              const route = [
                [18.514, 73.847],
                [18.516, 73.849],
                [18.518, 73.851],
                [18.519, 73.853],
                [18.520, 73.855],
                [18.5204, 73.8567]
              ];

              let i = 0;

              const doctor = L.marker(route[0], {
                icon: L.icon({
                  iconUrl: 'https://cdn-icons-png.flaticon.com/512/387/387561.png',
                  iconSize: [40, 40],
                  iconAnchor: [20, 40]
                })
              }).addTo(map).bindPopup("🧑‍⚕️ Doctor on the way");

              setInterval(() => {
                i++;
                if (i >= route.length) {
                  doctor.bindPopup("🧑‍⚕️ Doctor Arrived").openPopup();
                  return;
                }
                doctor.setLatLng(route[i]);
                map.panTo(route[i]);
              }, 2000);
            ''';

        html.document.body!.append(script);
      });

      return mapDiv;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("DRDS – Live Doctor Tracking")),
      body: SizedBox.expand(child: HtmlElementView(viewType: viewType)),
    );
  }
}
