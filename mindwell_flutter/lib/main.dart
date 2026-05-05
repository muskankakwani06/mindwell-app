import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'providers/auth_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const DevicePreviewWrapper());
}

class MindWellApp extends StatelessWidget {
  const MindWellApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = AppRouter.router(context.watch<AuthProvider>());
    return MaterialApp.router(
      title: 'MindWell',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}

// ─── iPhone Device Preview Wrapper ───────────────────────────────────────────
// Run this class as the root to see iPhone frame preview in web/desktop.
class DevicePreviewWrapper extends StatefulWidget {
  const DevicePreviewWrapper({super.key});

  @override
  State<DevicePreviewWrapper> createState() => _DevicePreviewWrapperState();
}

class _DevicePreviewWrapperState extends State<DevicePreviewWrapper> {
  double _scale = 0.85;
  final GlobalKey _phoneKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFE8EDF2),
        body: SafeArea(
          child: Column(
            children: [
              // Toolbar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFF1C1C1E),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.device_phone_portrait,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'MindWell  ·  iPhone 16 Pro',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text('Scale', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 120,
                      child: Slider(
                        value: _scale,
                        min: 0.5,
                        max: 1.0,
                        activeColor: const Color(0xFF30D158),
                        onChanged: (v) => setState(() => _scale = v),
                      ),
                    ),
                    Text(
                      '${(_scale * 100).round()}%',
                      style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Phone Frame
              Expanded(
                child: Center(
                  child: Transform.scale(
                    scale: _scale,
                    child: _IPhone16ProFrame(child: _AppContent()),
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

class _AppContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: Builder(
        builder: (ctx) {
          final router = AppRouter.router(ctx.watch<AuthProvider>());
          return MaterialApp.router(
            title: 'MindWell',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: router,
          );
        },
      ),
    );
  }
}

class _IPhone16ProFrame extends StatelessWidget {
  final Widget child;
  const _IPhone16ProFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    // iPhone 16 Pro dimensions: 393 × 852 logical pixels
    const double phoneW = 393.0;
    const double phoneH = 852.0;
    const double bezel = 14.0;
    const double cornerR = 54.0;

    return SizedBox(
      width: phoneW + bezel * 2,
      height: phoneH + bezel * 2,
      child: Stack(
        children: [
          // Outer shell
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(cornerR),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4A4A4C), Color(0xFF2C2C2E), Color(0xFF1C1C1E)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.08),
                  blurRadius: 1,
                  offset: const Offset(-1, -1),
                ),
              ],
            ),
          ),
          // Screen area
          Positioned(
            top: bezel,
            left: bezel,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(cornerR - bezel),
              child: SizedBox(
                width: phoneW,
                height: phoneH,
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 44),
                      child: child,
                    ),
                    // Dynamic Island
                    Positioned(
                      top: 12,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 126,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Side buttons (left)
          Positioned(
            top: 120,
            left: 0,
            child: _SideButton(height: 36),
          ),
          Positioned(
            top: 170,
            left: 0,
            child: _SideButton(height: 64),
          ),
          Positioned(
            top: 244,
            left: 0,
            child: _SideButton(height: 64),
          ),
          // Side button (right)
          Positioned(
            top: 180,
            right: 0,
            child: _SideButton(height: 80),
          ),
        ],
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  final double height;
  const _SideButton({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A3C),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
