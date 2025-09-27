import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// Hide Mapbox's Position so we can alias it
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart'
    hide Position;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/emergency_responders_bottom_sheet.dart';
import 'package:flutter/services.dart' show Uint8List, rootBundle;
import '../../core/network/socket_service.dart'; // adjust path
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;
import 'package:swiftaid_user/main.dart' show accessToken;

import '../dashboard/main_tabs.dart';

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
  PolylineAnnotationManager? _polylineManager;
  Position? _geoPosition;
  final socket = SocketService().socket;

  final Map<String, PointAnnotation> _responderMarkers = {};

  String? _lockedResponderId;
  double? _lockedResponderLng;
  double? _lockedResponderLat;
  int? _lockedResponderEta;

  @override
  void initState() {
    super.initState();
    _initSocketAndLocation();
  }

  Future<void> _initSocketAndLocation() async {
    await _determinePosition();

    _lockedResponderId ??= _findFastestResponderId();
    if (_lockedResponderId != null) {
      final coords = _getResponderCoordsById(_lockedResponderId!);
      if (coords != null) {
        _lockedResponderLng = coords[0];
        _lockedResponderLat = coords[1];
      }
    }

    _listenForSocketUpdates();
  }

  void _listenForSocketUpdates() {

    socket?.on('eta-update', (data) async {
    final responderId = data['responderId']?.toString();
    if (responderId == null) return;

    final eta = (data['eta'] as num?)?.toInt(); // minutes already
    final distance = (data['distance'] as num?)?.toDouble();
    final loc = data['location'];
    if (loc == null) return;

    final lat = (loc['latitude'] as num).toDouble();
    final lng = (loc['longitude'] as num).toDouble();

    debugPrint(
          'ETA update: $responderId -> $eta min, $distance m (lat:$lat, lng:$lng)');

    await _updateResponderMarker(responderId, lng, lat,
        etaMinutes: eta); 

    if (responderId == _lockedResponderId) {
      _lockedResponderLng = lng;
      _lockedResponderLat = lat;
      _lockedResponderEta = eta;
      await _updateRouteAndFrame();
    }
  });

    socket?.on('emergency-status-update', (data) async {
      final emergencyId = data['emergencyId']?.toString();
      final status = data['status']?.toString();

      debugPrint('Emergency $emergencyId status updated: $status');

      if (status == 'Completed') {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('userId');

        if (userId != null) {
          socket?.emit('leave-room', {
            'roomId': emergencyId,
            'userType': 'user',
            'userId': userId,
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'A responder has arrived. Returning to Dashboard shortly…',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }

        Future.delayed(const Duration(seconds: 7), () {
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MainTabs()),
              (route) => false,
            );
          }
        });
      }
    });
  }


  Future<void> _updateResponderMarker(
    String id,
    double lng,
    double lat, {
    int? etaMinutes,
  }) async {
    if (_annotationManager == null) return;

    final role = _findRoleById(id);
    final name = _findNameById(id);

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

    final imageBytes = await _loadIcon(assetPath);
    final isLocked = id == _lockedResponderId;

    final options = PointAnnotationOptions(
      geometry: mbx.Point(coordinates: mbx.Position(lng, lat)),
      image: imageBytes,
      iconSize: isLocked ? 1.1 : 0.8,
      textField: name.isNotEmpty && etaMinutes != null
          ? '$name – ${etaMinutes}m'
          : (etaMinutes != null ? '${etaMinutes}m' : name),
      textSize: 15,
      textOffset: <double?>[0.0, -1.8],
      textColor: Colors.white.value,
      textHaloColor: Colors.black.withOpacity(0.7).value,
      textHaloWidth: 3.0,
      textHaloBlur: 1.0,
    );

    final existing = _responderMarkers[id];

    if (existing != null) {
      try {
        final newMarker = await _annotationManager!.create(options);
        _responderMarkers[id] = newMarker;

        try {
          await _annotationManager!.delete(existing);
        } catch (e) {
          debugPrint('Failed to delete old marker: $e');
        }
      } catch (e) {
        debugPrint('Failed to recreate marker: $e');
      }
      return;
    }

    final marker = await _annotationManager!.create(options);
    _responderMarkers[id] = marker;
  }


  String _findNameById(String responderId) {
    final sources = ['police_units', 'fire_trucks', 'ambulances'];
    for (final key in sources) {
      final list = widget.responders[key];
      if (list is List) {
        for (final r in list) {
          if (r is Map<String, dynamic>) {
            final rid =
                (r['responder_id'] ?? r['id'] ?? r['name'])?.toString();
            if (rid == responderId) return r['name']?.toString() ?? '';
          }
        }
      }
    }
    return '';
  }

  String _findRoleById(String responderId) {
    final responders = widget.responders;

    bool match(dynamic r) {
      if (r is Map<String, dynamic>) {
        return r['responder_id'] == responderId || r['id'] == responderId || r['name'] == responderId;
      }
      return false;
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
    return 'default'; 
  }

  String? _findFastestResponderId() {
    final all = <Map<String, dynamic>>[];

    void addList(String key) {
      final list = widget.responders[key];
      if (list is List) {
        for (var e in list) {
          if (e is Map<String, dynamic>) all.add(e);
        }
      }
    }

    addList('police_units');
    addList('fire_trucks');
    addList('ambulances');

    if (all.isEmpty) return null;

    all.sort((a, b) {
      final ta = (a['travelTime'] ?? double.infinity) as num;
      final tb = (b['travelTime'] ?? double.infinity) as num;
      return ta.compareTo(tb);
    });

    final first = all.first;
    return (first['responder_id'] ?? first['id'] ?? first['name'])?.toString();
  }

  List<double>? _getResponderCoordsById(String id) {
    List<MapEntry<String, dynamic>> flatten = [];
    void collect(String key) {
      final list = widget.responders[key];
      if (list is List) {
        for (var r in list) {
          if (r is Map<String, dynamic>) flatten.add(MapEntry(key, r));
        }
      }
    }

    collect('police_units');
    collect('fire_trucks');
    collect('ambulances');

    for (var entry in flatten) {
      final r = entry.value as Map<String, dynamic>;
      final rid = (r['responder_id'] ?? r['id'] ?? r['name'])?.toString();
      if (rid == id) {
        try {
          final coords = r['current_location']?['coordinates'];
          if (coords is List && coords.length >= 2) {
            final lng = (coords[0] as num).toDouble();
            final lat = (coords[1] as num).toDouble();
            return [lng, lat];
          }
        } catch (_) {}
      }
    }

    return null;
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

      if (_lockedResponderLat != null && _lockedResponderLng != null) {
        await _updateRouteAndFrame();
      }
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

  Future<void> _createMarker(
    double lng,
    double lat,
    String id, {
    Uint8List? imageData,
    double iconSize = 0.8,
    String? responderName,   
    int? etaMinutes,        
  }) async {
    if (_annotationManager == null) return;

    final label = (responderName != null && responderName.isNotEmpty)
        ? etaMinutes != null
            ? '$responderName – ${etaMinutes}m'
            : responderName
        : (etaMinutes != null ? '${etaMinutes}m' : null);

    final options = PointAnnotationOptions(
      geometry: mbx.Point(coordinates: mbx.Position(lng, lat)),
      iconSize: iconSize,
      textField: label,
      textSize: 15,
      textColor: Colors.white.value,
      textHaloColor: Colors.black.withOpacity(0.7).value,
      textHaloWidth: 3.0,
      textHaloBlur: 1.0,
      textOffset: [0, -1.8],    
      image: imageData,
      iconImage: imageData == null ? 'default_marker' : null,
    );

    final marker = await _annotationManager!.create(options);
    if (id.isNotEmpty) _responderMarkers[id] = marker;
  }

  Future<void> _addUserMarker() async {
    if (_geoPosition == null) return;
    await _createMarker(
      _geoPosition!.longitude,
      _geoPosition!.latitude,
      'user_location',
      imageData: await _loadIcon('assets/icons/location.png'),
      iconSize: 0.7,
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
          try {
            final coords = responder['current_location']['coordinates'];
            final lng = (coords[0] as num).toDouble();
            final lat = (coords[1] as num).toDouble();
            final id = (responder['responder_id'] ??
                responder['id'] ??
                responder['name'])?.toString() ?? '';
            final isLocked = id == _lockedResponderId;

            final name = responder['name']?.toString() ?? '';
            final travelSecs = (responder['travelTime'] as num?)?.toInt();
            final etaMin =
                travelSecs != null ? (travelSecs / 60).ceil() : null; // ★ convert

            await _createMarker(
              lng,
              lat,
              id,
              imageData: imageBytes,
              iconSize: isLocked ? 1.1 : 0.8,
              responderName: name,
              etaMinutes: etaMin,
            );
          } catch (_) {}
        }
      }
    }

    await addMarkers('police_units', 'assets/icons/police.png');
    await addMarkers('fire_trucks', 'assets/icons/fire.png');
    await addMarkers('ambulances', 'assets/icons/ambulance.png');
  }

  Future<List<mbx.Position>> _fetchRoute(
    double startLng,
    double startLat,
    double endLng,
    double endLat,
  ) async {
    final url =
        'https://api.mapbox.com/directions/v5/mapbox/driving/$startLng,$startLat;$endLng,$endLat'
        '?geometries=geojson&overview=full&access_token=$accessToken';

    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) throw Exception('Directions failed');

    final data = jsonDecode(res.body);
    final coords = data['routes'][0]['geometry']['coordinates'] as List;
    // Map to mbx.Position
    return coords
        .map((c) => mbx.Position((c[0] as num).toDouble(), (c[1] as num).toDouble()))
        .toList();
  }


  Future<void> _drawRouteToLockedResponder(
    double responderLng,
    double responderLat,
  ) async {
    if (_mapboxMap == null || _geoPosition == null) return;

    _polylineManager ??=
        await _mapboxMap!.annotations.createPolylineAnnotationManager();

    await _polylineManager!.deleteAll();

    final positions = await _fetchRoute(
      _geoPosition!.longitude,
      _geoPosition!.latitude,
      responderLng,
      responderLat,
    );

    final line = mbx.LineString(coordinates: positions);

    await _polylineManager!.create(
      mbx.PolylineAnnotationOptions(
        geometry: line,
        lineWidth: 4.0,
        lineColor: 0xFF007AFF,
      ),
    );
  }


  double _computeDistanceMeters(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  Future<void> _fitCameraToUserAndResponder(double responderLng, double responderLat) async {
    if (_mapboxMap == null || _geoPosition == null) return;

    final userLat = _geoPosition!.latitude;
    final userLng = _geoPosition!.longitude;
    // midpoint
    final midLat = (userLat + responderLat) / 2;
    final midLng = (userLng + responderLng) / 2;

    final dist = _computeDistanceMeters(userLat, userLng, responderLat, responderLng);

    double zoom;
    if (dist > 50000) {
      zoom = 8;
    } else if (dist > 20000) {
      zoom = 10;
    } else if (dist > 10000) {
      zoom = 11;
    } else if (dist > 5000) {
      zoom = 12;
    } else if (dist > 2000) {
      zoom = 13;
    } else if (dist > 800) {
      zoom = 14;
    } else {
      zoom = 15;
    }

    try {
      await _mapboxMap!.flyTo(
        mbx.CameraOptions(
          center: mbx.Point(coordinates: mbx.Position(midLng, midLat)),
          zoom: zoom,
        ),
        mbx.MapAnimationOptions(duration: 1000),
      );
    } catch (e) {
      debugPrint('Camera fit error: $e');
    }
  }

  Future<void> _updateRouteAndFrame() async {
    if (_lockedResponderLat == null || _lockedResponderLng == null || _geoPosition == null) return;
    await _drawRouteToLockedResponder(_lockedResponderLng!, _lockedResponderLat!);
    await _fitCameraToUserAndResponder(_lockedResponderLng!, _lockedResponderLat!);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You cannot leave while an emergency is active.'),
          ),
        );
        return false; 
      },
      child:  Scaffold(
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
                      // annotation managers
                      _annotationManager = await mapboxMap.annotations.createPointAnnotationManager();
                      _polylineManager ??= await mapboxMap.annotations.createPolylineAnnotationManager();

                      // add markers (user + responders)
                      await _addUserMarker();
                      await _addResponderMarkers();

                      // if locked responder known, draw route and frame
                      if (_lockedResponderLat != null && _lockedResponderLng != null) {
                        await _updateRouteAndFrame();
                      }
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
                      lockedResponderEta: _lockedResponderEta,
                      scrollController: scrollController,
                    ),
                  ),
                ],
              ),
      )
    );
  }

  @override
  void dispose() {
    socket?.off('eta-update');
    socket?.off('emergency-status-update');
    try {
      _annotationManager?.deleteAll();
    } catch (_) {}
    try {
      _polylineManager?.deleteAll();
    } catch (_) {}
    super.dispose();
  }
}
