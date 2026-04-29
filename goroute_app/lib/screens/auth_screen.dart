import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:goroute_app/services/auth_service.dart';
import 'package:goroute_app/main.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignIn = true;
  bool _loading = false;
  bool _showPassword = false;

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _authService = AuthService();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  String get _selectedRole =>
      Provider.of<AppState>(context, listen: false).selectedRole ?? 'passenger';

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateByRole(String role) {
    if (!mounted) return;
    if (role == 'driver') {
      Navigator.pushReplacementNamed(context, '/driver-dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/passenger-home');
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      if (_isSignIn) {
        final credential = await _authService.signInWithEmail(
          _emailCtrl.text.trim(),
          _passwordCtrl.text.trim(),
          selectedRole: _selectedRole,
        );
        await _authService.updateLastLogin(credential.user!.uid);
        final role = await _authService.getUserRole(credential.user!.uid);
        if (!mounted) return;
        _navigateByRole(role);
      } else {
        await _authService.registerWithEmail(
          _emailCtrl.text.trim(),
          _passwordCtrl.text.trim(),
          _nameCtrl.text.trim(),
        );
        if (!mounted) return;
        setState(() => _isSignIn = true);
        _showSuccess('Account created! Please sign in.');
      }
    } on RoleMismatchException catch (e) {
      _showError(e.message);
    } on FirebaseAuthException catch (e) {
      _showError(_friendlyError(e.code));
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _loading = true);
    try {
      await GoogleSignIn().signOut();
      final credential = await _authService.signInWithGoogle(
        selectedRole: _selectedRole,
      );
      await _authService.updateLastLogin(credential.user!.uid);
      final role = await _authService.getUserRole(credential.user!.uid);
      if (!mounted) return;
      _navigateByRole(role);
    } on RoleMismatchException catch (e) {
      _showError(e.message);
    } on FirebaseAuthException catch (e) {
      _showError(_friendlyError(e.code));
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDriver = _selectedRole == 'driver';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B0000),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _isSignIn ? 'Sign In' : 'Create Account',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Role indicator banner
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isDriver
                              ? const Color(0xFF8B0000).withValues(alpha: 0.08)
                              : Colors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isDriver
                                ? const Color(0xFF8B0000).withValues(alpha: 0.3)
                                : Colors.blue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isDriver ? Icons.directions_bus : Icons.person,
                          color:
                              isDriver ? const Color(0xFF8B0000) : Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isDriver
                              ? 'Signing in as Driver'
                              : 'Signing in as Passenger',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color:
                                isDriver
                                    ? const Color(0xFF8B0000)
                                    : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Driver note
                  if (isDriver && _isSignIn) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.amber.shade800,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Driver accounts are created by admin only.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Sign In / Register tab switcher
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        _tabButton(
                          'Sign In',
                          _isSignIn,
                          () => setState(() => _isSignIn = true),
                        ),
                        // Hide Register tab when driver role is selected
                        if (!isDriver)
                          _tabButton(
                            'Register',
                            !_isSignIn,
                            () => setState(() => _isSignIn = false),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Name field (register only)
                  if (!_isSignIn) ...[
                    TextFormField(
                      controller: _nameCtrl,
                      validator:
                          (v) =>
                              (v == null || v.isEmpty)
                                  ? 'Enter your name'
                                  : null,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person),
                        hintText: 'Full Name',
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Email
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    validator:
                        (v) =>
                            (v == null || !v.contains('@'))
                                ? 'Enter a valid email'
                                : null,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.email),
                      hintText: 'Email',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Password
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: !_showPassword,
                    validator:
                        (v) =>
                            (v == null || v.length < 6)
                                ? 'Min 6 characters'
                                : null,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock),
                      hintText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed:
                            () =>
                                setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  ElevatedButton(
                    onPressed: _loading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B0000),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _isSignIn ? 'Sign In' : 'Create Account',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Google sign-in
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _handleGoogleSignIn,
                    icon: const Icon(Icons.g_mobiledata, size: 28),
                    label: const Text('Continue with Google'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading overlay
          if (_loading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF8B0000) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? Colors.white : Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
