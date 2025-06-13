import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class ResponderMapScreen extends StatefulWidget {
  final Map<String, dynamic> responders;
  final Map<String, dynamic> emergencyDetails;

  const ResponderMapScreen({
    super.key, 
    required this.responders, 
    required this.emergencyDetails
  });

  @override
  State<ResponderMapScreen> createState() => _ResponderMapScreenState();
}

class _ResponderMapScreenState extends State<ResponderMapScreen> {
  late GoogleMapController _mapController;
  LatLng? userLocation;
  final Set<Marker> _markers = {};

  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      userLocation = LatLng(position.latitude, position.longitude);
    });

    _addUserMarker();
    _addResponderMarkers();
  }

  void _addUserMarker() {
    if (userLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: userLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
          infoWindow: const InfoWindow(title: 'You'),
        ),
      );
    }
  }

  void _addResponderMarkers() {
    final responders = widget.responders;

    void addMarkersForAgency(String key, double hue) {
      if (responders[key] != null) {
        for (var responder in responders[key]) {
          final coordinates = responder['current_location']['coordinates'];
          final lat = coordinates[0] as double;
          final lng = coordinates[1] as double;
          final name = responder['name'] as String;

          _markers.add(
            Marker(
              markerId: MarkerId(name),
              position: LatLng(lat, lng),
              icon: BitmapDescriptor.defaultMarkerWithHue(hue),
              infoWindow: InfoWindow(title: name),
            ),
          );
        }
      }
    }

    addMarkersForAgency('police_units', BitmapDescriptor.hueBlue);
    addMarkersForAgency('fire_trucks', BitmapDescriptor.hueRed);
    addMarkersForAgency('ambulances', BitmapDescriptor.hueGreen);

    setState(() {});
  }

  Widget _buildCategoryList() {
    final categories = {
      'police_units': 'Police',
      'fire_trucks': 'Fire Service',
      'ambulances': 'Ambulance',
    };

    return Wrap(
      spacing: 8,
      children: categories.entries.map((entry) {
        final key = entry.key;
        final label = entry.value;
        final count = widget.responders[key]?.length ?? 0;
        if (count == 0) return const SizedBox.shrink();

        return ChoiceChip(
          label: Text("$label ($count)"),
          selected: selectedCategory == key,
          onSelected: (_) {
            setState(() => selectedCategory = key);
          },
        );
      }).toList(),
    );
  }

  Widget _buildResponderDetails() {
    if (selectedCategory == null || widget.responders[selectedCategory] == null) {
      return const SizedBox.shrink();
    }

    final responders = widget.responders[selectedCategory] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: responders.map<Widget>((responder) {
        final name = responder['name'];
        final travelTime = responder['travelTime'];
        final etaMinutes = (travelTime / 60).ceil(); // convert seconds to minutes
        return ListTile(
          leading: const Icon(Icons.directions_run),
          title: Text(name),
          subtitle: Text("ETA: $etaMinutes min"),
        );
      }).toList(),
    );
  }

  Widget _buildEmergencyDetails() {
  final type = widget.emergencyDetails['emergency_type'] ?? 'N/A';
  // final location = widget.emergencyDetails['emergency_location'] ?? 'Unknown location';
  final description = widget.emergencyDetails['emergency_description'] ?? 'No description';

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Divider(),
      const SizedBox(height: 10),
      const Text("Emergency Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 8),
      Text("Type: $type"),
      Text("Location: East Legon"),
      Text("Description: $description"),
    ],
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: userLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: userLocation!,
                    zoom: 14,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),
                DraggableScrollableSheet(
                  initialChildSize: 0.4,
                  minChildSize: 0.25,
                  maxChildSize: 0.9,
                  builder: (context, scrollController) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
                    ),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text(
                              "Emergency Responders",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildCategoryList(),
                          const SizedBox(height: 16),
                          _buildResponderDetails(),
                          const SizedBox(height: 16),
                          _buildEmergencyDetails(),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
    );
  }
}
