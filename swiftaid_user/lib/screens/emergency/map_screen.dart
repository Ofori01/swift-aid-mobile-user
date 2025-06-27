import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../widgets/emergency_responders_bottom_sheet.dart';


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
                  builder: (context, scrollController) {
                    return EmergencyRespondersBottomSheet(
                      responders: widget.responders,
                      emergencyDetails: widget.emergencyDetails,
                      scrollController: scrollController,
                    );
                  },
                ),
              ],
            ),
    );
  }
}
