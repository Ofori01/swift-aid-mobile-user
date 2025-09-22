import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../screens/auth/login_screen.dart';


class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "animation": "assets/lottie/onboarding1.json",
      "title": "Emergency Assistance",
      "desc": "Make Emergency Requests and get quick response",
    },
    {
      "animation": "assets/lottie/onboarding2.json",
      "title": "Live Location & ETA",
      "desc": "Track responders in real time and know when help will arrive.",
    },
    {
      "animation": "assets/lottie/ambulance.json",
      "title": "Ambulance Response",
      "desc": "Provide urgent medical support and save more lives during emergencies.",
    },
  ];

  void _nextPage() {
    if (_currentPage < onboardingData.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    // final themeProvider = Provider.of<ThemeProvider>(context);
    // final isDark = themeProvider.isDarkMode;

    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      //   actions: [
      //     Row(
      //       children: [
      //         Icon(isDark ? Icons.dark_mode : Icons.light_mode),
      //         Switch(
      //           value: isDark,
      //           onChanged: (val) => themeProvider.toggleTheme(val),
      //         ),
      //       ],
      //     ),
      //     const SizedBox(width: 10),
      //   ],
      // ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: onboardingData.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final item = onboardingData[index];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset(
                        item["animation"]!,
                        width: 250,
                        height: 250,
                        repeat: true,
                      ),
                      const SizedBox(height: 30),
                      Text(
                        item["title"]!,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Text(
                          item["desc"]!,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      )
                    ],
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(onboardingData.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 20),
                  width: _currentPage == index ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? Colors.red : Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: const Text("Skip"),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: FloatingActionButton(
                    onPressed: _nextPage,
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.arrow_forward),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

}
