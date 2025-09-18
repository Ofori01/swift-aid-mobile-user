import 'package:flutter/material.dart';
import '../screens/startupRedirectScreen.dart';
import 'package:provider/provider.dart';
import 'core/theme_provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';


late IO.Socket socket;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  String accessToken = const String.fromEnvironment("ACCESS_TOKEN");
  MapboxOptions.setAccessToken(accessToken);

  // socket = IO.io(
  //   'https://swift-aid-backend.onrender.com',  // Change this if needed
  //   IO.OptionBuilder()
  //     .setTransports(['websocket']) // Only websocket
  //     .disableAutoConnect()
  //     .build(),
  // );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const SwiftAidApp(),
    ),
  );
}

class SwiftAidApp extends StatelessWidget {
  const SwiftAidApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Connect socket here AFTER app is running
    Future.delayed(Duration.zero, () {
      if (!socket.connected) {
        socket.connect();
        socket.onConnect((_) {
          print('✅ Socket Connected');
          socket.emit('msg', 'test');
        });
        socket.onConnectError((data) => print('❌ Connect Error: $data'));
        socket.onError((data) => print('❌ Socket Error: $data'));
        socket.onDisconnect((_) => print('⚠️ Disconnected'));
      }
    });

    return MaterialApp(
      title: 'SwiftAid User',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(bodyLarge: TextStyle(color: Colors.black)),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(bodyLarge: TextStyle(color: Colors.white)),
      ),
      home: const StartupRedirectScreen(),
    );
  }
}
