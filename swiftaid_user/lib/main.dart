import 'package:flutter/material.dart';
import '../screens/startupRedirectScreen.dart';
import 'package:provider/provider.dart';
import 'core/theme_provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';


// late IO.Socket socket;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  String accessToken = const String.fromEnvironment("ACCESS_TOKEN");
  MapboxOptions.setAccessToken(accessToken);

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
