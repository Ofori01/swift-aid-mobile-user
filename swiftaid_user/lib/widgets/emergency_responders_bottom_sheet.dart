import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/utils/utils.dart';

class EmergencyRespondersBottomSheet extends StatefulWidget {
  final Map<String, dynamic> responders;
  final Map<String, dynamic> emergencyDetails;
  final ScrollController scrollController;

  const EmergencyRespondersBottomSheet({
    super.key,
    required this.responders,
    required this.emergencyDetails,
    required this.scrollController,
  });

  @override
  State<EmergencyRespondersBottomSheet> createState() =>
      _EmergencyRespondersBottomSheetState();
}

class _EmergencyRespondersBottomSheetState extends State<EmergencyRespondersBottomSheet> {
  String? selectedCategory;

  @override
  Widget build(BuildContext context) {
    return SafeArea( 
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              color: Theme.of(context).shadowColor.withOpacity(0.1),
            ),
          ],
        ),
        child: selectedCategory == null
            ? buildMainView()
            : buildCategoryDetailsView(),
      ),
    );
  }

  Widget buildMainView() {
    final categories = widget.responders.keys.toList();

    return FutureBuilder<String>(
      future: () {
        final loc = widget.emergencyDetails['emergency_location'];
        if (loc is String) {
          try {
            final coords = jsonDecode(loc) as List;
    
            if (coords.length == 2) {
              final lng = coords[0] as double;
              final lat = coords[1] as double;

              return getAddressFromCoordinates(lat, lng);
            }
          } catch (e) {
            debugPrint('Error parsing location: $e');
          }
        }
        return Future.value(loc?.toString() ?? 'Unknown location');
      }(),

      builder: (context, snapshot) {
        final address = snapshot.data ?? 'Resolving address...';

        return SingleChildScrollView(
          controller: widget.scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: Icon(Icons.horizontal_rule, size: 30)),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.center, // Center horizontally
                children: [
                  Icon(  // Emergency icon
                    Icons.emergency,
                    color: Colors.red,
                    size: 24,
                  ),
                  SizedBox(width: 8), // Spacing between icon and text
                  Text(
                    "HELP IS ON THE WAY!!!",  
                    style: GoogleFonts.poppins(
                      fontSize: 18,  // Larger font
                      fontWeight: FontWeight.bold,  
                      color: Colors.red,  
                      letterSpacing: 0.5,  
                    ),
                  ),
                  SizedBox(width: 8), 
                  Icon(  
                    Icons.warning_amber_rounded,
                    color: Colors.amber,
                    size: 24,
                  ),
                ],
              ),

              const Divider(height: 40),
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.red.withOpacity(0.3),
                    child: Icon(
                      getEmergencyTypeIcon(widget.emergencyDetails['emergency_type'] ?? ''),
                      color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.emergencyDetails['emergency_type'] ?? 'Emergency',
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w600
                            ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.emergencyDetails['emergency_description'] ?? '',
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 40),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      address,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withOpacity(0.6)),
                    ),
                  ),
                ],
              ),
              const Divider(height: 40),
              const SizedBox(height: 8),

              // Category list as before...
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final icon = getCategoryIcon(cat);
                  return GestureDetector(
                    onTap: () => setState(() => selectedCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(icon, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            cat[0].toUpperCase() + cat.substring(1),
                            style: GoogleFonts.poppins(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }


  Widget buildCategoryDetailsView() {
    final responders = widget.responders[selectedCategory] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => selectedCategory = null),
            ),
            Text(
              selectedCategory![0].toUpperCase() + selectedCategory!.substring(1),
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => selectedCategory = null),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.bottomCenter,
          child: Lottie.asset(getCategoryLottie(selectedCategory!), width: 190),
        ),
        const SizedBox(height: 8),

        // ✅ Constrain the ListView using Expanded
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            itemCount: responders.length,
            itemBuilder: (context, index) {
              final responder = responders[index];
              final name = responder['name'] ?? 'Unknown';
              final travelTime = responder['travelTime'] ?? 0;
              final etaMinutes = (travelTime / 60).ceil();

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                leading: const Icon(Icons.directions_run),
                title: Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                subtitle: Text("ETA: $etaMinutes min", style: GoogleFonts.poppins(fontSize: 13)),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData getCategoryIcon(String category) {
    switch (category) {
      case 'ambulances':
        return Icons.local_hospital;
      case 'fire_trucks':
        return Icons.local_fire_department;
      case 'police':
        return Icons.local_police;
      default:
        return Icons.car_rental;
    }
  }

  String getCategoryLottie(String category) {
    switch (category) {
      case 'ambulances':
        return 'assets/lottie/ambulance.json';
      case 'fire_trucks':
        return 'assets/lottie/policecar.json';
      case 'police':
        return 'assets/lottie/policecar.json';
      default:
        return 'assets/lottie/policecar.json';
    }
  }
}
