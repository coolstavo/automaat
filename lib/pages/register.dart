import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/logo_widget.dart';
import '../theme/constants.dart';
import 'login.dart';

/// Registratie‑scherm dat `/api/AM/register` aanroept.

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController(); // ← nieuw
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _loading = false;
  String? _error;

  /// Stuurt de registratie naar de backend en gaat bij succes terug naar login.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AuthService.register(
        login: _usernameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } catch (_) {
      setState(() {
        _error = 'Registratie mislukt. Probeer het opnieuw.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
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
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'REGISTER',
                          style: TextStyle(
                            fontFamily: 'BHH Sans Bartleby',
                            color: Colors.white,
                            fontSize: 22,
                            letterSpacing: 6,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _firstNameController,
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration().copyWith(
                            labelText: 'FIRST NAME',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Vul je voornaam in'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _lastNameController,
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration().copyWith(
                            labelText: 'LAST NAME',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Vul je achternaam in'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        // NIEUW: USERNAME / LOGIN veld
                        TextFormField(
                          controller: _usernameController,
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration().copyWith(
                            labelText: 'USERNAME',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Vul een gebruikersnaam in';
                            }
                            if (v.contains(' ')) {
                              return 'Geen spaties in gebruikersnaam';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration().copyWith(
                            labelText: 'EMAIL',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Vul je e‑mail in';
                            }
                            if (!v.contains('@')) {
                              return 'Geen geldige e‑mail';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration().copyWith(
                            labelText: 'PASSWORD',
                          ),
                          obscureText: true,
                          validator: (v) => v != null && v.length >= 6
                              ? null
                              : 'Minimaal 6 tekens',
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmController,
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration().copyWith(
                            labelText: 'CONFIRM PASSWORD',
                          ),
                          obscureText: true,
                          validator: (v) => v == _passwordController.text
                              ? null
                              : 'Wachtwoorden komen niet overeen',
                        ),
                        const SizedBox(height: 16),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
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
            ),
            // Onderste LOGIN‑knop om terug te kunnen naar het login‑scherm.
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  child: const Text(
                    'LOGIN',
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
