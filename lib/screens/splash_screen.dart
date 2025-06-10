import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  bool _isLoggedIn = false;
  bool _isLoading = true;
  int _currentPage = 0;
  final PageController _pageController = PageController();

  final List<Map<String, String>> _features = [
    {
      'title': 'Track Everything',
      'subtitle': 'Easily log and categorize your daily expenses.',
      'emoji': '💰',
    },
    {
      'title': 'Plan Your Getaways',
      'subtitle': 'Create separate budgets for holidays and events.',
      'emoji': '🏖 ️',
    },
    {
      'title': 'See Insights Instantly',
      'subtitle': 'Visualize your spending with clean charts and quick stats.',
      'emoji': '📊',
    },
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();

    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      setState(() {
        _isLoggedIn = true;
      });

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.fetchUser(user.uid);

      // Fade out animation before navigation
      await _controller.reverse();

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildPage(Map<String, String> item) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(item['emoji'] ?? '', style: const TextStyle(fontSize: 60)),
        const SizedBox(height: 20),
        Text(
          item['title'] ?? '',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            item['subtitle'] ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_features.length, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 12 : 8,
          height: _currentPage == index ? 12 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index ? Color(0xFF305038) : Colors.grey[400],
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
            const Text(
              "DimeFlow",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Effortless Money Management!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 30),

            // Carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _features.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildPage(_features[index]);
                },
              ),
            ),

            _buildDots(),
            const SizedBox(height: 30),

            // Conditional loading or button
            if (_isLoading)
              const CircularProgressIndicator(color: Colors.black,)
            else
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF305038),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: const Text("Get Started", style: TextStyle(fontSize: 18, color: Color(0xFFFFD700),)),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}