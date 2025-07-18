import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import '../widgets/onboarding_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController controller = PageController();
  int currentPage = 0;

  final pages = [
    OnboardingPage(
      image: 'assets/onboarding1.png',
      title: '✅ Boost Productivity',
      subtitle: 'Break tasks into steps, track progress, and get more done with ease.',
    ),
    OnboardingPage(
      image: 'assets/onboarding2.png',
      title: '⏳ Never Miss a Deadline',
      subtitle: 'Set reminders and due dates to keep track of important tasks effortlessly.',
    ),
    OnboardingPage(
      image: 'assets/onboarding3.png',
      title: '📌 Stay Organized & Focused',
      subtitle: 'Easily create, manage, and prioritize your tasks to stay on top of your day.',
    ),
  ];

  void finishOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: controller,
        itemCount: pages.length,
        onPageChanged: (i) => setState(() => currentPage = i),
        itemBuilder: (_, i) => pages[i],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: finishOnboarding,
              child: const Text('Skip'),
            ),
            Row(
              children: List.generate(
                pages.length,
                    (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: currentPage == index ? Colors.orange : Colors.grey[300],
                  ),
                ),
              ),
            ),
            FloatingActionButton.small(
              backgroundColor: Colors.orange,
              onPressed: () {
                if (currentPage == pages.length - 1) {
                  finishOnboarding();
                } else {
                  controller.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: const Icon(Icons.arrow_forward),
            ),
          ],
        ),
      ),
    );
  }
}
