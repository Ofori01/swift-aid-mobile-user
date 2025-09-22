import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  
  // Singleton pattern so you can access the same instance everywhere
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;

  void connect({
    required String token,
    required String userId,
    required String baseUrl,
  }) {
    if (_socket?.connected == true) return; // avoid reconnect loops

    _socket = IO.io(
      baseUrl, 
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setAuth({'token': token}) 
          .build(),
    );

    _socket!.onAny((event, data) => print('📩 [$event] $data'));

    _socket!.onConnect((_) {
      print('✅ Socket connected');
      _socket!.emit('join-room', {
        'roomId': userId,
        'userType': 'user',
        'userId': userId,
      });
    });

    // _socket!.onConnect((_) => print('✅ Socket connected'));
    _socket!.onDisconnect((_) => print('❌ Socket disconnected'));
    _socket!.onConnectError((err) => print('🚨 Socket connect error: $err'));
    _socket!.onError((err) => print('⚠️ Socket error: $err'));

    _socket!.connect();
  }

  IO.Socket? get socket => _socket;

  void disconnect() {
    print('Socket disconnected after logout');
    _socket?.clearListeners();         // remove listeners
    _socket?.disconnect(); // stop the connection
    _socket?.close();      // fully close
    _socket = null;
  }

}



// import 'dart:async';
// import 'package:socket_io_client/socket_io_client.dart' as IO;

// class SocketService {
//   static final SocketService _instance = SocketService._internal();
//   factory SocketService() => _instance;
//   SocketService._internal();

//   IO.Socket? _socket;

//   IO.Socket? get socket => _socket;

//   /// Fire-and-forget connect (keeps autoConnect).
//   void connect({
//     required String token,
//     required String userId,
//     required String baseUrl,
//   }) {
//     if (_socket?.connected == true) return;

//     _socket = IO.io(
//       baseUrl,
//       IO.OptionBuilder()
//           .setTransports(['websocket', 'polling']) // allow fallback
//           .enableAutoConnect()
//           .setQuery({'token': token})
//           .setTimeout(10000) // ms
//           .build(),
//     );

//     _attachCommonListeners(userId);
//   }

//   /// Connect and wait for onConnect to fire (returns true if success).
//   /// Useful if you want to ensure socket is connected before navigating.
//   Future<bool> connectAndWait({
//     required String token,
//     required String userId,
//     required String baseUrl,
//     int timeoutMs = 5000,
//   }) async {
//     if (_socket?.connected == true) return true;

//     // Clean previous socket
//     _socket?.clearListeners();
//     _socket?.disconnect();
//     _socket = null;

//     final completer = Completer<bool>();

//     _socket = IO.io(
//       baseUrl,
//       IO.OptionBuilder()
//           .setTransports(['websocket', 'polling'])
//           .disableAutoConnect() // we'll call connect explicitly
//           .setQuery({'token': token})
//           .setTimeout(timeoutMs)
//           .build(),
//     );

//     // attach listeners that resolve the completer
//     _socket!.onConnect((_) {
//       print('✅ Socket connected (id=${_socket!.id})');
//       // join personal room
//       _socket!.emit('join-room', {
//         'roomId': userId,
//         'userType': 'user',
//         'userId': userId,
//       });
//       // attach normal listeners too
//       _attachCommonListeners(userId);
//       if (!completer.isCompleted) completer.complete(true);
//     });

//     _socket!.onConnectError((err) {
//       print('🚨 Socket connect error: $err');
//       if (!completer.isCompleted) completer.complete(false);
//     });

//     _socket!.onConnectTimeout((_) {
//       print('🚨 Socket connect timeout');
//       if (!completer.isCompleted) completer.complete(false);
//     });

//     _socket!.onError((err) {
//       print('⚠️ Socket error (during connect): $err');
//     });

//     // attempt connect
//     _socket!.connect();

//     // wait up to timeoutMs + 500ms guard
//     try {
//       final success = await completer.future.timeout(Duration(milliseconds: timeoutMs + 500),
//           onTimeout: () {
//         if (!completer.isCompleted) completer.complete(false);
//         return false;
//       });
//       return success;
//     } catch (_) {
//       return false;
//     }
//   }

//   void _attachCommonListeners(String userId) {
//     _socket!.onDisconnect((_) => print('❌ Socket disconnected'));
//     _socket!.onError((err) => print('⚠️ Socket error: $err'));
//     _socket!.onReconnect((attempt) => print('🔄 Socket reconnect attempt: $attempt'));
//     _socket!.onReconnectAttempt((attempt) => print('🔄 Socket reconnecting: $attempt'));
//     _socket!.onReconnectError((err) => print('🔄 Reconnect error: $err'));
//     _socket!.onConnectError((err) => print('🚨 Connect error: $err'));
//     // don't re-add onConnect here to avoid duplicates -- handled in connectAndWait / connect
//   }

//   void disconnect() {
//     _socket?.clearListeners();
//     _socket?.disconnect();
//     try {
//       _socket?.close();
//     } catch (_) {}
//     _socket = null;
//     print('SocketService: disconnected and cleaned up');
//   }
// }
