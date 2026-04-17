import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:goroute_app/services/auth_service.dart';
import 'package:goroute_app/main.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isSignIn = true;
  bool loading = false;
  bool showPassword = false;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  final AuthService _authService = AuthService();

  // =========================
  // EMAIL LOGIN / REGISTER
  // =========================
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = Provider.of<AppState>(context, listen: false);
    final role = appState.selectedRole ?? 'passenger';

    setState(() => loading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final name = _nameController.text.trim();

      if (isSignIn) {
        final userCredential = await _authService.signInWithEmail(
          email,
          password,
          role: role,
        );

        if (userCredential != null && mounted) {
          _navigateBasedOnRole(role);
        }
      } else {
        final userCredential = await _authService.registerWithEmail(
          email,
          password,
          name,
          role: role,
        );

        if (userCredential != null && mounted) {
          setState(() => isSignIn = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Account created! Please sign in")),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => loading = false);
  }

  void _navigateBasedOnRole(String role) {
    if (role == 'driver') {
      Navigator.pushReplacementNamed(context, '/driver-dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/passenger-home');
    }
  }

  // =========================
  // 🔥 GOOGLE SIGN IN FIXED
  // =========================
  Future<void> _handleGoogleSignIn() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final role = appState.selectedRole ?? 'passenger';

    setState(() => loading = true);

    try {
      final userCredential = await _authService.signInWithGoogle(role: role);

      if (userCredential != null && mounted) {
        _navigateBasedOnRole(role);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B0000),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          isSignIn ? "Sign In" : "Create Account",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ================= BODY =================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🔥 TOGGLE
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isSignIn = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color:
                                isSignIn
                                    ? const Color(0xFF8B0000)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            "Sign In",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: isSignIn ? Colors.white : Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isSignIn = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color:
                                !isSignIn
                                    ? const Color(0xFF8B0000)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            "Register",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: !isSignIn ? Colors.white : Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // NAME
              if (!isSignIn)
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person),
                    hintText: "Full Name",
                    border: OutlineInputBorder(),
                  ),
                ),

              const SizedBox(height: 12),

              // EMAIL
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.email),
                  hintText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              // PASSWORD
              TextFormField(
                controller: _passwordController,
                obscureText: !showPassword,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed:
                        () => setState(() => showPassword = !showPassword),
                  ),
                  hintText: "Password",
                  border: const OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 25),

              // MAIN BUTTON
              ElevatedButton(
                onPressed: loading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B0000),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child:
                    loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                          isSignIn ? "Sign In" : "Create Account",
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
              ),

              const SizedBox(height: 20),

              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text("OR"),
                  ),
                  Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 20),

              // GOOGLE BUTTON
              OutlinedButton.icon(
                onPressed: loading ? null : _handleGoogleSignIn,
                icon: Image.asset('Images/google.jpeg', height: 22),
                label: Text(
                  "Continue with Google",
                  style: GoogleFonts.poppins(),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
