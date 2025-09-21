import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart' as latLng;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftaid_user/core/location_helper.dart';
import 'package:swiftaid_user/core/overpass_service.dart';

/// Simple POI model
class POI {
  final String name;
  final latLng.LatLng location;
  POI({required this.name, required this.location});

  Map<String, dynamic> toJson() =>
      {'name': name, 'lat': location.latitude, 'lng': location.longitude};

  static POI fromJson(Map<String, dynamic> j) => POI(
        name: j['name'],
        location: latLng.LatLng(j['lat'], j['lng']),
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
  latLng.LatLng? _currentLatLng;
  List<Marker> _poiMarkers = [];
  List<POI> _pois = [];
  bool _loadingPois = false;

  final List<Map<String, String>> safetyTips = [
    {
      'title': 'CPR Basics',
      'desc': 'Push hard & fast in the chest center, 100–120/min.'
    },
    {
      'title': 'Fire Safety',
      'desc': 'Stop, drop & roll if clothes catch fire. Keep exits clear.'
    },
    {
      'title': 'Emergency Numbers',
      'desc': 'Know 112 (National), 191 (Fire), 193 (Police) in Ghana.'
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location/POI error: $e')),
        );
      }
    }
  }

  Future<void> _fetchPOIs(double lat, double lon) async {
    setState(() => _loadingPois = true);
    try {
      final poisRaw = await OverpassService.fetchPOIs(lat, lon, radius: 3000);

      // convert to POI model list
      final poiList = poisRaw.map<POI>((p) {
        final name = (p['name'] ?? 'Unknown') as String;
        final plat = (p['lat'] as num).toDouble();
        final plon = (p['lon'] as num).toDouble();
        return POI(name: name, location: latLng.LatLng(plat, plon));
      }).toList();

      // build markers
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
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList();

      // update state & cache
      setState(() {
        _pois = poiList;
        _poiMarkers = markers;
      });
      await _cachePOIs(poiList);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load POIs: $e')),
        );
      }
      setState(() => _poiMarkers = []);
    } finally {
      setState(() => _loadingPois = false);
    }
  }

  void _showPoiDialog(String name, String type) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(name),
        content: Text('Type: $type'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
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
          tabs: const [
            Tab(text: 'Nearby Resources'),
            Tab(text: 'Safety Tips'),
          ],
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
        child: const Icon(Icons.person_pin_circle,
            color: Colors.red, size: 34),
      ),
      ..._poiMarkers,
    ];

    return Stack(
      children: [
        FlutterMap(
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
                size: const Size(40,40),
                markers: markers,
                builder: (context, cluster) => CircleAvatar(
                  backgroundColor: Colors.red,
                  child: Text('${cluster.length}'),
                ),
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 20,
          left: 16,
          right: 16,
          child: Card(
            color: isDark ? Colors.grey[900] : Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: Icon(Icons.place, color: red),
              title: const Text('Nearby Hospitals & Stations'),
              subtitle: Text(_loadingPois
                  ? 'Loading nearby places...'
                  : 'Showing live/cached POIs'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTipsTab(Color red, bool isDark) {
    return PageView.builder(
      itemCount: safetyTips.length,
      controller: PageController(viewportFraction: 0.9),
      itemBuilder: (context, index) {
        final tip = safetyTips[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          child: Card(
            color: isDark ? Colors.grey[850] : Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lightbulb, size: 60, color: red),
                  const SizedBox(height: 20),
                  Text(
                    tip['title']!,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tip['desc']!,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
