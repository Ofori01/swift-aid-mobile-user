import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'map_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/socket_service.dart';

class EmergencyRequestScreen extends StatefulWidget {
  final String emergencyType;

  const EmergencyRequestScreen({super.key, required this.emergencyType});

  @override
  State<EmergencyRequestScreen> createState() => _EmergencyRequestScreenState();
}

class _EmergencyRequestScreenState extends State<EmergencyRequestScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  File? _image;
  bool _isLoading = false;
  String? userToken;
  String? userId;
  String userLocation = "Fetching location...";
  late String selectedType;

  @override
  void initState() {
    super.initState();
    _loadUserToken();
    selectedType = widget.emergencyType;
    _loadLocation();
  }

  Future<void> _loadUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userToken = prefs.getString('authToken');
      userId = prefs.getString('userId');
    });
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Select Image Source", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Use Camera"),
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await ImagePicker().pickImage(source: ImageSource.camera);
                  if (picked != null) {
                    setState(() => _image = File(picked.path));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text("Choose from Gallery"),
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    setState(() => _image = File(picked.path));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadLocation() async {
    try {
      Position position = await _getLocation();
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks.first;
      setState(() {
        userLocation = "${place.street}, ${place.locality}";
      });
    } catch (e) {
      userLocation = "Unable to fetch location";
    }
  }

  Future<Position> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception("Location services are disabled.");

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) throw Exception("Location permission denied forever.");
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _submitEmergency() async {
    if (_descriptionController.text.isEmpty || _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please provide all details.")));
      return;
    }

    if (userToken == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User not authenticated. Please log in again.")),
    );
    return;
  }

    try {
      setState(() => _isLoading = true);

      final location = await _getLocation();
      final uri = Uri.parse("https://swift-aid-backend.onrender.com/emergency/create");

      final request = http.MultipartRequest('POST', uri)
        ..fields['user_description'] = _descriptionController.text
        ..fields['emergency_type'] = selectedType
        ..fields['emergency_location'] = '[${location.longitude},${location.latitude}]'
        ..headers['Authorization'] = 'Bearer $userToken'; 

      final mimeType = lookupMimeType(_image!.path)!.split('/');
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        _image!.path,
        contentType: MediaType(mimeType[0], mimeType[1]),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {

        var data = json.decode(response.body);
        final responders = data["response"]["responders"];
        final emergencyDetails = data["response"]["emergency_details"];
        final emergency_id =  data["response"]["emergency_id"] as String;

        // final prefs = await SharedPreferences.getInstance();
        // final userId = prefs.getString('userId');   
        
        final socket = SocketService().socket;

        socket?.on('emergency-created', (payload) {
          final emergencyId = payload['emergencyId'];
          print('🚨 Emergency created: $emergencyId');

          
          // socket.emit('join-room', {
          //   'roomId': emergencyId,
          //   'userType': 'user',
          //   'userId': userId,
          // });

          // Optional: remove this listener if you only need it once
          socket.off('emergency-created');
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResponderMapScreen(
              responders: responders as Map<String, dynamic>,
              emergencyDetails: emergencyDetails as Map<String, dynamic>,
              emergencyId: emergency_id,
            ),
          ),
        );
      }else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to create request.")));
      }
      
    } catch (e) {
      debugPrint("Error: ${e.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Something went wrong.")));

    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget buildEmergencyChips() {
    final chips = [
      "Medical", "Violence", "Accident", "Natural Disaster", "Fire", "Rescue"
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips.map((type) {
        final isSelected = selectedType == type;
        return ChoiceChip(
          label: Text(type),
          selected: isSelected,
          onSelected: (_) => setState(() => selectedType = type),
          backgroundColor: Colors.grey.shade200,
          selectedColor: Colors.red.shade300,
          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Report Emergency")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LOCATION
            Row(
              children: [
                const Icon(Icons.location_pin, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Text(userLocation, style: const TextStyle(fontSize: 14))),
              ],
            ),
            const SizedBox(height: 20),

            const Text("Select Emergency Type", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            buildEmergencyChips(),
            const SizedBox(height: 20),

            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Describe your emergency',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text("Attach Image"),
            ),

            if (_image != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(_image!, height: 150, fit: BoxFit.cover),
              ),
            ],

            const SizedBox(height: 30),

            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _submitEmergency,
                    icon: const Icon(Icons.send),
                    label: const Text("Send Emergency Request"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
