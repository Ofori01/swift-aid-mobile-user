import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:lottie/lottie.dart';
import '../emergency/emergency_request_screen.dart';

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
  String userLocation = "Fetching location...";

  @override
  void initState() {
    super.initState();
    getUserLocation().then((location) {
      setState(() {
        userLocation = location;
        // Text(userLocation);
      });
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
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return 'Location services are disabled.';
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return 'Location permissions are denied.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return 'Location permissions are permanently denied.';
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark place = placemarks[0];

    return "${place.street}, ${place.locality}";
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location Display
              Row(
                children: [
                  const Icon(Icons.location_pin, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      userLocation,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Emergency Header
              Row(
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
                  Lottie.asset('assets/lottie/dashboard1.json', width: 100, height: 100),
                ],
              ),

              const SizedBox(height: 30),

              // SOS Button
              Center(
                child: GestureDetector(
                  onLongPress: () {
                    // Handle SOS request trigger
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: Lottie.asset("assets/lottie/sos_button.json"),
                      ),
                      const Text(
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
              Wrap(
                spacing: 5,
                runSpacing: 10,
                children: [
                  GestureDetector(
                    onTap: () => _navigateToRequest("Medical", context),
                    child: const EmergencyChip(
                      icon: Icons.medical_services,
                      label: "Medical",
                      bgColor: Color(0xFFE9F99C),
                      iconColor: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _navigateToRequest("Violence", context),
                    child: const EmergencyChip(
                      icon: Icons.security,
                      label: "Violence",
                      bgColor: Color(0xFFFFC3E3),
                      iconColor: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _navigateToRequest("Accident", context),
                    child: const EmergencyChip(
                      icon: Icons.car_crash,
                      label: "Accident",
                      bgColor: Color(0xFFE0D7FF),
                      iconColor: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _navigateToRequest("Natural Disaster", context),
                    child: const EmergencyChip(
                      icon: Icons.apartment,
                      label: "Natural disaster",
                      bgColor: Color(0xFFC2F2E8),
                      iconColor: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _navigateToRequest("Fire", context),
                    child: const EmergencyChip(
                      icon: Icons.local_fire_department,
                      label: "Fire",
                      bgColor: Color(0xFFFFD6DA),
                      iconColor: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _navigateToRequest("Rescue", context),
                    child: const EmergencyChip(
                      icon: Icons.sos,
                      label: "Rescue",
                      bgColor: Color(0xFFFFEDB1),
                      iconColor: Colors.black,
                    ),
                  ),
                ],
              ),



            ],
          ),
        ),
      ),
    );
  }
}
