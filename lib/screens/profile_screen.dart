import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/theme.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsOn = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final data = await AuthService.getUserData();
    if (mounted) setState(() => _userData = data);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = AuthService.currentUser;
    final wasteKg = (state.totalIngredientsUsed * 0.12).toStringAsFixed(1);
    final initials = user?.displayName?.isNotEmpty == true
        ? user!.displayName!.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : (user?.email?.substring(0, 2).toUpperCase() ?? 'JD');

    return Scaffold(
      appBar: AppBar(title: const Text('My profile', style: TextStyle(color: Colors.white))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Avatar & name
        Center(child: Column(children: [
          user?.photoURL != null
              ? CircleAvatar(radius: 40, backgroundImage: NetworkImage(user!.photoURL!))
              : Container(
                  width: 80, height: 80,
                  decoration: const BoxDecoration(color: kPrimaryLight, shape: BoxShape.circle),
                  child: Center(child: Text(initials, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: kPrimary))),
                ),
          const SizedBox(height: 10),
          Text(user?.displayName ?? 'Welcome!', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          Text(user?.email ?? 'Not signed in', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF0997B))),
            child: Text(_userData?['plan'] == 'pro' ? '⭐ Pro plan' : 'Free plan', style: const TextStyle(fontSize: 12, color: kPrimaryDark, fontWeight: FontWeight.w500)),
          ),
        ])),
        const SizedBox(height: 24),

        // Stats
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.5, crossAxisSpacing: 10, mainAxisSpacing: 10,
          children: [
            _statCard('${_userData?['totalSearches'] ?? 0}', 'Searches'),
            _statCard('${state.savedRecipes.length}', 'Saved recipes'),
            _statCard('${state.totalIngredientsUsed}', 'Ingredients used'),
            _statCard('${wasteKg}kg', 'Waste saved 🌱'),
          ],
        ),
        const SizedBox(height: 20),

        // Pro upgrade
        if (_userData?['plan'] != 'pro') ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [kPrimary, Color(0xFFFF9A6C)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Upgrade to Pro', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('Unlimited AI recipes, nutrition tracking,\ncommunity sharing & more', style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
              ])),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: kPrimary),
                child: const Text('\$2.99/mo', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
          const SizedBox(height: 20),
        ],

        // Settings
        _sectionTitle('Settings'),
        _settingsTile(),
        const SizedBox(height: 16),

        // Account
        _sectionTitle('Account'),
        if (user != null) ...[
          _tile('Name', user.displayName ?? 'Not set'),
          _tile('Email', user.email ?? ''),
          _tile('Member since', _userData?['createdAt'] != null ? 'Joined recently' : '—'),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Sign out', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 12)),
          )),
        ] else ...[
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
            icon: const Icon(Icons.login),
            label: const Text('Sign in to sync your data'),
          )),
        ],
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _settingsTile() => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
    child: Column(children: [
      ListTile(
        title: const Text('Daily meal reminders', style: TextStyle(fontSize: 14)),
        subtitle: const Text('Get notified to plan your meals', style: TextStyle(fontSize: 12)),
        trailing: Switch(
          value: _notificationsOn, activeColor: kPrimary,
          onChanged: (v) async {
            setState(() => _notificationsOn = v);
            if (v) await FirebaseService.scheduleMealReminder(hour: 17, minute: 0);
            else await FirebaseService.cancelReminders();
            await AuthService.updateUserData({'notificationsEnabled': v});
          },
        ),
      ),
    ]),
  );

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey, letterSpacing: .5)),
  );

  Widget _statCard(String val, String label) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    ]),
  );

  Widget _tile(String label, String val) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    margin: const EdgeInsets.only(bottom: 1),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(0), border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 14)),
      Text(val, style: const TextStyle(fontSize: 14, color: Colors.grey)),
    ]),
  );

  Future<void> _signOut() async {
    await AuthService.signOut();
    if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }
}
