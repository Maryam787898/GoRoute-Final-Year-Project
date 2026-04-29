import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:goroute_app/models/onboarding_model.dart';

// ── SharedPreferences key ─────────────────────────────────────────────────────
const String kOnboardingComplete = 'onboarding_complete';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  // ── State ───────────────────────────────────────────────────────────────────
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Per-page animation controllers
  late List<AnimationController> _iconControllers;
  late List<AnimationController> _textControllers;
  late List<Animation<double>> _iconScaleAnims;
  late List<Animation<double>> _iconBounceAnims;
  late List<Animation<double>> _textFadeAnims;
  late List<Animation<Offset>> _textSlideAnims;

  // Button pulse
  late AnimationController _buttonController;
  late Animation<double> _buttonScaleAnim;

  @override
  void initState() {
    super.initState();

    // Dark status bar icons — white background
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    _iconControllers = List.generate(
      onboardingPages.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700),
      ),
    );
    _textControllers = List.generate(
      onboardingPages.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );

    _iconScaleAnims =
        _iconControllers
            .map(
              (c) => Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(CurvedAnimation(parent: c, curve: Curves.elasticOut)),
            )
            .toList();

    _iconBounceAnims =
        _iconControllers
            .map(
              (c) => Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: c,
                  curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
                ),
              ),
            )
            .toList();

    _textFadeAnims =
        _textControllers
            .map(
              (c) => Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(CurvedAnimation(parent: c, curve: Curves.easeOut)),
            )
            .toList();

    _textSlideAnims =
        _textControllers
            .map(
              (c) => Tween<Offset>(
                begin: const Offset(0, 0.25),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: c, curve: Curves.easeOut)),
            )
            .toList();

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _buttonScaleAnim = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    _animatePage(0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _iconControllers) {
      c.dispose();
    }
    for (final c in _textControllers) {
      c.dispose();
    }
    _buttonController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  void _animatePage(int index) {
    _iconControllers[index].forward(from: 0);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _textControllers[index].forward(from: 0);
    });
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kOnboardingComplete, true);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/role-selection');
  }

  void _nextPage() {
    if (_currentPage < onboardingPages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skip() => _completeOnboarding();

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == onboardingPages.length - 1;
    final cardColor = onboardingPages[_currentPage].backgroundColor;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────────────
            _buildTopBar(isLast, cardColor),

            // ── PageView ─────────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                  _animatePage(index);
                },
                itemCount: onboardingPages.length,
                itemBuilder:
                    (context, index) =>
                        _buildPage(onboardingPages[index], index),
              ),
            ),

            // ── Bottom: dots + button ─────────────────────────────────────
            _buildBottomSection(isLast, cardColor),
          ],
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────────

  Widget _buildTopBar(bool isLast, Color cardColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page counter pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_currentPage + 1} / ${onboardingPages.length}',
              style: GoogleFonts.poppins(
                color: cardColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Skip button
          AnimatedOpacity(
            opacity: isLast ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: TextButton(
              onPressed: isLast ? null : _skip,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF9CA3AF),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
              ),
              child: Text(
                'Skip',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Single page ───────────────────────────────────────────────────────────────

  Widget _buildPage(OnboardingModel page, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // ── Colored illustration card ──────────────────────────────────────
          ScaleTransition(
            scale: _iconScaleAnims[index],
            child: Container(
              width: double.infinity,
              height: 280,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [page.backgroundColor, page.accentColor],
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: page.backgroundColor.withValues(alpha: 0.35),
                    blurRadius: 32,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Decorative circles inside the card
                  Positioned(
                    top: -30,
                    right: -30,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -20,
                    left: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),

                  // Centered icon with floating animation
                  Center(
                    child: AnimatedBuilder(
                      animation: _iconBounceAnims[index],
                      builder: (context, child) {
                        final offset =
                            7.0 *
                            (0.5 - (_iconBounceAnims[index].value - 0.5).abs());
                        return Transform.translate(
                          offset: Offset(0, -offset),
                          child: child,
                        );
                      },
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                        child: Icon(page.icon, size: 58, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 36),

          // ── Text content on white background ──────────────────────────────
          FadeTransition(
            opacity: _textFadeAnims[index],
            child: SlideTransition(
              position: _textSlideAnims[index],
              child: Column(
                children: [
                  Text(
                    page.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827),
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    page.subtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      color: const Color(0xFF6B7280),
                      height: 1.65,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom section ────────────────────────────────────────────────────────────

  Widget _buildBottomSection(bool isLast, Color cardColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
      child: Column(
        children: [
          // Dot indicators
          _buildDots(cardColor),

          const SizedBox(height: 28),

          // Action button
          ScaleTransition(
            scale: _buttonScaleAnim,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cardColor,
                    foregroundColor: Colors.white,
                    elevation: 6,
                    shadowColor: cardColor.withValues(alpha: 0.45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child:
                        isLast
                            ? Row(
                              key: const ValueKey('get_started'),
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Get Started',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 20,
                                ),
                              ],
                            )
                            : Row(
                              key: const ValueKey('next'),
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Next',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 20,
                                ),
                              ],
                            ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Dot indicators ────────────────────────────────────────────────────────────

  Widget _buildDots(Color activeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(onboardingPages.length, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 26 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? activeColor : const Color(0xFFD1D5DB),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
