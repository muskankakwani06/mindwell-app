import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/mw_card.dart';
import '../widgets/mw_button.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});
  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  Stream<QuerySnapshot>? _historyStream;
  int _rating = 0;
  int _hovered = 0;
  final _textCtrl = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthProvider>().user!.uid;
    _historyStream = FirebaseFirestore.instance
        .collection('feedback')
        .where('userId', '==', uid)
        .snapshots();
  }

  @override
  void dispose() { _textCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_rating == 0) { MwSnackBar.show(context, 'Select a star rating'); return; }
    setState(() => _submitting = true);
    try {
      final uid = context.read<AuthProvider>().user!.uid;
      await FirebaseFirestore.instance.collection('feedback').add({
        'userId': uid,
        'Rating': _rating,
        'Feedback_Text': _textCtrl.text,
        'Date': DateTime.now().toIso8601String(),
        'timestamp': FieldValue.serverTimestamp(),
      });
      setState(() { _submitted = true; _rating = 0; _textCtrl.clear(); });
      Future.delayed(const Duration(seconds: 3), () { if (mounted) setState(() => _submitted = false); });
    } catch (_) { MwSnackBar.show(context, 'Something went wrong'); }
    if (mounted) setState(() => _submitting = false);
  }

  Future<void> _delete(String id) async {
    try {
      await FirebaseFirestore.instance.collection('feedback').doc(id).delete();
      MwSnackBar.show(context, 'Feedback deleted');
    } catch (_) { MwSnackBar.show(context, "Couldn't delete"); }
  }

  static const _ratingLabels = ['', 'Poor', 'Fair', 'Good', 'Very Good', 'Excellent'];
  static const _ratingColors = [Colors.transparent, Color(0xFFEF4444), Color(0xFFF97316), Color(0xFFEAB308), Color(0xFF2D9F6B), Color(0xFF2D9F6B)];

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
        leading: IconButton(icon: const Icon(CupertinoIcons.back), onPressed: () => context.go('/dashboard')),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), children: [
        // Submit form
        MwCard(
          padding: const EdgeInsets.all(24),
          child: _submitted
              ? _successView()
              : Column(children: [
                  Text('How was your experience?', style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: AppTheme.foreground)),
                  const SizedBox(height: 4),
                  Text('Your feedback helps us improve MindWell.', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.mutedFg)),
                  const SizedBox(height: 20),
                  // Stars
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) {
                    final star = i + 1;
                    final active = star <= (_hovered > 0 ? _hovered : _rating);
                    return GestureDetector(
                      onTap: () => setState(() => _rating = star),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          active ? CupertinoIcons.star_fill : CupertinoIcons.star,
                          size: 36,
                          color: active ? const Color(0xFFFBBF24) : AppTheme.border,
                        ),
                      ),
                    );
                  })),
                  if (_rating > 0) ...[
                    const SizedBox(height: 8),
                    Text(_ratingLabels[_rating], style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: _ratingColors[_rating])),
                  ],
                  const SizedBox(height: 20),
                  TextField(
                    controller: _textCtrl, maxLines: 4,
                    style: GoogleFonts.inter(fontSize: 14, color: AppTheme.foreground),
                    decoration: InputDecoration(
                      hintText: 'Tell us more (optional)…',
                      hintStyle: GoogleFonts.inter(fontSize: 13, color: AppTheme.mutedFg),
                      filled: true, fillColor: AppTheme.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  MwButton(
                    label: _submitting ? 'Submitting…' : 'Submit Feedback',
                    icon: CupertinoIcons.arrow_up_circle_fill,
                    onTap: (_submitting || _rating == 0) ? null : _submit,
                    loading: _submitting,
                  ),
                ]),
        ),
        const SizedBox(height: 24),

        // History
        StreamBuilder<QuerySnapshot>(
          stream: _historyStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox();

            final history = snapshot.data!.docs.map((d) => {'Feedback_ID': d.id, ...d.data() as Map<String, dynamic>}).toList();
            history.sort((a, b) => (b['Date'] ?? '').compareTo(a['Date'] ?? ''));

            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Your Previous Feedback', style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: AppTheme.foreground)),
              const SizedBox(height: 12),
              ...history.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MwCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        ...List.generate(5, (i) => Icon(
                          i < (f['Rating'] ?? 0) ? CupertinoIcons.star_fill : CupertinoIcons.star,
                          size: 14,
                          color: i < (f['Rating'] ?? 0) ? const Color(0xFFFBBF24) : AppTheme.border,
                        )),
                        const SizedBox(width: 6),
                        Text(_ratingLabels[(f['Rating'] ?? 0).clamp(0, 5)],
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                                color: _ratingColors[(f['Rating'] ?? 0).clamp(0, 5)])),
                        if (f['therapist_name'] != null) ...[
                          const SizedBox(width: 6),
                          Text('· ${f['therapist_name']}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.mutedFg)),
                        ],
                      ]),
                      if ((f['Comments'] ?? f['Feedback_Text'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(f['Comments'] ?? f['Feedback_Text'] ?? '',
                            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.foreground, height: 1.5)),
                      ],
                      const SizedBox(height: 4),
                      Text(_fmtDate(f['Date']), style: GoogleFonts.inter(fontSize: 11, color: AppTheme.mutedFg)),
                    ])),
                    GestureDetector(
                      onTap: () => _delete(f['Feedback_ID']),
                      child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(
                        color: AppTheme.destructive.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
                        child: Icon(CupertinoIcons.trash, size: 16, color: AppTheme.destructive)),
                    ),
                  ]),
                ),
              )),
            ]);
          },
        ),
      ]),
    );
  }

  Widget _successView() => Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Column(children: [
    Container(width: 64, height: 64, decoration: BoxDecoration(color: AppTheme.primaryLight, shape: BoxShape.circle),
      child: const Icon(CupertinoIcons.checkmark_circle_fill, color: AppTheme.primary, size: 36)),
    const SizedBox(height: 12),
    Text('Thank you for your feedback!', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.foreground)),
    const SizedBox(height: 4),
    Text('Your response has been recorded.', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.mutedFg)),
  ]));

  String _fmtDate(dynamic d) {
    if (d == null) return '';
    try {
      final dt = DateTime.parse(d.toString());
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
    } catch (_) { return ''; }
  }
}
