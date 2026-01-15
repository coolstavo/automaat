import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/logo_widget.dart';
import '../theme/constants.dart';
import 'register.dart';
import 'home.dart';

/// Login-scherm dat praat met `/api/authenticate`.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  String? _error;

  String? _required(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  /// Probeert in te loggen en toont een generieke foutmelding bij failure.
  /// Alle echte HTTP-logica zit in [AuthService].
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AuthService.login(
        username: _loginController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (_) {
      setState(() {
        _error = 'Ongeldige gebruikersnaam of wachtwoord';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned(
              top: 24,
              left: 0,
              right: 0,
              child: Center(child: MaatAutoLogo()),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'LOGIN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          letterSpacing: 6,
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _loginController,
                        style: const TextStyle(color: Colors.black),
                        decoration: const InputDecoration().copyWith(
                          labelText: 'USERNAME OR EMAIL',
                        ),
                        validator: (v) =>
                            _required(v, 'Vul je gebruikersnaam of e‑mail in'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        style: const TextStyle(color: Colors.black),
                        decoration: const InputDecoration().copyWith(
                          labelText: 'PASSWORD',
                        ),
                        obscureText: true,
                        validator: (v) => _required(v, 'Vul je wachtwoord in'),
                      ),
                      const SizedBox(height: 24),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      TextButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('NEXT', style: nextTextStyle),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    );
                  },
                  child: const Text(
                    'REGISTER',
                    style: TextStyle(
                      color: Colors.white,
                      letterSpacing: 8,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
