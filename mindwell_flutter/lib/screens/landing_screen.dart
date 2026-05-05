import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/mw_button.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Mesh Gradient Background
          Positioned(
            top: -100, right: -100,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryLight.withOpacity(0.4),
              ),
              child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: const SizedBox()),
            ),
          ),
          Positioned(
            bottom: -50, left: -50,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent.withOpacity(0.1),
              ),
              child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60), child: const SizedBox()),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // Logo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: AppTheme.primary.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: const Icon(CupertinoIcons.heart_fill, color: AppTheme.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Text('MindWell', style: GoogleFonts.dmSerifDisplay(fontSize: 28, color: AppTheme.foreground)),
                    ],
                  ),
                  const SizedBox(height: 50),
                  
                  // Headline with Animation
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(seconds: 1),
                    builder: (ctx, val, child) => Opacity(
                      opacity: val,
                      child: Padding(
                        padding: EdgeInsets.only(top: (1 - val) * 20),
                        child: child,
                      ),
                    ),
                    child: Column(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Text('Your mental health matters',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary, letterSpacing: 0.5)),
                      ),
                      const SizedBox(height: 24),
                      Text('A safe space for your mental wellness',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSerifDisplay(fontSize: 40, color: AppTheme.foreground, height: 1.1, letterSpacing: -0.5)),
                      const SizedBox(height: 16),
                      Text('Connect with licensed therapists, join support groups, and take assessments — all in one calm, secure platform.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 15, color: AppTheme.mutedFg, height: 1.6)),
                    ]),
                  ),
                  
                  const SizedBox(height: 48),
                  // CTA buttons
                  MwButton(label: 'Get Started Free', icon: CupertinoIcons.arrow_right, onTap: () => context.go('/signup')),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.go('/login'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      side: const BorderSide(color: AppTheme.border, width: 1.5),
                      foregroundColor: AppTheme.foreground,
                    ),
                    child: Text('Sign In', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                  
                  const SizedBox(height: 60),
                  // Feature grid
                  const _FeaturesGrid(),
                  const SizedBox(height: 48),
                  
                  // Premium CTA Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, Color(0xFF25855A)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text('Start your healing journey today',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSerifDisplay(fontSize: 24, color: Colors.white)),
                        const SizedBox(height: 10),
                        Text('Take the first step towards better mental health.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.85))),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => context.go('/signup'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primary,
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: Text('Create Free Account',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15)),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.heart_fill, color: AppTheme.primary, size: 14),
                      const SizedBox(width: 8),
                      Text('MindWell  ·  © 2026', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.mutedFg)),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturesGrid extends StatelessWidget {
  final List<_Feature> features = const [
    _Feature(icon: CupertinoIcons.waveform, title: 'Mental Assessments',
        desc: 'PHQ-9, GAD-7 & Stress tests', color: AppTheme.sageBg),
    _Feature(icon: CupertinoIcons.calendar, title: 'Easy Scheduling',
        desc: 'Book with licensed therapists', color: AppTheme.warmBg),
    _Feature(icon: CupertinoIcons.chat_bubble_2, title: 'Secure Chat',
        desc: 'Private therapist conversations', color: AppTheme.lavenderBg),
    _Feature(icon: CupertinoIcons.person_3, title: 'Support Groups',
        desc: 'Community who understands you', color: AppTheme.skyBg),
    _Feature(icon: CupertinoIcons.lock_shield, title: 'Safe & Private',
        desc: 'Your data, your control', color: AppTheme.sageBg),
    _Feature(icon: CupertinoIcons.sparkles, title: 'Holistic Care',
        desc: 'Feedback-driven wellness goals', color: AppTheme.warmBg),
  ];

  const _FeaturesGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Everything you need',
            style: GoogleFonts.dmSerifDisplay(
                fontSize: 24, color: AppTheme.foreground)),
        const SizedBox(height: 6),
        Text('Comprehensive tools for your mental health journey.',
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.mutedFg)),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: features.map((f) => _FeatureCard(feature: f)).toList(),
        ),
      ],
    );
  }
}

class _Feature {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  const _Feature({required this.icon, required this.title,
    required this.desc, required this.color});
}

class _FeatureCard extends StatelessWidget {
  final _Feature feature;
  const _FeatureCard({super.key, required this.feature});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: feature.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(feature.icon, color: AppTheme.primary, size: 22),
          const SizedBox(height: 10),
          Text(feature.title,
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppTheme.foreground)),
          const SizedBox(height: 4),
          Text(feature.desc,
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppTheme.mutedFg, height: 1.4),
              maxLines: 2),
        ],
      ),
    );
  }
}
