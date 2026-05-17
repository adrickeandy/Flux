import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showPass = false;
  bool _showConfirm = false;
  bool _loading = false;
  Map<String, String> _errors = {};

  bool _validate() {
    final e = <String, String>{};
    if (_nameCtrl.text.trim().isEmpty) e['name'] = 'Full name is required';
    if (!_phoneCtrl.text.startsWith('07') || _phoneCtrl.text.length != 10)
      e['phone'] = 'Enter a valid Uganda number starting with 07';
    if (!_emailCtrl.text.contains('@')) e['email'] = 'Enter a valid email';
    if (_passCtrl.text.length < 8) e['password'] = 'Password must be at least 8 characters';
    if (_passCtrl.text != _confirmCtrl.text) e['confirm'] = 'Passwords do not match';
    setState(() => _errors = e);
    return e.isEmpty;
  }

  Future<void> _signUp() async {
    if (!_validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService().signUp(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (mounted) context.go('/profile/setup');
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('phone_taken'))
        setState(() => _errors = {'phone': 'This number is already registered'});
      else if (msg.contains('email_taken'))
        setState(() => _errors = {'email': 'This email is already registered'});
      else
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
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
              Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded),
                  onPressed: () => context.go('/login'),
                ),
                const SizedBox(width: 8),
                ShaderMask(
                  shaderCallback: (b) => kGradient.createShader(b),
                  child: const Text('CREATE ACCOUNT',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                        color: Colors.white, letterSpacing: 1)),
                ),
              ]),
              const SizedBox(height: 28),
              _field('FULL NAME', _nameCtrl, 'Your name', _errors['name']),
              const SizedBox(height: 16),
              _phoneField(),
              const SizedBox(height: 16),
              _field('EMAIL', _emailCtrl, 'email@example.com', _errors['email'],
                  type: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _passField('PASSWORD', _passCtrl, _showPass,
                  () => setState(() => _showPass = !_showPass), _errors['password']),
              const SizedBox(height: 16),
              _passField('CONFIRM PASSWORD', _confirmCtrl, _showConfirm,
                  () => setState(() => _showConfirm = !_showConfirm), _errors['confirm']),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _loading ? null : _signUp,
                child: Container(
                  width: double.infinity, height: 54,
                  decoration: BoxDecoration(
                    gradient: kGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.4),
                        blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  alignment: Alignment.center,
                  child: _loading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('CREATE ACCOUNT',
                          style: TextStyle(fontWeight: FontWeight.w900,
                              letterSpacing: 2, fontSize: 11, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => context.go('/login'),
                child: RichText(text: TextSpan(
                  text: 'Already have an account? ',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  children: [
                    TextSpan(text: 'LOG IN',
                      style: TextStyle(color: kPrimary, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  ],
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint,
      String? error, {TextInputType type = TextInputType.text}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900,
          color: kPrimary, letterSpacing: 2)),
      const SizedBox(height: 6),
      TextField(controller: ctrl, keyboardType: type,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        decoration: InputDecoration(hintText: hint, errorText: error)),
    ]);

  Widget _phoneField() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('PHONE NUMBER', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900,
        color: kPrimary, letterSpacing: 2)),
    const SizedBox(height: 6),
    Stack(alignment: Alignment.centerLeft, children: [
      TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          hintText: '07XXXXXXXX',
          contentPadding: const EdgeInsets.fromLTRB(88, 14, 16, 14),
          errorText: _errors['phone'],
        )),
      Padding(padding: const EdgeInsets.only(left: 14),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('🇺🇬', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text('+256', style: TextStyle(fontWeight: FontWeight.w700,
              color: Colors.grey.shade600, fontSize: 13)),
        ])),
    ]),
  ]);

  Widget _passField(String label, TextEditingController ctrl,
      bool show, VoidCallback toggle, String? error) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900,
          color: kPrimary, letterSpacing: 2)),
      const SizedBox(height: 6),
      TextField(controller: ctrl, obscureText: !show,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          hintText: 'Enter password', errorText: error,
          suffixIcon: IconButton(
            icon: Icon(show ? Icons.visibility_off : Icons.visibility,
                size: 20, color: Colors.grey),
            onPressed: toggle,
          ),
        )),
    ]);
}