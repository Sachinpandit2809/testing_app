import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool _hidePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  // =========================
  // LOGIN
  // =========================

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty) {
      showMessage('Please enter your email.');
      return;
    }

    if (password.isEmpty) {
      showMessage('Please enter your password.');
      return;
    }

    final authProvider = context.read<AuthProvider>();

    final bool success = await authProvider.login(
      email: email,
      password: password,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
        (route) => false,
      );
    } else {
      showMessage(
        authProvider.errorMessage ??
            'Something went wrong.',
      );
    }
  }

  // =========================
  // SHOW MESSAGE
  // =========================

  void showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // =========================
  // UI
  // =========================

  @override
  Widget build(BuildContext context) {
    final bool isLoading =
        context.watch<AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            children: [
              const SizedBox(height: 80),

              const Icon(
                Icons.chat,
                size: 80,
              ),

              const SizedBox(height: 30),

              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              // EMAIL
              TextField(
                controller: emailController,

                keyboardType:
                    TextInputType.emailAddress,

                enabled: !isLoading,

                decoration: const InputDecoration(
                  labelText: 'Email',

                  hintText: 'Enter your email',

                  prefixIcon: Icon(
                    Icons.email_outlined,
                  ),

                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // PASSWORD
              TextField(
                controller: passwordController,

                obscureText: _hidePassword,

                enabled: !isLoading,

                decoration: InputDecoration(
                  labelText: 'Password',

                  hintText: 'Enter your password',

                  prefixIcon: const Icon(
                    Icons.lock_outline,
                  ),

                  suffixIcon: IconButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            setState(() {
                              _hidePassword =
                                  !_hidePassword;
                            });
                          },
                    icon: Icon(
                      _hidePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                  ),

                  border: const OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 25),

              // LOGIN BUTTON
              SizedBox(
                width: double.infinity,

                height: 52,

                child: ElevatedButton(
                  onPressed:
                      isLoading ? null : login,

                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,

                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // REGISTER
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [
                  const Text(
                    "Don't have an account? ",
                  ),

                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const RegisterScreen(),
                              ),
                            );
                          },
                    child: const Text(
                      'Register',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}