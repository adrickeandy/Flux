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
  bool _showPass = false, _showConfirm = false, _loading = false;
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
          padding: const EdgeInsets.fromLTRB(32, 48, 32, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Column(children: [
                const Text('Create Account',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Join the FLUX community',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500,
                        fontWeight: FontWeight.w900, letterSpacing: 2)),
              ])),
              const SizedBox(height: 32),

              _label('FULL NAME'),
              const SizedBox(height: 6),
              TextField(controller: _nameCtrl, autofocus: true,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                decoration: InputDecoration(hintText: 'John Doe', errorText: _errors['name'])),
              const SizedBox(height: 16),

              _label('PHONE NUMBER'),
              const SizedBox(height: 6),
              Stack(alignment: Alignment.centerLeft, children: [
                TextField(
                  controller: _phoneCtrl, keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText: '07XXXXXXXX',
                    contentPadding: const EdgeInsets.fromLTRB(88, 14, 16, 14),
                    errorText: _errors['phone'],
                  ),
                ),
                Padding(padding: const EdgeInsets.only(left: 14),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('🇺🇬', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text('+256', style: TextStyle(fontWeight: FontWeight.w700,
                        color: Colors.grey.shade600, fontSize: 13)),
                  ])),
              ]),
              const SizedBox(height: 16),

              _label('EMAIL ADDRESS'),
              const SizedBox(height: 6),
              TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                decoration: InputDecoration(hintText: 'email@example.com', errorText: _errors['email'])),
              const SizedBox(height: 16),

              _label('PASSWORD'),
              const SizedBox(height: 6),
              TextField(controller: _passCtrl, obscureText: !_showPass,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: 'Min 8 characters', errorText: _errors['password'],
                  suffixIcon: IconButton(
                    icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility,
                        size: 20, color: Colors.grey),
                    onPressed: () => setState(() => _showPass = !_showPass),
                  ),
                )),
              const SizedBox(height: 16),

              _label('CONFIRM PASSWORD'),
              const SizedBox(height: 6),
              TextField(controller: _confirmCtrl, obscureText: !_showConfirm,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: 'Confirm your password', errorText: _errors['confirm'],
                  suffixIcon: IconButton(
                    icon: Icon(_showConfirm ? Icons.visibility_off : Icons.visibility,
                        size: 20, color: Colors.grey),
                    onPressed: () => setState(() => _showConfirm = !_showConfirm),
                  ),
                )),
              const SizedBox(height: 32),

              GestureDetector(
                onTap: _loading ? null : _signUp,
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
                      : const Text('Create Account',
                          style: TextStyle(fontWeight: FontWeight.w900,
                              fontSize: 13, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 24),

              Center(child: GestureDetector(
                onTap: () => context.go('/login'),
                child: RichText(text: TextSpan(
                  text: 'Already have an account? ',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  children: [
                    TextSpan(text: 'LOG IN',
                        style: TextStyle(color: kPrimary, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  ],
                )),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900,
          color: kPrimary, letterSpacing: 2));
}