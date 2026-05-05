import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    const tabs = ['/dashboard', '/therapists', '/assessment', '/groups', '/chat'];
    final i = tabs.indexOf(path);
    return i < 0 ? 0 : i;
  }

  void _onTap(BuildContext context, int i) {
    const paths = ['/dashboard', '/therapists', '/assessment', '/groups', '/chat'];
    context.go(paths[i]);
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.background.withOpacity(0.85),
          border: const Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(icon: idx == 0 ? CupertinoIcons.house_fill : CupertinoIcons.house, label: 'Home', selected: idx == 0, onTap: () => _onTap(context, 0)),
                    _NavItem(icon: idx == 1 ? CupertinoIcons.person_2_fill : CupertinoIcons.person_2, label: 'Therapists', selected: idx == 1, onTap: () => _onTap(context, 1)),
                    _NavItem(icon: idx == 2 ? CupertinoIcons.waveform_path : CupertinoIcons.waveform, label: 'Assess', selected: idx == 2, onTap: () => _onTap(context, 2)),
                    _NavItem(icon: idx == 3 ? CupertinoIcons.person_3_fill : CupertinoIcons.person_3, label: 'Groups', selected: idx == 3, onTap: () => _onTap(context, 3)),
                    _NavItem(icon: idx == 4 ? CupertinoIcons.chat_bubble_2_fill : CupertinoIcons.chat_bubble_2, label: 'Chat', selected: idx == 4, onTap: () => _onTap(context, 4)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
              size: 22,
              color: selected ? AppTheme.primary : AppTheme.mutedFg,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppTheme.primary : AppTheme.mutedFg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
