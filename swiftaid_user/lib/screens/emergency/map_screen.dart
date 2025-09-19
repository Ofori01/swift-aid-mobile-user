import 'dart:async';
import 'package:flutter/material.dart';
// Hide Mapbox's Position so we can alias it
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart'
    hide Position;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx
    show Position, Point, CameraOptions, MapAnimationOptions;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/emergency_responders_bottom_sheet.dart';
import 'package:flutter/services.dart' show Uint8List, rootBundle;
import '../../core/network/socket_service.dart'; // adjust path


class ResponderMapScreen extends StatefulWidget {
  final Map<String, dynamic> responders;
  final Map<String, dynamic> emergencyDetails;
  final String emergencyId;

  const ResponderMapScreen({
    super.key,
    required this.responders,
    required this.emergencyDetails,
    required this.emergencyId,
  });

  @override
  State<ResponderMapScreen> createState() => _ResponderMapScreenState();
}

class _ResponderMapScreenState extends State<ResponderMapScreen> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _annotationManager;
  Position? _geoPosition;
  final socket = SocketService().socket;

  final Map<String, PointAnnotation> _responderMarkers = {};

  @override
  void initState() {
    super.initState();
    _initSocketAndLocation();
  }

  Future<void> _initSocketAndLocation() async {
    await _determinePosition();

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    socket?.emit('join-room', {
      'roomId': widget.emergencyId,
      'userType': 'user',
      'userId': userId,
    });

    _listenForSocketUpdates();
  }

  void _listenForSocketUpdates() {
    socket?.on('responder-location-update', (data) async {
      final responderId = data['responderId'];
      final lat = (data['location']['latitude'] as num).toDouble();
      final lng = (data['location']['longitude'] as num).toDouble();
      await _updateResponderMarker(responderId, lng, lat);
    });

    socket?.on('eta-update', (data) {
      final responderId = data['responderId'];
      final eta = data['eta'];
      final distance = data['distance'];
      debugPrint('ETA update: $responderId -> $eta min ($distance m)');
      // Update UI/bottom sheet if needed
    });
  }

  Future<void> _updateResponderMarker(String id, double lng, double lat) async {
    if (_annotationManager == null) return;

    // 🔍 find the responder’s role from the original responders map
    final role = _findRoleById(id);

    // pick icon based on role
    String assetPath;
    switch (role) {
      case 'police':
        assetPath = 'assets/icons/police.png';
        break;
      case 'fire':
        assetPath = 'assets/icons/fire.png';
        break;
      case 'ambulance':
        assetPath = 'assets/icons/ambulance.png';
        break;
      default:
        assetPath = 'assets/icons/location.png';
    }

    // remove old marker if it exists
    if (_responderMarkers.containsKey(id)) {
      await _annotationManager!.delete(_responderMarkers[id]!);
    }

    // create a new marker
    final imageBytes = await _loadIcon(assetPath);
    final newMarker = await _annotationManager!.create(
      PointAnnotationOptions(
        geometry: mbx.Point(coordinates: mbx.Position(lng, lat)),
        image: imageBytes,
        iconSize: 2.0,
      ),
    );
    _responderMarkers[id] = newMarker;
  }


  String _findRoleById(String responderId) {
    final responders = widget.responders;

    // Accept dynamic and cast inside
    bool match(dynamic r) {
      final map = r as Map<String, dynamic>;
      return map['_id'] == responderId || map['id'] == responderId;
    }

    if ((responders['police_units'] as List?)?.any(match) ?? false) {
      return 'police';
    }
    if ((responders['fire_trucks'] as List?)?.any(match) ?? false) {
      return 'fire';
    }
    if ((responders['ambulances'] as List?)?.any(match) ?? false) {
      return 'ambulance';
    }
    return 'default'; // fallback if not found
  }



  Future<void> _determinePosition() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever) return;
    }

    final pos = await Geolocator.getCurrentPosition();
    setState(() => _geoPosition = pos);

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
      {Uint8List? imageData, double iconSize = 2.0}) async {
    if (_annotationManager == null) return;

    final options = PointAnnotationOptions(
      geometry: mbx.Point(coordinates: mbx.Position(lng, lat)),
      iconSize: iconSize,
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

    Future<void> addMarkers(String key, String assetPath) async {
      final list = responders[key];
      if (list is List) {
        final imageBytes = await _loadIcon(assetPath);
        for (var responder in list) {
          final coords = responder['current_location']['coordinates'];
          final lng = (coords[0] as num).toDouble();
          final lat = (coords[1] as num).toDouble();
          await _createMarker(lng, lat, responder['name'],
              imageData: imageBytes, iconSize: 1.0);
        }
      }
    }

    await addMarkers('police_units', 'assets/icons/police.png');
    await addMarkers('fire_trucks', 'assets/icons/fire.png');
    await addMarkers('ambulances', 'assets/icons/ambulance.png');
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
                    await _addUserMarker();
                    await _addResponderMarkers();
                  },
                ),
                DraggableScrollableSheet(
                  initialChildSize: 0.4,
                  minChildSize: 0.25,
                  maxChildSize: 0.9,
                  builder: (context, scrollController) =>
                      EmergencyRespondersBottomSheet(
                    responders: widget.responders,
                    emergencyDetails: widget.emergencyDetails,
                    scrollController: scrollController,
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    socket?.off('responder-location-update');
    socket?.off('eta-update');
    _annotationManager?.deleteAll();
    super.dispose();
  }
}
