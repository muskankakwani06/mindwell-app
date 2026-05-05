import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/mw_card.dart';
import '../widgets/mw_button.dart';

const _timeSlots = ['09:00','10:00','11:00','12:00','14:00','15:00','16:00','17:00'];

class TherapistsScreen extends StatefulWidget {
  const TherapistsScreen({super.key});
  @override
  State<TherapistsScreen> createState() => _TherapistsScreenState();
}

class _TherapistsScreenState extends State<TherapistsScreen> {
  List<Map<String, dynamic>> _therapists = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('therapists').get();
      if (mounted) {
        setState(() {
          _therapists = snap.docs.map((d) => {'Therapist_ID': d.id, ...d.data()}).toList();
          _loading = false;
        });
      }
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  void _openBooking(Map<String, dynamic> t) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingSheet(therapist: t, initialDate: tomorrow),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: _therapists.length,
              itemBuilder: (_, i) => _TherapistCard(t: _therapists[i], onBook: () => _openBooking(_therapists[i])),
            ),
    );
  }
}

class _TherapistCard extends StatelessWidget {
  final Map<String, dynamic> t;
  final VoidCallback onBook;
  const _TherapistCard({required this.t, required this.onBook});

  @override
  Widget build(BuildContext context) {
    final String name = t['Name']?.toString() ?? '';
    final initials = name.split(' ').where((s) => s.isNotEmpty).map((s) => s[0].toUpperCase()).take(2).join();
    final rating = t['avg_rating'];
    final reviewCount = t['review_count'] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MwCard(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: 26, backgroundColor: AppTheme.primaryLight,
              child: Text(initials, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primary)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: GoogleFonts.dmSerifDisplay(fontSize: 17, color: AppTheme.foreground)),
              Text(t['Specialization'] ?? '', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.mutedFg)),
            ])),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            if (rating != null) ...[
              const Icon(CupertinoIcons.star_fill, color: Color(0xFFFBBF24), size: 14),
              const SizedBox(width: 4),
              Text('$rating ($reviewCount review${reviewCount != 1 ? 's' : ''})',
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.mutedFg)),
            ] else
              Text('No reviews yet', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.mutedFg)),
            if (t['Phone'] != null) ...[
              const SizedBox(width: 16),
              Icon(CupertinoIcons.phone, size: 12, color: AppTheme.mutedFg),
              const SizedBox(width: 4),
              Text('${t['Phone']}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.mutedFg)),
            ],
          ]),
          const SizedBox(height: 16),
          MwButton(label: 'Book Session', onTap: onBook),
        ]),
      ),
    );
  }
}

class _BookingSheet extends StatefulWidget {
  final Map<String, dynamic> therapist;
  final DateTime initialDate;
  const _BookingSheet({required this.therapist, required this.initialDate});
  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  late DateTime _date;
  String? _time;
  bool _booking = false;

  @override
  void initState() { super.initState(); _date = widget.initialDate; }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: _date,
      firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.primary)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _book() async {
    if (_time == null) { MwSnackBar.show(context, 'Select a time slot'); return; }
    setState(() => _booking = true);
    try {
      final user = context.read<AuthProvider>().user!;
      final dateStr = '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';
      
      await FirebaseFirestore.instance.collection('appointments').add({
        'date': dateStr,
        'time': '$_time:00',
        'userId': user.uid,
        'therapistId': widget.therapist['Therapist_ID'],
        'therapist_name': widget.therapist['Name'],
        'Specialization': widget.therapist['Specialization'],
        'status': 'upcoming',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
         MwSnackBar.show(context, '✅ Appointment booked!');
      }
    } catch (_) {
      if (mounted) MwSnackBar.show(context, '❌ Booking failed');
    }
    if (mounted) setState(() => _booking = false);
  }

  @override
  Widget build(BuildContext context) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Book Appointment', style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: AppTheme.foreground)),
            Text('${widget.therapist['Name']} — ${widget.therapist['Specialization']}',
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.mutedFg)),
          ]),
          GestureDetector(onTap: () => Navigator.pop(context),
            child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppTheme.muted, borderRadius: BorderRadius.circular(10)),
              child: const Icon(CupertinoIcons.xmark, size: 16, color: AppTheme.mutedFg))),
        ]),
        const SizedBox(height: 20),

        // Date
        Text('Select Date', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.foreground)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.border)),
            child: Row(children: [
              const Icon(CupertinoIcons.calendar, size: 16, color: AppTheme.primary),
              const SizedBox(width: 10),
              Text('${_date.day} ${months[_date.month - 1]} ${_date.year}',
                  style: GoogleFonts.inter(fontSize: 14, color: AppTheme.foreground)),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        // Time
        Text('Select Time', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.foreground)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: _timeSlots.map((s) {
          final sel = _time == s;
          return GestureDetector(
            onTap: () => setState(() => _time = s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: sel ? AppTheme.primary : AppTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: sel ? AppTheme.primary : AppTheme.border),
              ),
              child: Text(s, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppTheme.foreground)),
            ),
          );
        }).toList()),
        const SizedBox(height: 24),
        MwButton(label: _booking ? 'Booking…' : 'Confirm Appointment', onTap: _booking ? null : _book, loading: _booking),
      ]),
    );
  }
}
