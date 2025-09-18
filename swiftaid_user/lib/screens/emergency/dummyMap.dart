import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class DummyMap extends StatelessWidget {
  const DummyMap({super.key});

  @override
  Widget build(BuildContext context) {
    // String accessToken = const String.fromEnvironment("ACCESS_TOKEN");
    // MapboxOptions.setAccessToken(accessToken);
    // Define options for your camera
    CameraOptions camera = CameraOptions(
      center: Point(coordinates: Position(-98.0, 39.5)), // Dummy coordinates
      zoom: 2,
      bearing: 0,
      pitch: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dummy Map'),
      ),
      body: MapWidget(
        cameraOptions: camera,
        onMapCreated: (MapboxMap mapboxMap) {
          print("Map created successfully");
        },
      ),
    );
  }
}