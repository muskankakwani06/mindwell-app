import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/mw_button.dart';
import '../widgets/mw_text_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading = false;
  String _error = '';

  @override
  void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    setState(() { _error = ''; _loading = true; });
    try {
      final creds = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      if (creds.user != null) {
        await FirebaseFirestore.instance.collection('users').doc(creds.user!.uid).set({
          'name': _nameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'createdAt': DateTime.now().toIso8601String(),
        });
      }

      if (mounted) context.go('/dashboard');
    } catch (e) {
      setState(() { _error = 'Registration failed. Please try again.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Background accents
          Positioned(top: -50, right: -50, child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primaryLight.withOpacity(0.3)))),
          Positioned(bottom: -50, left: -50, child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.accent.withOpacity(0.1)))),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 44, height: 44, decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(16)),
                        child: const Icon(CupertinoIcons.heart_fill, color: AppTheme.primary, size: 22)),
                      const SizedBox(width: 12),
                      Text('MindWell', style: GoogleFonts.dmSerifDisplay(fontSize: 26, color: AppTheme.foreground)),
                    ],
                  ),
                  const SizedBox(height: 48),
                  
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: AppTheme.border, width: 0.5),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 15)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Create account', style: GoogleFonts.dmSerifDisplay(fontSize: 28, color: AppTheme.foreground)),
                        const SizedBox(height: 6),
                        Text('Start your wellness journey today', style: GoogleFonts.inter(fontSize: 14, color: AppTheme.mutedFg)),
                        const SizedBox(height: 32),
                        
                        if (_error.isNotEmpty) ...[
                          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.destructive.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                            child: Row(children: [
                              const Icon(CupertinoIcons.exclamationmark_circle, color: AppTheme.destructive, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_error, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.destructive))),
                            ])),
                          const SizedBox(height: 20),
                        ],
                        
                        _Label('FULL NAME'),
                        const SizedBox(height: 8),
                        MwTextField(controller: _nameCtrl, hint: 'Muskan'),
                        const SizedBox(height: 16),
                        _Label('EMAIL ADDRESS'),
                        const SizedBox(height: 8),
                        MwTextField(controller: _emailCtrl, hint: 'you@example.com', keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 16),
                        _Label('PHONE (OPTIONAL)'),
                        const SizedBox(height: 8),
                        MwTextField(controller: _phoneCtrl, hint: '9876543210', keyboardType: TextInputType.phone),
                        const SizedBox(height: 16),
                        _Label('PASSWORD'),
                        const SizedBox(height: 8),
                        MwTextField(controller: _passCtrl, hint: '••••••••', obscure: true),
                        const SizedBox(height: 32),
                        
                        MwButton(label: _loading ? 'Creating account…' : 'Create Account', onTap: _loading ? null : _submit, loading: _loading),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? ', style: GoogleFonts.inter(fontSize: 14, color: AppTheme.mutedFg)),
                      GestureDetector(onTap: () => context.go('/login'), child: Text('Sign in', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primary))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppTheme.mutedFg));
}
