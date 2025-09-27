import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;

  void connect({
    required String token,
    required String userId,
    required String baseUrl,
  }) {
    if (_socket?.connected == true) return; 

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
    _socket?.clearListeners();        
    _socket?.disconnect(); 
    _socket?.close();     
    _socket = null;
  }
}