import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idCtrl  = TextEditingController();
  final _pwCtrl  = TextEditingController();
  bool _showPass = false;
  bool _loading  = false;
  String? _idErr;
  String? _pwErr;

  bool get _isPhone =>
      !_idCtrl.text.contains('@') && _idCtrl.text.isNotEmpty;

  Future<void> _login() async {
    setState(() { _idErr = null; _pwErr = null; });
    final id = _idCtrl.text.trim();
    final pw = _pwCtrl.text;
    if (id.isEmpty) { setState(() => _idErr = 'Required'); return; }
    if (pw.isEmpty) { setState(() => _pwErr = 'Required'); return; }
    setState(() => _loading = true);
    try {
      await AuthService().login(id, pw);
      if (mounted) context.go('/home');
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('account_not_found')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account not found. Redirecting to sign up...'),
                behavior: SnackBarBehavior.floating));
          Future.delayed(const Duration(seconds: 1), () => context.go('/signup'));
        }
      } else if (msg.contains('wrong-password') || msg.contains('invalid-credential')) {
        setState(() => _pwErr = 'Incorrect password');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 64, 32, 48),
          child: Column(
            children: [
              // Logo
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: kGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: kPrimary.withAlpha(102), blurRadius: 24)],
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              ShaderMask(
                shaderCallback: (b) => kGradient.createShader(b),
                child: const Text('FLUX',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900,
                        color: Colors.white, fontStyle: FontStyle.italic, letterSpacing: -1)),
              ),
              const SizedBox(height: 4),
              Text('Welcome back',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                      color: Colors.grey.shade500, letterSpacing: 2)),
              const SizedBox(height: 48),

              // Phone/Email field
              Align(alignment: Alignment.centerLeft,
                child: Text('PHONE OR EMAIL',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900,
                        color: kPrimary, letterSpacing: 2))),
              const SizedBox(height: 6),
              Stack(alignment: Alignment.centerLeft, children: [
                TextField(
                  controller: _idCtrl,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText: '07XXXXXXXX or email',
                    contentPadding: EdgeInsets.fromLTRB(_isPhone ? 88 : 16, 14, 16, 14),
                    errorText: _idErr,
                  ),
                ),
                if (_isPhone)
                  Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Text('🇺🇬', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text('+256', style: TextStyle(fontWeight: FontWeight.w700,
                          color: Colors.grey.shade600, fontSize: 13)),
                    ]),
                  ),
              ]),
              const SizedBox(height: 20),

              // Password
              Align(alignment: Alignment.centerLeft,
                child: Text('PASSWORD',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900,
                        color: kPrimary, letterSpacing: 2))),
              const SizedBox(height: 6),
              TextField(
                controller: _pwCtrl,
                obscureText: !_showPass,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  errorText: _pwErr,
                  suffixIcon: IconButton(
                    icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility,
                        size: 20, color: Colors.grey),
                    onPressed: () => setState(() => _showPass = !_showPass),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Login button
              GestureDetector(
                onTap: _loading ? null : _login,
                child: Container(
                  width: double.infinity, height: 56,
                  decoration: BoxDecoration(
                    color: kPrimary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: kPrimary.withAlpha(102),
                        blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  alignment: Alignment.center,
                  child: _loading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Log In',
                          style: TextStyle(fontWeight: FontWeight.w900,
                              fontSize: 13, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 24),

              // Divider
              Row(children: [
                Expanded(child: Divider(color: Colors.grey.shade200)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Or', style: TextStyle(fontSize: 9,
                      fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 2)),
                ),
                Expanded(child: Divider(color: Colors.grey.shade200)),
              ]),
              const SizedBox(height: 24),

              // Sign up link
              GestureDetector(
                onTap: () => context.go('/signup'),
                child: RichText(text: TextSpan(
                  text: "Don't have an account? ",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  children: [
                    TextSpan(text: 'SIGN UP',
                        style: TextStyle(color: kPrimary, fontWeight: FontWeight.w900,
                            letterSpacing: 2)),
                  ],
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}