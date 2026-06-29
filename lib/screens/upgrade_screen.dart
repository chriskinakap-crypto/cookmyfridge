import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/theme.dart';
import '../services/paypal_service.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});
  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  bool _yearly = false;
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade to Pro', style: TextStyle(color: Colors.white)),
        backgroundColor: kPrimary,
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          // Hero banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimary, Color(0xFFFF9A6C)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            child: Column(children: [
              Container(width: 70, height: 70, decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle), child: const Icon(Icons.auto_awesome, size: 36, color: Colors.white)),
              const SizedBox(height: 14),
              const Text('CookMyFridge Pro', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 6),
              const Text('Unlock the full kitchen experience', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [

              // Plan toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  _planToggle('Monthly', !_yearly, () => setState(() => _yearly = false)),
                  _planToggle('Annual  (save 30%)', _yearly, () => setState(() => _yearly = true)),
                ]),
              ),
              const SizedBox(height: 8),

              // Price display
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _priceCard(key: ValueKey(_yearly)),
              ),
              const SizedBox(height: 20),

              // Feature list
              _featureList(),
              const SizedBox(height: 24),

              // PayPal button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _startPayPal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0070BA), // PayPal blue
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Text('Pay', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          RichText(text: const TextSpan(children: [
                            TextSpan(text: 'Pay', style: TextStyle(color: Color(0xFF009CDE), fontSize: 18, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic)),
                            TextSpan(text: 'Pal', style: TextStyle(color: Color(0xFF012169), fontSize: 18, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic)),
                          ])),
                        ]),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),
              ],

              const SizedBox(height: 12),

              // Test button for dev
              OutlinedButton(
                onPressed: _activateForTesting,
                child: const Text('Activate Pro (testing only)', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),

              const SizedBox(height: 16),
              Text('Cancel anytime. Secure payment via PayPal.', style: TextStyle(fontSize: 12, color: Colors.grey[400]), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('By subscribing you agree to our Terms of Service.', style: TextStyle(fontSize: 11, color: Colors.grey[300]), textAlign: TextAlign.center),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _planToggle(String label, bool active, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? kPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: active ? Colors.white : Colors.grey[600])),
      ),
    ),
  );

  Widget _priceCard({Key? key}) => Container(
    key: key,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: kPrimaryLight,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFF0997B)),
    ),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(
        _yearly ? '\$24.99' : '\$2.99',
        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: kPrimary),
      ),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_yearly ? '/year' : '/month', style: const TextStyle(fontSize: 14, color: kPrimaryDark)),
        if (_yearly) Container(
          margin: const EdgeInsets.only(top: 3),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(10)),
          child: Text('Save \$10.89/yr', style: TextStyle(fontSize: 11, color: Colors.green[700], fontWeight: FontWeight.w600)),
        ),
      ]),
    ]),
  );

  Widget _featureList() {
    final features = [
      (Icons.auto_awesome, 'Unlimited AI recipe suggestions', true),
      (Icons.bar_chart, 'Full nutrition tracking per recipe', true),
      (Icons.people, 'Community recipe sharing', true),
      (Icons.no_meals, 'Completely ad-free experience', true),
      (Icons.sync, 'Sync across all your devices', true),
      (Icons.history, 'Full unlimited search history', true),
      (Icons.support_agent, 'Priority Chef Kinakap responses', true),
      (Icons.calendar_today, 'Advanced meal planning tools', true),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
      child: Column(
        children: features.map((f) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(children: [
            Container(width: 28, height: 28, decoration: BoxDecoration(color: f.$3 ? Colors.green[50] : Colors.grey[100], shape: BoxShape.circle), child: Icon(f.$3 ? Icons.check : Icons.close, size: 16, color: f.$3 ? Colors.green : Colors.grey)),
            const SizedBox(width: 12),
            Expanded(child: Text(f.$1.toString() == f.$1.toString() ? f.$2 : f.$2, style: TextStyle(fontSize: 13, color: f.$3 ? Colors.black87 : Colors.grey[400]))),
            Icon(f.$1, size: 18, color: kPrimary),
          ]),
        )).toList(),
      ),
    );
  }

  Future<void> _startPayPal() async {
    if (!AuthService.isLoggedIn) {
      setState(() => _error = 'Please sign in before upgrading.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    await FirebaseService.logUpgradeView();

    try {
      final approvalUrl = await PayPalService.createSubscription(yearly: _yearly);
      if (approvalUrl != null) {
        final launched = await PayPalService.launchPayPal(approvalUrl);
        if (!launched && mounted) setState(() => _error = 'Could not open PayPal. Try again.');
        // Note: After PayPal redirects back, your backend webhook should call
        // PayPalService.activatePro() — see README_PHASE3.md for webhook setup
      } else {
        setState(() => _error = 'Could not connect to PayPal. Check credentials.');
      }
    } catch (e) {
      setState(() => _error = 'Payment error: $e');
    }

    setState(() => _loading = false);
  }

  // For testing without real PayPal credentials
  Future<void> _activateForTesting() async {
    setState(() => _loading = true);
    await PayPalService.activatePro(yearly: _yearly);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pro activated! (test mode)'), backgroundColor: Colors.green));
      Navigator.pop(context);
    }
    setState(() => _loading = false);
  }
}
