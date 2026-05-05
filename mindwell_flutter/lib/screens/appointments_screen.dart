import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/mw_card.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});
  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<Map<String, dynamic>> _appointments = [];
  bool _loading = true;
  Stream<QuerySnapshot>? _stream;

  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthProvider>().user!.uid;
    _stream = FirebaseFirestore.instance
        .collection('appointments')
        .where('userId', '==', uid)
        .snapshots();
  }

  Future<void> _cancel(String id) async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Cancel Appointment?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          CupertinoDialogAction(isDestructiveAction: true, onPressed: () => Navigator.pop(context, true), child: const Text('Cancel it')),
          CupertinoDialogAction(isDefaultAction: true, onPressed: () => Navigator.pop(context, false), child: const Text('Keep')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await FirebaseFirestore.instance.collection('appointments').doc(id).delete();
      MwSnackBar.show(context, 'Appointment cancelled');
    } catch (_) { MwSnackBar.show(context, 'Failed to cancel'); }
  }

  String _fmtDate(dynamic d) {
    if (d == null) return '';
    try {
      final dt = DateTime.parse(d.toString());
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';

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
        leading: IconButton(icon: const Icon(CupertinoIcons.back), onPressed: () => context.go('/dashboard')),
        actions: [
          TextButton(
            onPressed: () => context.go('/therapists'),
            child: Text('+ Book', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primary)),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No appointments found', style: GoogleFonts.inter(color: AppTheme.mutedFg)));
          }

          final appts = snapshot.data!.docs.map((d) => {'Appointment_ID': d.id, ...d.data() as Map<String, dynamic>}).toList();
          final upcoming = appts.where((a) => (a['date'] ?? '').toString().substring(0, 10).compareTo(todayStr) >= 0).toList();
          final past = appts.where((a) => (a['date'] ?? '').toString().substring(0, 10).compareTo(todayStr) < 0).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              Text('Upcoming (${upcoming.length})', style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: AppTheme.foreground)),
              const SizedBox(height: 12),
              if (upcoming.isEmpty)
                MwCard(child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(children: [
                    Icon(CupertinoIcons.calendar, size: 36, color: AppTheme.mutedFg),
                    const SizedBox(height: 8),
                    Text('No upcoming appointments', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.mutedFg)),
                    const SizedBox(height: 4),
                    GestureDetector(onTap: () => context.go('/therapists'),
                      child: Text('Book one now', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary))),
                  ]),
                ))
              else
                ...upcoming.map((a) => _ApptTile(a: a, fmtDate: _fmtDate, canCancel: true, onCancel: () => _cancel(a['Appointment_ID']))),
              if (past.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Past (${past.length})', style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: AppTheme.foreground)),
                const SizedBox(height: 12),
                Opacity(opacity: 0.6, child: Column(children: past.map((a) => _ApptTile(a: a, fmtDate: _fmtDate, canCancel: false)).toList())),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ApptTile extends StatelessWidget {
  final Map<String, dynamic> a;
  final String Function(dynamic) fmtDate;
  final bool canCancel;
  final VoidCallback? onCancel;
  const _ApptTile({required this.a, required this.fmtDate, required this.canCancel, this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MwCard(child: Row(children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(13)),
          child: const Icon(CupertinoIcons.calendar, color: AppTheme.primary, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(a['therapist_name'] ?? '', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.foreground)),
          Text(a['Specialization'] ?? '', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.mutedFg)),
          if (a['therapist_phone'] != null)
            Row(children: [
              Icon(CupertinoIcons.phone, size: 10, color: AppTheme.mutedFg), const SizedBox(width: 4),
              Text('${a['therapist_phone']}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.mutedFg)),
            ]),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(fmtDate(a['Date']), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.foreground)),
          Text((a['Time'] ?? '').toString().length >= 5 ? a['Time'].toString().substring(0, 5) : '',
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.mutedFg)),
        ]),
        if (canCancel) ...[
          const SizedBox(width: 8),
          GestureDetector(onTap: onCancel,
            child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppTheme.destructive.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
              child: Icon(CupertinoIcons.trash, size: 16, color: AppTheme.destructive))),
        ],
      ])),
    );
  }
}
