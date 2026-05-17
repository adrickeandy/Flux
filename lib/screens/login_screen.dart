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
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl   = TextEditingController();
  bool _showPass = false;
  bool _loading  = false;
  String? _identifierError;
  String? _passwordError;

  bool get _isPhone => !_identifierCtrl.text.contains('@') && _identifierCtrl.text.isNotEmpty;

  Future<void> _login() async {
    setState(() { _identifierError = null; _passwordError = null; });

    final id = _identifierCtrl.text.trim();
    final pw = _passwordCtrl.text;

    if (id.isEmpty) { setState(() => _identifierError = 'Required'); return; }
    if (pw.isEmpty) { setState(() => _passwordError = 'Required'); return; }

    setState(() => _loading = true);
    try {
      await AuthService().login(id, pw);
      if (mounted) context.go('/home');
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('account_not_found')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account not found. Redirecting to sign up...'), behavior: SnackBarBehavior.floating));
        Future.delayed(const Duration(seconds: 1), () => context.go('/signup'));
      } else if (msg.contains('wrong-password') || msg.contains('invalid-credential')) {
        setState(() => _passwordError = 'Incorrect password');
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
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              // Logo
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF833AB4), Color(0xFFfd1d1d), Color(0xFFfcb045)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.4), blurRadius: 24)],
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 38),
              ),
              const SizedBox(height: 16),
              ShaderMask(
                shaderCallback: (b) => kGradient.createShader(b),
                child: const Text('FLUX',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900,
                        color: Colors.white, fontStyle: FontStyle.italic, letterSpacing: -1)),
              ),
              const SizedBox(height: 4),
              Text('WELCOME BACK',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900,
                      letterSpacing: 4, color: Colors.grey.shade500)),
              const SizedBox(height: 44),

              // Phone/Email field
              _label('PHONE OR EMAIL'),
              const SizedBox(height: 6),
              Stack(
                alignment: Alignment.centerLeft,
                children: [
                  TextField(
                    controller: _identifierCtrl,
                    autofocus: true,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      hintText: '07XXXXXXXX or email@example.com',
                      contentPadding: EdgeInsets.fromLTRB(_isPhone ? 90 : 16, 14, 16, 14),
                      errorText: _identifierError,
                    ),
                  ),
                  if (_isPhone)
                    Padding(
                      padding: const EdgeInsets.only(left: 14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🇺🇬', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text('+256', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Password field
              _label('PASSWORD'),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordCtrl,
                obscureText: !_showPass,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  errorText: _passwordError,
                  suffixIcon: IconButton(
                    icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility, size: 20, color: Colors.grey),
                    onPressed: () => setState(() => _showPass = !_showPass),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Login button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: kGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('LOG IN', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 12, color: Colors.white)),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Row(children: [
                Expanded(child: Divider(color: Colors.grey.shade200)),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 2))),
                Expanded(child: Divider(color: Colors.grey.shade200)),
              ]),
              const SizedBox(height: 24),

              TextButton(
                onPressed: () => context.go('/signup'),
                child: RichText(
                  text: TextSpan(
                    text: "Don't have an account? ",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    children: [
                      TextSpan(text: 'SIGN UP',
                          style: TextStyle(color: kPrimary, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Align(
    alignment: Alignment.centerLeft,
    child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900,
        color: kPrimary, letterSpacing: 2)),
  );
}