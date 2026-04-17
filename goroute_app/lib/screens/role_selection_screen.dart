import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:goroute_app/main.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String selectedRole = 'passenger';

  void handleContinue() {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.setSelectedRole(selectedRole);
    Navigator.of(context).pushNamed('/auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B0000),
        title: Text(
          'Choose Role',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 4,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),

              // LOGO
              Image.asset('Images/logo.jpeg', height: 150),

              const SizedBox(height: 40),

              Text(
                'Get Started',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Choose your role',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: const Color(0xFF6B7280),
                ),
              ),

              const SizedBox(height: 50),

              // ROLE CARDS
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedRole = 'passenger'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color:
                              selectedRole == 'passenger'
                                  ? const Color(0xFF8B0000)
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: const Color(0xFF8B0000)),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.person,
                              color:
                                  selectedRole == 'passenger'
                                      ? Colors.white
                                      : const Color(0xFF8B0000),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Passenger',
                              style: GoogleFonts.poppins(
                                color:
                                    selectedRole == 'passenger'
                                        ? Colors.white
                                        : const Color(0xFF8B0000),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedRole = 'driver'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color:
                              selectedRole == 'driver'
                                  ? const Color(0xFF8B0000)
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: const Color(0xFF8B0000)),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.account_circle,
                              color:
                                  selectedRole == 'driver'
                                      ? Colors.white
                                      : const Color(0xFF8B0000),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Driver',
                              style: GoogleFonts.poppins(
                                color:
                                    selectedRole == 'driver'
                                        ? Colors.white
                                        : const Color(0xFF8B0000),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // CONTINUE BUTTON (FORCED WHITE TEXT)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B0000),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white, // ✅ FIXED WHITE TEXT
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
