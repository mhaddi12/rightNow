import 'package:chats/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Generate an initial random name
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _generateName();
    });
  }

  void _generateName() {
    if (!mounted) return;
    final authService = Provider.of<AuthService>(context, listen: false);
    setState(() {
      _nameController.text = authService.generateRandomName();
    });
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    try {
      if (_isLogin) {
        await auth.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        if (_nameController.text.isEmpty) {
          _generateName(); // Ensure a name exists
        }
        await auth.signUpWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.flash_on, size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                Text(
                  _isLogin ? 'Welcome Back' : 'Join Right Now',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (!_isLogin) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Display Name (Dummy)',
                            hintText: 'e.g. Happy Panda',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _generateName,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Generate new random name',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(_isLogin ? 'Sign In' : 'Sign Up'),
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                      if (!_isLogin && _nameController.text.isEmpty) {
                        _generateName();
                      }
                    });
                  },
                  child: Text(
                    _isLogin
                        ? 'Create an account'
                        : 'Already have an account? Sign in',
                  ),
                ),
                const Divider(height: 32),
                OutlinedButton.icon(
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    try {
                      await Provider.of<AuthService>(
                        context,
                        listen: false,
                      ).signInAnonymously();
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  },
                  icon: const Icon(Icons.person_off),
                  label: const Text('Continue as Guest'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
