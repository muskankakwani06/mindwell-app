import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/mw_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final uid = context.read<AuthProvider>().user!.uid;
      final db = FirebaseFirestore.instance;

      // Parallel fetch
      final results = await Future.wait([
        db.collection('appointments').where('userId', '==', uid).get(),
        db.collection('assessments').where('userId', '==', uid).get(),
        db.collection('appointments')
            .where('userId', '==', uid)
            .where('Status', '==', 'Booked')
            .get(),
      ]);

      final allAppointments = results[0].docs;
      final allAssessments = results[1].docs;
      final upcomingDocs = results[2].docs;

      if (mounted) {
        setState(() {
          _data = {
            'stats': {
              'sessions': allAppointments.length,
              'assessments': allAssessments.length,
            },
            'upcomingAppointments': upcomingDocs.map((d) => d.data()).toList(),
            'recentAssessments': allAssessments.map((d) => d.data()).take(3).toList(),
          };
          _loading = false;
        });
      }
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  String _fmtDate(dynamic d) {
    if (d == null) return '';
    try {
      final dt = DateTime.parse(d.toString());
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${m[dt.month - 1]}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(8)),
              child: const Icon(CupertinoIcons.heart_fill, color: AppTheme.primary, size: 16),
            ),
            const SizedBox(width: 8),
            Text('MindWell', style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: AppTheme.foreground)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: CircleAvatar(
              radius: 17, backgroundColor: AppTheme.primaryLight,
              child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'M',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.primary)),
            ),
            itemBuilder: (_) => [
              PopupMenuItem(child: Text('Appointments'), onTap: () => context.go('/appointments')),
              PopupMenuItem(child: Text('Payment'), onTap: () => context.go('/payment')),
              PopupMenuItem(child: Text('Feedback'), onTap: () => context.go('/feedback')),
              const PopupMenuDivider(),
              PopupMenuItem(
                child: Text('Sign Out', style: TextStyle(color: AppTheme.destructive)),
                onTap: () => context.read<AuthProvider>().logout(),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(color: AppTheme.primary, onRefresh: _fetch, child: _body(user)),
    );
  }

  Widget _body(AuthUser user) {
    final stats = _data?['stats'] ?? {};
    final upcoming = List<Map<String, dynamic>>.from(_data?['upcomingAppointments'] ?? []);
    final assessments = List<Map<String, dynamic>>.from(_data?['recentAssessments'] ?? []);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Welcome Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Welcome back, ${user.name.toString().split(' ').first}',
                  style: GoogleFonts.dmSerifDisplay(fontSize: 28, color: AppTheme.foreground)),
              const SizedBox(height: 2),
              Text("Ready for your wellness check-in?", style: GoogleFonts.inter(fontSize: 14, color: AppTheme.mutedFg)),
            ]),
          ],
        ),
        const SizedBox(height: 24),

        // Daily Tip Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF25855A)]),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 10))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(CupertinoIcons.sparkles, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('DAILY WELLNESS TIP', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white.withOpacity(0.8), letterSpacing: 1)),
            ]),
            const SizedBox(height: 12),
            Text('Practice "box breathing" for 2 minutes to quickly lower stress levels and regain focus.',
                style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: Colors.white, height: 1.3)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(100)),
              child: Text('Try Now →', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ]),
        ),
        const SizedBox(height: 32),

        // Stats Row
        Text('Your Progress', style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: AppTheme.foreground)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: GradientStatCard(icon: CupertinoIcons.clock_fill, value: '${stats['sessions'] ?? 0}', label: 'Sessions Done', bgColor: AppTheme.sageBg)),
          const SizedBox(width: 12),
          Expanded(child: GradientStatCard(icon: CupertinoIcons.waveform, value: '${stats['assessments'] ?? 0}', label: 'Assessments', bgColor: AppTheme.skyBg)),
        ]),
        const SizedBox(height: 32),

        // Quick Actions (Iconic Style)
        Text('Quick Actions', style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: AppTheme.foreground)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _QA(icon: CupertinoIcons.calendar_badge_plus, label: 'Book', color: AppTheme.cardColor, onTap: () => context.go('/therapists')),
          _QA(icon: CupertinoIcons.chat_bubble_2_fill, label: 'Chat', color: AppTheme.cardColor, onTap: () => context.go('/chat')),
          _QA(icon: CupertinoIcons.creditcard_fill, label: 'Pay', color: AppTheme.cardColor, onTap: () => context.go('/payment')),
          _QA(icon: CupertinoIcons.star_fill, label: 'Review', color: AppTheme.cardColor, onTap: () => context.go('/feedback')),
        ]),
        const SizedBox(height: 32),

        // Upcoming Activity Section
        SectionTitle(title: 'Upcoming Session', action: 'View all', onAction: () => context.go('/appointments')),
        const SizedBox(height: 16),
        if (upcoming.isEmpty)
          _EmptyBox(icon: CupertinoIcons.calendar, msg: 'No sessions booked for this week', actionLabel: 'Find a therapist', onAction: () => context.go('/therapists'))
        else
          ...upcoming.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MwCard(child: Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(16)),
                child: const Icon(CupertinoIcons.calendar, color: AppTheme.primary, size: 20)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a['therapist_name'] ?? '', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
                Text(a['Specialization'] ?? '', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.mutedFg)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(_fmtDate(a['Date']), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
                Text((a['Time'] ?? '').toString().length >= 5 ? a['Time'].toString().substring(0, 5) : '', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.mutedFg)),
              ]),
            ])),
          )),
      ]),
    );
  }
}

class _QA extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _QA({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Expanded(child: GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border.withOpacity(0.7))),
      child: Column(children: [
        Icon(icon, color: AppTheme.primary, size: 22),
        const SizedBox(height: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.foreground)),
      ]),
    )));
  }
}

class _EmptyBox extends StatelessWidget {
  final IconData icon; final String msg; final String actionLabel; final VoidCallback onAction;
  const _EmptyBox({required this.icon, required this.msg, required this.actionLabel, required this.onAction});
  @override
  Widget build(BuildContext context) {
    return MwCard(child: Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Column(children: [
      Icon(icon, size: 32, color: AppTheme.mutedFg),
      const SizedBox(height: 8),
      Text(msg, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.mutedFg)),
      const SizedBox(height: 4),
      GestureDetector(onTap: onAction, child: Text('$actionLabel →', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary))),
    ]))));
  }
}
