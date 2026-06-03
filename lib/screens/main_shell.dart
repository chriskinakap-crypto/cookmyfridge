import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/theme.dart';
import '../services/app_state.dart';
import 'fridge_screen.dart';
import 'saved_screen.dart';
import 'meal_plan_screen.dart';
import 'chat_screen.dart';
import 'shopping_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _screens = const [
    FridgeScreen(),
    MealPlanScreen(),
    ChatScreen(),
    SavedScreen(),
    ShoppingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        indicatorColor: kPrimaryLight,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.kitchen_outlined), selectedIcon: Icon(Icons.kitchen, color: kPrimary), label: 'Fridge'),
          const NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today, color: kPrimary), label: 'Plan'),
          const NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble, color: kPrimary), label: 'Chef'),
          NavigationDestination(
            icon: Badge(isLabelVisible: state.savedRecipes.isNotEmpty, label: Text('${state.savedRecipes.length}'), child: const Icon(Icons.favorite_border)),
            selectedIcon: const Icon(Icons.favorite, color: kPrimary),
            label: 'Saved',
          ),
          const NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), selectedIcon: Icon(Icons.shopping_cart, color: kPrimary), label: 'Shop'),
        ],
      ),
    );
  }
}
