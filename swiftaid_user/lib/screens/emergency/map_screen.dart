import 'dart:async';
import 'package:flutter/material.dart';
// Hide Mapbox's Position so we can alias it
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart'
    hide Position;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx
    show Position, Point, CameraOptions, MapAnimationOptions;
import 'package:geolocator/geolocator.dart';
import '../../widgets/emergency_responders_bottom_sheet.dart';
import 'package:flutter/services.dart' show Uint8List, rootBundle;

class ResponderMapScreen extends StatefulWidget {
  final Map<String, dynamic> responders;
  final Map<String, dynamic> emergencyDetails;

  const ResponderMapScreen({
    super.key,
    required this.responders,
    required this.emergencyDetails,
  });

  @override
  State<ResponderMapScreen> createState() => _ResponderMapScreenState();
}

class _ResponderMapScreenState extends State<ResponderMapScreen> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _annotationManager;
  Position? _geoPosition; // geolocator Position

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    // request location permission if needed
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever) return;
    }

    final pos = await Geolocator.getCurrentPosition();
    setState(() => _geoPosition = pos);

    // once we have a position and the map/manager exist, add markers
    if (_annotationManager != null) {
      await _addUserMarker();
      await _addResponderMarkers();
      await _flyToUser();
    }
  }

  Future<void> _flyToUser() async {
    if (_mapboxMap == null || _geoPosition == null) return;
    await _mapboxMap!.flyTo(
      mbx.CameraOptions(
        center: mbx.Point(
          coordinates:
              mbx.Position(_geoPosition!.longitude, _geoPosition!.latitude),
        ),
        zoom: 14,
      ),
      mbx.MapAnimationOptions(duration: 1500),
    );
  }

  Future<void> _createMarker(double lng, double lat, String id,
    {Uint8List? imageData, double iconSize = 1.5}) async {
      if (_annotationManager == null) return;

      final options = PointAnnotationOptions(
        geometry: mbx.Point(coordinates: mbx.Position(lng, lat)),
        iconSize: iconSize,
        // if imageData is supplied we use it, else fallback to default sprite
        image: imageData,
        iconImage: imageData == null ? 'default_marker' : null,
      );

      await _annotationManager!.create(options);
    }

  Future<void> _addUserMarker() async {
    if (_geoPosition == null) return;
    await _createMarker(
      _geoPosition!.longitude,
      _geoPosition!.latitude,
      'user_location',
      imageData: await _loadIcon('assets/icons/location.png'),
      iconSize: 1.5,
    );

  }

  Future<Uint8List> _loadIcon(String assetPath) async {
    final bytes = await rootBundle.load(assetPath);
    return bytes.buffer.asUint8List();
  }

  Future<void> _addResponderMarkers() async {
    final responders = widget.responders;

    Future<void> addMarkersForAgency(String key, String assetPath) async {
      final list = responders[key];
      if (list is List) {
        final imageBytes = await _loadIcon(assetPath);
        for (var responder in list) {
          final coords = responder['current_location']['coordinates'];
          final lng = coords[0] as double;
          final lat = coords[1] as double;
          await _createMarker(lng, lat, responder['name'],
              imageData: imageBytes, iconSize: 2.5);
        }
      }
    }

    await addMarkersForAgency('police_units', 'assets/icons/police.png');
    await addMarkersForAgency('fire_trucks', 'assets/icons/fire.png');
    await addMarkersForAgency('ambulances', 'assets/icons/ambulance.png');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _geoPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                MapWidget(
                  key: const ValueKey("mapbox-map"),
                  styleUri: MapboxStyles.MAPBOX_STREETS,
                  cameraOptions: mbx.CameraOptions(
                    center: mbx.Point(
                      coordinates: mbx.Position(
                        _geoPosition!.longitude,
                        _geoPosition!.latitude,
                      ),
                    ),
                    zoom: 14,
                  ),
                  mapOptions: MapOptions(
                    pixelRatio: MediaQuery.of(context).devicePixelRatio,
                  ),
                  onMapCreated: (mapboxMap) async {
                    _mapboxMap = mapboxMap;
                    _annotationManager =
                        await mapboxMap.annotations.createPointAnnotationManager();
                    // add markers now that manager exists
                    await _addUserMarker();
                    await _addResponderMarkers();
                  },
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
