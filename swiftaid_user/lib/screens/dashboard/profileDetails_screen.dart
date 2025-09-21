// // lib/screens/profile/profile_details_screen.dart
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class ProfileDetailsScreen extends StatefulWidget {
//   const ProfileDetailsScreen({super.key});

//   @override
//   State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
// }

// class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
//   String name = '';
//   String phone = '';
//   String email = '';
//   bool loading = false;

//   @override
//   void initState() {
//     loading = true;
//     super.initState();
//     loadUserInfo();
//   }

//   Future <void> loadUserInfo() async {
//     final prefs = await SharedPreferences.getInstance();
//     name = prefs.getString('userName') ?? '';
//     email = prefs.getString('userEmail') ?? '';
//     phone = prefs.getString('userPhone') ?? '';

//     setState(() {
//       loading = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (loading) {
//       return Scaffold(body: Center(child: CircularProgressIndicator(),),);
//     }
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Profile'),
//         backgroundColor: const Color(0xFFB71C1C),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           children: [
//             CircleAvatar(
//               radius: 60,
//               backgroundColor: Colors.red.shade200,
//               child: const Icon(Icons.person, size: 100, color: Colors.white),
//             ),
//             const SizedBox(height: 30),

//             _buildField("Full Name", name),
//             const SizedBox(height: 20),
//             _buildField("Phone Number", phone),
//             const SizedBox(height: 20),
//             _buildField("Email", email),
//             // const SizedBox(height: 20),
//             // _buildField("Date Of Birth", "DD / MM / YYYY", enabled: false),

//             const SizedBox(height: 30),
//             ElevatedButton(
//               onPressed: () {
//                 // Will enable this when update functionality is ready
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.red,
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10)),
//                 padding: const EdgeInsets.symmetric(vertical: 18),
//                 minimumSize: const Size.fromHeight(50),
//               ),
//               child: const Text('Update Profile'),
//             )
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildField(String label, String value, {bool enabled = false}) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
//         const SizedBox(height: 8),
//         TextFormField(
//           initialValue: value,
//           enabled: enabled,
//           decoration: const InputDecoration(
//             filled: true,
//             fillColor: Color(0xFFF0F0F0),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.all(Radius.circular(10)),
//               borderSide: BorderSide.none,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  String name = '';
  String phone = '';
  String email = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      name = prefs.getString('userName') ?? '';
      email = prefs.getString('userEmail') ?? '';
      phone = prefs.getString('userPhone') ?? '';
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // final isDark = Theme.of(context).brightness == Brightness.dark;

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        // backgroundColor: Colors.red,
        // backgroundColor: const Color(0xFFB71C1C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.red.shade200,
              child: const Icon(Icons.person, size: 100, color: Colors.white),
            ),
            const SizedBox(height: 30),

            _buildField(context, "Full Name", name),
            const SizedBox(height: 20),
            _buildField(context, "Phone Number", phone),
            const SizedBox(height: 20),
            _buildField(context, "Email", email),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // TODO: Add update functionality here
              },
              style: ElevatedButton.styleFrom(
                // backgroundColor: const Color(0xFFB71C1C),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 18),
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Update Profile'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildField(BuildContext context, String label, String value,
      {bool enabled = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? Colors.grey[800] : const Color(0xFFF0F0F0);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
            )),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value,
          enabled: enabled,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
