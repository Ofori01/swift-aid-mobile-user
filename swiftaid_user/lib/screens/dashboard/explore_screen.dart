import 'dart:convert';
import 'dart:math' show sin, cos, sqrt, atan2, pi;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart' as latLng;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftaid_user/core/utils/location_helper.dart';
import 'package:swiftaid_user/core/utils/overpass_service.dart';
import 'safety_tip_detail.dart';


/// Simple POI model with distance & ETA helpers
class POI {
  final String name;
  final latLng.LatLng location;
  double distanceKm;
  int etaMin;
  POI({
    required this.name,
    required this.location,
    this.distanceKm = 0,
    this.etaMin = 0,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'lat': location.latitude,
        'lng': location.longitude,
        'distanceKm': distanceKm,
        'etaMin': etaMin,
      };

  static POI fromJson(Map<String, dynamic> j) => POI(
        name: j['name'],
        location: latLng.LatLng(j['lat'], j['lng']),
        distanceKm: (j['distanceKm'] ?? 0).toDouble(),
        etaMin: (j['etaMin'] ?? 0).toInt(),
      );
}

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MapController _mapController = MapController();
  latLng.LatLng? _currentLatLng;
  List<Marker> _poiMarkers = [];
  List<POI> _pois = [];
  bool _loadingPois = false;

  final List<Map<String, dynamic>> safetyTips = [
    {
      'title': 'CPR & First Aid',
      'desc':
          'Check responsiveness and breathing. Call 112 immediately. Push hard & fast in the chest center, 100–120 compressions per minute.',
      'details': '''
  1️⃣ Ensure the area is safe for both you and the victim.
  2️⃣ Check responsiveness by tapping the shoulders and shouting.
  3️⃣ Call 112 or ask someone nearby to call and put the phone on speaker.
  4️⃣ If not breathing normally, begin chest compressions:
    • Place the heel of one hand on the chest center.
    • Push hard and fast at 100–120 compressions per minute, depth ~5 cm.
  5️⃣ If trained, give 2 rescue breaths after every 30 compressions.
  6️⃣ Continue until professional help arrives or the person shows signs of life.
  ''',
      'videoUrl': 'https://www.youtube.com/watch?v=cosVBV96E2g',
    },
    {
      'title': 'Fire Safety',
      'desc':
          'Stop, drop & roll if clothes catch fire. Keep exits clear. Never use elevators during a fire.',
      'details': '''
  1️⃣ If clothes catch fire: Stop, Drop to the ground, and Roll to smother flames.
  2️⃣ Crawl low under smoke to avoid inhaling toxic fumes.
  3️⃣ Feel doors with the back of your hand before opening—if hot, find another exit.
  4️⃣ Never use elevators; use stairs only.
  5️⃣ Call 112 once safe and give your exact location.
  ''',
      'videoUrl': 'https://www.youtube.com/watch?v=J5jhhIdhU5Q',
    },
    {
      'title': 'Emergency Contacts',
      'desc':
          'Memorize key numbers in Ghana: 112 (National Emergency), 191 (Fire), 193 (Police). Save them on your phone.',
      'details': '''
  1️⃣ Save these numbers in your phone and label them clearly:
    • 112 – National Emergency (all services)
    • 191 – Fire Service
    • 193 – Police
  2️⃣ Post them visibly at home and work.
  3️⃣ Teach children how and when to call these numbers.
  4️⃣ Always state your location clearly when calling.
  ''',
      'videoUrl': '', // optional
    },
    {
      'title': 'Road Accident Safety',
      'desc':
          'Keep calm, move to a safe area if possible, avoid moving the injured, and wait for responders. Provide first aid if trained.',
      'details': '''
  1️⃣ Park safely and turn on hazard lights.
  2️⃣ Check for injuries; call 112 if anyone is hurt.
  3️⃣ Do not move seriously injured victims unless there is immediate danger (e.g., fire).
  4️⃣ If trained, provide first aid such as controlling bleeding or CPR.
  5️⃣ Exchange contact and insurance details if appropriate, but stay at the scene until help arrives.
  ''',
      'videoUrl': 'https://www.youtube.com/watch?v=3oT-evcOaUM',
    },
    {
      'title': 'Flood Safety',
      'desc':
          'Avoid walking or driving through flood waters. Move to higher ground and stay informed via local alerts.',
      'details': '''
  1️⃣ Move immediately to higher ground—never wait for evacuation orders.
  2️⃣ Avoid walking or driving through moving water; just 15 cm of water can knock you down.
  3️⃣ Disconnect electrical appliances if it’s safe to do so.
  4️⃣ Listen to radio or official alerts for updates.
  5️⃣ Do not return home until authorities say it’s safe.
  ''',
      'videoUrl': 'https://www.youtube.com/watch?v=1fXSPFv_xW8',
    },
    {
      'title': 'Fire Extinguisher Use',
      'desc':
          'Remember PASS: Pull the pin, Aim at base, Squeeze handle, Sweep side to side.',
      'details': '''
  1️⃣ Identify a safe escape route before approaching the fire.
  2️⃣ Remember PASS:
    • **Pull** the safety pin.
    • **Aim** the nozzle at the base of the flames.
    • **Squeeze** the handle to release the agent.
    • **Sweep** the nozzle side to side until the fire is out.
  3️⃣ If the fire grows or spreads, evacuate immediately and call 112.
  ''',
      'videoUrl': 'https://www.youtube.com/watch?v=lUojO1HvC8c',
    },
  ];


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCachedPOIs();
    _loadUserLocationAndPOIs();
  }

  Future<void> _loadUserLocationAndPOIs() async {
    try {
      final pos = await LocationHelper.getRawPosition();
      setState(() {
        _currentLatLng = latLng.LatLng(pos.latitude, pos.longitude);
      });
      await _fetchPOIs(pos.latitude, pos.longitude);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Location/POI error: $e')));
      }
    }
  }

  Future<void> _fetchPOIs(double lat, double lon) async {
    setState(() => _loadingPois = true);
    try {
      final poisRaw = await OverpassService.fetchPOIs(lat, lon, radius: 3000);

      final poiList = poisRaw.map<POI>((p) {
        final name = (p['name'] ?? 'Unknown') as String;
        final plat = (p['lat'] as num).toDouble();
        final plon = (p['lon'] as num).toDouble();
        final location = latLng.LatLng(plat, plon);
        final dist = _distanceKm(lat, lon, plat, plon);
        final eta = (dist / 40 * 60).round(); // assume 40 km/h travel
        return POI(name: name, location: location, distanceKm: dist, etaMin: eta);
      }).toList();

      final markers = poisRaw.map<Marker>((p) {
        final type = (p['type'] ?? 'unknown') as String;
        final iconData = _iconForType(type);
        final color = _colorForType(type);
        final plat = (p['lat'] as num).toDouble();
        final plon = (p['lon'] as num).toDouble();
        final name = (p['name'] ?? 'Unknown') as String;
        return Marker(
          point: latLng.LatLng(plat, plon),
          width: 44,
          height: 44,
          child: GestureDetector(
            onTap: () => _showPoiDialog(name, type),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(iconData, color: color, size: 30),
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ],
            ),
          ),
        );
      }).toList();

      setState(() {
        _pois = poiList;
        _poiMarkers = markers;
      });
      await _cachePOIs(poiList);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to load POIs: $e')));
      }
      setState(() => _poiMarkers = []);
    } finally {
      setState(() => _loadingPois = false);
    }
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Earth radius km
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  void _showPoiDialog(String name, String type) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(name),
        content: Text('Type: $type'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'hospital':
      case 'clinic':
        return Icons.local_hospital;
      case 'pharmacy':
        return Icons.local_pharmacy;
      case 'police':
        return Icons.local_police;
      case 'fire_station':
      case 'fire':
        return Icons.local_fire_department;
      default:
        return Icons.place;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'hospital':
      case 'clinic':
        return Colors.red;
      case 'pharmacy':
        return Colors.green;
      case 'police':
        return Colors.blue;
      case 'fire_station':
      case 'fire':
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }

  Future<void> _cachePOIs(List<POI> pois) async {
    final prefs = await SharedPreferences.getInstance();
    final data = pois.map((p) => p.toJson()).toList();
    await prefs.setString('cached_pois', jsonEncode(data));
  }

  Future<void> _loadCachedPOIs() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('cached_pois');
    if (str != null) {
      final List list = jsonDecode(str);
      setState(() {
        _pois = list.map((e) => POI.fromJson(e)).toList();
        _poiMarkers = _pois
            .map((p) => Marker(
                  point: p.location,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.location_on, color: Colors.green),
                ))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const red = Color(0xFFB71C1C);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: red,
        title: const Text('Explore'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [Tab(text: 'Nearby Resources'), Tab(text: 'Safety Tips')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildResourcesTab(red, isDark),
          _buildTipsTab(red, isDark),
        ],
      ),
    );
  }

  Widget _buildResourcesTab(Color red, bool isDark) {
    if (_currentLatLng == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final markers = <Marker>[
      Marker(
        point: _currentLatLng!,
        width: 48,
        height: 48,
        child: const Icon(Icons.person_pin_circle, color: Colors.red, size: 34),
      ),
      ..._poiMarkers,
    ];

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentLatLng!,
            initialZoom: 14,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'swiftaid_user',
            ),
            MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                maxClusterRadius: 45,
                size: const Size(40, 40),
                markers: markers,
                builder: (context, cluster) => CircleAvatar(
                  backgroundColor: Colors.red,
                  child: Text('${cluster.length}'),
                ),
              ),
            ),
          ],
        ),
        DraggableScrollableSheet(
          initialChildSize: 0.25,
          minChildSize: 0.1,
          maxChildSize: 0.7,
          builder: (context, scrollController) {
            return Material(
              color: isDark ? Colors.grey[900] : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              elevation: 8,
              child: Column(
                mainAxisSize: MainAxisSize.min,   // ✅ prevents overflow
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: Icon(Icons.place, color: red),
                    title: const Text('Nearby Hospitals & Stations'),
                    subtitle: Text(
                      _loadingPois ? 'Loading nearby places...' : 'Tap an item to focus',
                    ),
                  ),
                  const Divider(height: 1),
                  // ✅ Expanded ensures the list uses only remaining space
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: _pois.length,
                      itemBuilder: (context, i) {
                        final poi = _pois[i];
                        return ListTile(
                          leading: const Icon(Icons.place, color: Colors.teal),
                          title: Text(poi.name),
                          subtitle: Text(
                            '${poi.distanceKm.toStringAsFixed(2)} km • ETA ${poi.etaMin} min',
                          ),
                          onTap: () {
                            _mapController.move(poi.location, 16);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTipsTab(Color red, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: PageView.builder(
        itemCount: safetyTips.length,
        controller: PageController(viewportFraction: 0.85),
        itemBuilder: (context, index) {
          final tip = safetyTips[index];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SafetyTipDetail(tip: tip),
                  ),
                );
              },
              child: Card(
                color: isDark ? Colors.grey[850] : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.lightbulb, size: 50, color: red),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        tip['title']!,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Text(
                            tip['desc']!,
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.grey[300] : Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
