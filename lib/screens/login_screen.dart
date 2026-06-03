import 'package:flutter/material.dart';
import '../models/theme.dart';
import '../services/auth_service.dart';
import 'main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const SizedBox(height: 32),
              // Logo
              Container(
                width: 80, height: 80,
                decoration: const BoxDecoration(color: kPrimaryLight, shape: BoxShape.circle),
                child: const Icon(Icons.kitchen, size: 44, color: kPrimary),
              ),
              const SizedBox(height: 16),
              const Text('CookMyFridge', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: kPrimary)),
              const Text('Turn leftovers into delicious meals', style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 36),

              // Social login buttons
              _socialBtn(
                icon: 'G',
                label: 'Continue with Google',
                color: Colors.white,
                textColor: Colors.black87,
                borderColor: Colors.grey[300]!,
                onTap: () => _signIn(() => AuthService.signInWithGoogle()),
              ),
              const SizedBox(height: 10),
              _socialBtn(
                icon: '',
                label: 'Continue with Apple',
                color: Colors.black,
                textColor: Colors.white,
                icon2: const Icon(Icons.apple, color: Colors.white, size: 20),
                onTap: () => _signIn(() => AuthService.signInWithApple()),
              ),
              const SizedBox(height: 20),

              Row(children: [
                Expanded(child: Divider(color: Colors.grey[300])),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('or use email', style: TextStyle(color: Colors.grey[400], fontSize: 13))),
                Expanded(child: Divider(color: Colors.grey[300])),
              ]),
              const SizedBox(height: 16),

              // Email tabs
              Container(
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                child: TabBar(
                  controller: _tabs,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  indicator: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(8)),
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: const [Tab(text: 'Sign in'), Tab(text: 'Create account')],
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                height: 260,
                child: TabBarView(controller: _tabs, children: [
                  _signInForm(),
                  _signUpForm(),
                ]),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red[200]!)),
                  child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),
              ],

              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainShell())),
                child: const Text('Continue without account', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _signInForm() => Column(children: [
    TextField(controller: _emailCtrl, decoration: const InputDecoration(hintText: 'Email address', prefixIcon: Icon(Icons.email_outlined)), keyboardType: TextInputType.emailAddress),
    const SizedBox(height: 10),
    TextField(
      controller: _passCtrl, obscureText: _obscure,
      decoration: InputDecoration(
        hintText: 'Password',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscure = !_obscure)),
      ),
    ),
    Align(alignment: Alignment.centerRight, child: TextButton(
      onPressed: () => _resetPassword(),
      child: const Text('Forgot password?', style: TextStyle(fontSize: 12)),
    )),
    const SizedBox(height: 4),
    SizedBox(width: double.infinity, child: ElevatedButton(
      onPressed: _loading ? null : () => _signIn(() => AuthService.signInWithEmail(_emailCtrl.text.trim(), _passCtrl.text)),
      child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Sign in'),
    )),
  ]);

  Widget _signUpForm() => Column(children: [
    TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'Your name', prefixIcon: Icon(Icons.person_outline))),
    const SizedBox(height: 10),
    TextField(controller: _emailCtrl, decoration: const InputDecoration(hintText: 'Email address', prefixIcon: Icon(Icons.email_outlined)), keyboardType: TextInputType.emailAddress),
    const SizedBox(height: 10),
    TextField(controller: _passCtrl, obscureText: _obscure, decoration: InputDecoration(hintText: 'Password (min 6 chars)', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscure = !_obscure)))),
    const SizedBox(height: 14),
    SizedBox(width: double.infinity, child: ElevatedButton(
      onPressed: _loading ? null : () => _signIn(() => AuthService.signUpWithEmail(_emailCtrl.text.trim(), _passCtrl.text, _nameCtrl.text.trim())),
      child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Create account'),
    )),
  ]);

  Widget _socialBtn({required String icon, required String label, required Color color, required Color textColor, Color? borderColor, Widget? icon2, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity, height: 48,
      child: OutlinedButton(
        onPressed: _loading ? null : onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: color,
          side: BorderSide(color: borderColor ?? color),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          icon2 ?? Text(icon, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor)),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 15, color: textColor, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Future<void> _signIn(Future<dynamic> Function() method) async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await method();
      if (result != null && mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainShell()));
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _resetPassword() async {
    if (_emailCtrl.text.isEmpty) {
      setState(() => _error = 'Enter your email first.');
      return;
    }
    await AuthService.resetPassword(_emailCtrl.text.trim());
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reset email sent!'), backgroundColor: kPrimary));
  }
}
