import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/theme.dart';
import 'main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  final _steps = [
    _Step(Icons.kitchen, 'Welcome to CookMyFridge', 'Turn whatever is in your fridge into delicious meals with AI-powered recipe suggestions.'),
    _Step(Icons.auto_awesome, 'AI-powered recipes', 'Just type your ingredients and our Chef Kinakap instantly suggests recipes tailored to exactly what you have.'),
    _Step(Icons.favorite_border, 'Save your favorites', 'Heart any recipe to save it forever. Build your own personal AI-curated cookbook over time.'),
    _Step(Icons.calendar_today, 'Plan your whole week', 'Use the meal planner to organize meals for the entire week and dramatically reduce food waste.'),
    _Step(Icons.chat_bubble_outline, 'Ask Chef Kinakap Kinakap', 'Got a cooking question? Chat with your personal Chef Kinakap anytime for tips, substitutions and techniques.'),
  ];

  void _next() async {
    if (_page < _steps.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('seen_onboarding', true);
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _next,
                child: Text('Skip', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _steps.length,
                itemBuilder: (_, i) => _StepPage(step: _steps[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_steps.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == _page ? kPrimary : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  child: Text(_page < _steps.length - 1 ? 'Next' : 'Start cooking!', style: const TextStyle(fontSize: 16)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StepPage extends StatelessWidget {
  final _Step step;
  const _StepPage({required this.step});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100, height: 100,
            decoration: const BoxDecoration(color: kPrimaryLight, shape: BoxShape.circle),
            child: Icon(step.icon, size: 48, color: kPrimary),
          ),
          const SizedBox(height: 32),
          Text(step.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Text(step.desc, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.6)),
        ],
      ),
    );
  }
}

class _Step {
  final IconData icon;
  final String title;
  final String desc;
  _Step(this.icon, this.title, this.desc);
}
