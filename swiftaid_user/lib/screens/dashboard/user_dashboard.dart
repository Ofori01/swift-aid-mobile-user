import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/network/socket_service.dart';
import '../emergency/map_screen.dart';
import 'package:geolocator/geolocator.dart';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:lottie/lottie.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../emergency/emergency_request_screen.dart';
import 'package:swiftaid_user/core/utils/location_helper.dart'; 

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();

}


class EmergencyChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color? iconColor;

  const EmergencyChip({
    super.key,
    required this.icon,
    required this.label,
    required this.bgColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white, // adaptive bg
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: iconColor ?? (isDark ? Colors.white : Colors.black)),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black, // adaptive text color
            ),
          ),
        ],
      ),
    );
  }
}


class _UserDashboardState extends State<UserDashboard> {
  bool _isLoading = false;
  String userLocation = "Fetching location...";
  String? userName;
  String? userToken;
  String? userId;


  @override
  void initState() {
    super.initState();
    _loadUserDetails();
    getUserLocation().then((location) {
      setState(() {
        userLocation = location;
        // Text(userLocation);
      });
    });
  }

  Future<void> _loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? 'User';
      userToken = prefs.getString('authToken');
      userId = prefs.getString('userId');
    });
  }
  
  void _navigateToRequest(String type, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmergencyRequestScreen(emergencyType: type),
      ),
    );
  }

  Future<String> getUserLocation() async {
    final loc = await LocationHelper.getReadableLocation(); // 👈 use the helper
    return loc;
  }

  Future<Position> _getLocation() async {
    final loc = await LocationHelper.getRawPosition();
    return loc;
  }

  Future<void> _submitEmergency() async {
    try {
      setState(() => _isLoading = true);

      if (userToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User token is missing. Please log in again.")),
        );
        return;
      }

      final location = await _getLocation();
      final uri = Uri.parse("https://swift-aid-backend.onrender.com/emergency/create");

      final request = http.MultipartRequest('POST', uri)
        ..fields['user_description'] = "I need help urgently"
        ..fields['emergency_type'] = "Other"
        ..fields['emergency_location'] = '[${location.longitude},${location.latitude}]'
        ..headers['Authorization'] = 'Bearer $userToken';

      // Load image from assets as bytes
      ByteData byteData = await rootBundle.load('assets/icons/police_icon.jpeg');
      Uint8List imageBytes = byteData.buffer.asUint8List();

      // Detect MIME type
      final mimeType = lookupMimeType('police_icon.jpeg', headerBytes: imageBytes)!.split('/');

      // Add image directly from memory
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: 'police_icon.jpeg',
        contentType: MediaType(mimeType[0], mimeType[1]),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {

        var data = json.decode(response.body);
        final responders = data["response"]["responders"];
        final emergencyDetails = data["response"]["emergency_details"];
        final emergency_id = data["response"]["emergency_id"];

        final socket = SocketService().socket;

        socket?.on('emergency-created', (payload) {

          final emergencyId = payload['emergencyId'];
          print('🚨 Emergency created: $emergencyId');

          
          socket.emit('join-room', {
            'roomId': emergencyId,
            'userType': 'user',
            'userId': userId,
          });

          // Optional: remove this listener if you only need it once
          socket.off('emergency-created');
        });

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ResponderMapScreen(
            responders: responders as Map<String, dynamic>,
            emergencyDetails: emergencyDetails as Map<String, dynamic>,
            emergencyId: emergency_id,
          )),
        );

      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to create request.")));
      }

    } catch (e) {
      debugPrint("Error: ${e.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Something went wrong.")));

    } finally {
      setState(() => _isLoading = false);
    }
  }
  

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 🔒 Fixed Header: Location + Notification
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              decoration: BoxDecoration(
                // color: theme.scaffoldBackgroundColor,
                color: theme.brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[200],
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.white12 : Colors.black12,
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_pin, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      userLocation,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.notifications_active, color: theme.iconTheme.color),
                    onPressed: () {
                      // TODO: Navigate to notifications
                    },
                  ),
                ],
              ),
            ),
            

            // 🔄 Scrollable Responsive Body
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            
                            // Emergency Header
                            // Welcome + Emergency Header
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome, ${userName ?? 'User'} 👋',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: const [
                                          Text(
                                            'Are you in an emergency?',
                                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Press the SOS button, your live location will be shared with the nearest help centre.',
                                            style: TextStyle(fontSize: 16, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Lottie.asset('assets/lottie/dashboard1.json', width: 105),
                                  ],
                                ),
                              ],
                            ),


                            const SizedBox(height: 30),

                            // SOS Button
                            Center(
                              child: GestureDetector(
                                onLongPress: _isLoading
                                    ? null
                                    : () async {
                                        HapticFeedback.vibrate();
                                        await _submitEmergency();
                                      },
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 200,
                                      height: 200,
                                      child: Lottie.asset("assets/lottie/sos_button.json"),
                                    ),
                                    _isLoading
                                        ? const CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          )
                                        : const Text(
                                            'SOS',
                                            style: TextStyle(
                                              fontSize: 28,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black54,
                                                  blurRadius: 4,
                                                  offset: Offset(1, 1),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 30),

                            const Text(
                              "What's your emergency?",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 10),

                            // Emergency Type Chips
                            Wrap(
                              spacing: 5,
                              runSpacing: 10,
                              children: [
                                _buildChip("Medical", Icons.medical_services, const Color(0xFFE9F99C)),
                                _buildChip("Violence", Icons.security, const Color(0xFFFFC3E3)),
                                _buildChip("Accident", Icons.car_crash, const Color(0xFFE0D7FF)),
                                _buildChip("Natural Disaster", Icons.apartment, const Color(0xFFC2F2E8)),
                                _buildChip("Fire", Icons.local_fire_department, const Color(0xFFFFD6DA)),
                                _buildChip("Rescue", Icons.sos, const Color(0xFFFFEDB1)),
                              ],
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, IconData icon, Color bgColor) {
    return GestureDetector(
      onTap: () => _navigateToRequest(label, context),
      child: EmergencyChip(
        icon: icon,
        label: label,
        bgColor: bgColor,
        iconColor: Colors.black,
      ),
    );
  }
}
