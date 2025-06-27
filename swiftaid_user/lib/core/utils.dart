import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

// Reverse geocode using OpenStreetMap/Nominatim
Future<String> getAddressFromCoordinates(double lat, double lng) async {
  final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng');

  final response = await http.get(url, headers: {
    'User-Agent': 'SwiftAidApp/1.0 (ubaidaabdul723@gmail.com)'
  });

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['display_name'] ?? 'Unknown Location';
  } else {
    return 'Unknown Location';
  }
}

// Icon by emergency type
IconData getEmergencyTypeIcon(String type) {
  switch (type.toLowerCase()) {
    case 'medical':
      return Icons.medical_services;
    case 'fire':
      return Icons.local_fire_department;
    case 'accident':
      return Icons.car_crash;
    case 'violence':
      return Icons.local_police;
    case 'natural disaster':
      return Icons.apartment;
    default:
      return Icons.warning_amber_rounded;
  }
}
