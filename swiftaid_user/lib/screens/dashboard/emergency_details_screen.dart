import 'package:flutter/material.dart';
import 'package:swiftaid_user/core/utils/utils.dart';

class EmergencyDetailScreen extends StatefulWidget {
  final Map<String, dynamic> emergency;
  const EmergencyDetailScreen({Key? key, required this.emergency})
      : super(key: key);

  @override
  State<EmergencyDetailScreen> createState() => _EmergencyDetailScreenState();
}

class _EmergencyDetailScreenState extends State<EmergencyDetailScreen> {
  String? _readableLocation;
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    final coords = widget.emergency['emergency_location']['coordinates'];
    final lat = coords[1];
    final lng = coords[0];

    final address = await getAddressFromCoordinates(lat, lng);
    if (mounted) {
      setState(() {
        _readableLocation = address;
        _loadingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const swiftRed = Color(0xFFB71C1C);
    final emergency = widget.emergency;

    // Extract responder counts
    final selected = emergency['selected_responders'] ?? {};
    final ambulances = (selected['ambulances'] as List? ?? []).length;
    final fireTrucks = (selected['fire_trucks'] as List? ?? []).length;
    final policeUnits = (selected['police_units'] as List? ?? []).length;

    // Response metrics
    final metrics = emergency['response_metrics'] ?? {};

    // AI recommendations
    final aiRec = emergency['ai_recommendations'] ?? {};
    final recommendedResources = aiRec['recommended_resources'] ?? {};

    return Scaffold(
      appBar: AppBar(
        backgroundColor: swiftRed,
        title: Text(emergency['emergency_type'] ?? 'Emergency Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Emergency Info ---
          _sectionCard(
            context,
            icon: Icons.info_outline,
            title: 'Emergency Info',
            children: [
              _info(context, 'Description', emergency['description']),
              _info(context, 'Severity', emergency['severity']),
              _info(context, 'Status', emergency['status']),
              _info(context, 'Admin Notes', emergency['admin_notes']),
              Row(
                children: [
                  const Icon(Icons.location_on, color: swiftRed),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _loadingLocation
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _readableLocation ?? 'Unknown Location',
                            style: TextStyle(
                              color: isDark ? Colors.grey[300] : Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // --- Responders Summary ---
          _sectionCard(
            context,
            icon: Icons.support_agent,
            title: 'Responders Assigned',
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (ambulances > 0)
                    _responderChip(Icons.local_hospital, 'Ambulances', ambulances, swiftRed),
                  if (fireTrucks > 0)
                    _responderChip(Icons.local_fire_department, 'Fire Trucks', fireTrucks, Colors.orange),
                  if (policeUnits > 0)
                    _responderChip(Icons.local_police, 'Police', policeUnits, Colors.blue),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // --- AI Recommendations ---
          _sectionCard(
            context,
            icon: Icons.smart_toy,
            title: 'AI Recommendations',
            children: [
              _info(context, 'Severity Level', aiRec['severity_level']),
              _info(context, 'Justification', aiRec['justification']),
              _info(context, 'Estimated Response Time',
                  '${aiRec['estimated_response_time'] ?? metrics['average_response_time'] ?? ''} mins'),
              _info(context, 'Recommended Resources',
                  'Ambulances: ${recommendedResources['ambulances'] ?? 0}, Fire Trucks: ${recommendedResources['fire_trucks'] ?? 0}, Police Units: ${recommendedResources['police_units'] ?? 0}'),
            ],
          ),
          const SizedBox(height: 16),

          // --- Response Metrics ---
          _sectionCard(
            context,
            icon: Icons.analytics,
            title: 'Response Metrics',
            children: [
              _info(context, 'Total Responders Selected', metrics['total_responders_selected']),
              _info(context, 'Fastest Responder Time', '${metrics['fastest_responder_time'] ?? ''} secs'),
              _info(context, 'Average Response Time', '${metrics['average_response_time'] ?? ''} secs'),
              _info(context, 'Route Calculation Method', metrics['route_calculation_method']),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(BuildContext context,
          {required IconData icon, required String title, required List<Widget> children}) =>
      Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[850] : Colors.white,
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: const Color(0xFFB71C1C)),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      );

  Widget _info(BuildContext context, String label, dynamic value, {String suffix = ''}) =>
      value == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : Colors.black87,
                    fontSize: 14,
                  ),
                  children: [
                    TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: '$value$suffix'),
                  ],
                ),
              ),
            );

  Widget _responderChip(IconData icon, String label, int count, Color color) =>
      Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Chip(
          backgroundColor: color.withOpacity(0.1),
          avatar: Icon(icon, color: color, size: 18),
          label: Text('$count $label', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
      );
}
