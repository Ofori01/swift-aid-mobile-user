// lib/services/socket_events.dart
import 'socket_service.dart';

/// Central place to register all socket event listeners.
class SocketEvents {
  final SocketService socketService = SocketService();

  void setup({
    required String currentUserId,
    required void Function(Map<String, dynamic>) showResponderInfo,
    required void Function(String responderId, Map<String, dynamic> location)
        updateResponderMarker,
    required void Function(dynamic eta, dynamic distance) updateETAonUI,
    required void Function(String status) showStatusChange,
  }) {
    final s = socketService.socket;
    if (s == null) return;

    // Fired when a new emergency is created for this user
    s.on('emergency-created', (data) {
      final map = Map<String, dynamic>.from(data);
      print('Emergency created: $map');

      // join the specific emergency room
      s.emit('join-room', {
        'roomId': map['emergencyId'],
        'userType': 'user',
        'userId': currentUserId,
      });
    });

    // A responder accepted the emergency
    s.on('responder-accepted', (data) {
      final map = Map<String, dynamic>.from(data);
      showResponderInfo(map);
    });

    // Live location updates from the responder
    s.on('responder-location-update', (data) {
      final map = Map<String, dynamic>.from(data);
      final responderId = map['responderId'] as String;
      final location = Map<String, dynamic>.from(map['location']);
      updateResponderMarker(responderId, location);
    });

    // ETA and distance updates
    s.on('eta-update', (data) {
      final map = Map<String, dynamic>.from(data);
      updateETAonUI(map['eta'], map['distance']);
    });

    // Overall status updates (e.g., “arrived”, “completed”)
    s.on('emergency-status-update', (data) {
      final map = Map<String, dynamic>.from(data);
      showStatusChange(map['status'] as String);
    });
  }

  /// Remove all listeners (optional but useful on logout)
  // void removeAllListeners() {
  //   final s = socketService.socket;
  //   s?.off(); // removes every listener
  // }
}
