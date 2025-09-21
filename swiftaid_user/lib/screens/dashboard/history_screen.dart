// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class EmergencyHistoryScreen extends StatefulWidget {
//   const EmergencyHistoryScreen({Key? key}) : super(key: key);

//   @override
//   State<EmergencyHistoryScreen> createState() => _EmergencyHistoryScreenState();
// }

// class _EmergencyHistoryScreenState extends State<EmergencyHistoryScreen> {
//   late Future<Map<String, List<dynamic>>> _groupedHistory;

//   @override
//   void initState() {
//     super.initState();
//     _groupedHistory = _fetchAndGroup();
//   }

//   Future<Map<String, List<dynamic>>> _fetchAndGroup() async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('token'); // adjust if key differs

//     final res = await http.get(
//       Uri.parse('https://swift-aid-backend.onrender.com/user/emergency'),
//       headers: {'Authorization': 'Bearer $token'},
//     );

//     if (res.statusCode != 200) {
//       throw Exception('Failed to load history: ${res.statusCode}');
//     }

//     final List data = json.decode(res.body);

//     final now = DateTime.now();
//     final Map<String, List<dynamic>> grouped = {};

//     for (var item in data) {
//       final created = DateTime.parse(item['createdAt']);
//       final diff = now.difference(created).inDays;
//       final key = diff == 0
//           ? 'Today'
//           : diff == 1
//               ? 'Yesterday'
//               : DateFormat('d MMM yyyy').format(created);

//       grouped.putIfAbsent(key, () => []).add(item);
//     }

//     // Sort so most recent groups come first
//     final ordered = Map.fromEntries(
//       grouped.entries.toList()
//         ..sort((a, b) {
//           DateTime latest(List<dynamic> list) => list
//               .map((e) => DateTime.parse(e['createdAt']))
//               .reduce((d1, d2) => d1.isAfter(d2) ? d1 : d2);
//           return latest(b.value).compareTo(latest(a.value));
//         }),
//     );

//     return ordered;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Emergency History'),
//         backgroundColor: const Color(0xFFB71C1C),
//       ),
//       body: FutureBuilder<Map<String, List<dynamic>>>(
//         future: _groupedHistory,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (snapshot.hasError) {
//             return Center(
//               child: Text('Error: ${snapshot.error}',
//                   style: TextStyle(color: isDark ? Colors.white : Colors.black)),
//             );
//           }

//           final grouped = snapshot.data!;
//           return ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: grouped.keys.length,
//             itemBuilder: (context, i) {
//               final dateLabel = grouped.keys.elementAt(i);
//               final items = grouped[dateLabel]!;

//               return Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     dateLabel,
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: isDark ? Colors.white : Colors.black87,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   ...items.map((e) => _buildEmergencyCard(context, e)),
//                   const SizedBox(height: 24),
//                 ],
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildEmergencyCard(BuildContext context, Map<String, dynamic> e) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final type = (e['emergency_type'] ?? 'Unknown').toString();
//     final desc = e['user_description'] ?? '';
//     final created = DateTime.parse(e['createdAt']);
//     final time = DateFormat('HH:mm').format(created);

//     IconData icon;
//     switch (type.toLowerCase()) {
//       case 'fire':
//         icon = Icons.local_fire_department;
//         break;
//       case 'police':
//         icon = Icons.local_police;
//         break;
//       case 'medical':
//       case 'ambulance':
//         icon = Icons.local_hospital;
//         break;
//       default:
//         icon = Icons.warning;
//     }

//     return Card(
//       elevation: 2,
//       margin: const EdgeInsets.symmetric(vertical: 6),
//       color: isDark ? Colors.grey[850] : Colors.white,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: ListTile(
//         leading: CircleAvatar(
//           backgroundColor: const Color(0xFFB71C1C).withOpacity(0.1),
//           child: Icon(icon, color: const Color(0xFFB71C1C)),
//         ),
//         title: Text(
//           type,
//           style: TextStyle(
//             fontWeight: FontWeight.w600,
//             color: isDark ? Colors.white : Colors.black87,
//           ),
//         ),
//         subtitle: Text(
//           desc,
//           maxLines: 2,
//           overflow: TextOverflow.ellipsis,
//           style: TextStyle(color: isDark ? Colors.grey[300] : Colors.black54),
//         ),
//         trailing: Text(
//           time,
//           style: TextStyle(
//             color: isDark ? Colors.grey[400] : Colors.black54,
//             fontSize: 12,
//           ),
//         ),
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EmergencyHistoryScreen extends StatelessWidget {
  const EmergencyHistoryScreen({Key? key}) : super(key: key);

  Map<String, List<Map<String, dynamic>>> get _dummyGroupedHistory {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final earlier = now.subtract(const Duration(days: 5));

    return {
      'Today': [
        {
          'emergency_type': 'Fire',
          'user_description': 'Small kitchen fire at home',
          'createdAt': now.subtract(const Duration(hours: 1)).toIso8601String(),
        },
        {
          'emergency_type': 'Police',
          'user_description': 'Suspicious activity near the shop',
          'createdAt': now.subtract(const Duration(hours: 3)).toIso8601String(),
        },
      ],
      'Yesterday': [
        {
          'emergency_type': 'Medical',
          'user_description': 'Severe allergic reaction',
          'createdAt': yesterday.subtract(const Duration(hours: 4)).toIso8601String(),
        },
      ],
      DateFormat('d MMM yyyy').format(earlier): [
        {
          'emergency_type': 'Ambulance',
          'user_description': 'Minor road accident on Highway 5',
          'createdAt': earlier.subtract(const Duration(hours: 2)).toIso8601String(),
        },
        {
          'emergency_type': 'Fire',
          'user_description': 'Bush fire behind warehouse',
          'createdAt': earlier.subtract(const Duration(hours: 5)).toIso8601String(),
        },
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _dummyGroupedHistory;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency History'),
        backgroundColor: const Color(0xFFB71C1C), 
        // backgroundColor: Colors.red,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: grouped.keys.length,
        itemBuilder: (context, i) {
          final dateLabel = grouped.keys.elementAt(i);
          final items = grouped[dateLabel]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateLabel,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              ...items.map((e) => _buildEmergencyCard(context, e)).toList(),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmergencyCard(BuildContext context, Map<String, dynamic> e) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final type = e['emergency_type'];
    final desc = e['user_description'];
    final created = DateTime.parse(e['createdAt']);
    final time = DateFormat('HH:mm').format(created);

    IconData icon;
    switch (type.toLowerCase()) {
      case 'fire':
        icon = Icons.local_fire_department;
        break;
      case 'police':
        icon = Icons.local_police;
        break;
      case 'medical':
      case 'ambulance':
        icon = Icons.local_hospital;
        break;
      default:
        icon = Icons.warning;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFB71C1C).withOpacity(0.1),
          // backgroundColor: Colors.red.withOpacity(0.1),
          child: Icon(icon, color: const Color(0xFFB71C1C)),
        ),
        title: Text(type, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Text(
          time,
          style: TextStyle(
            color: isDark ? Colors.grey[300] : Colors.black54,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

