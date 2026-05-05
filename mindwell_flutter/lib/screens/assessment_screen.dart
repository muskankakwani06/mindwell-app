import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/mw_card.dart';
import '../widgets/mw_button.dart';

const _tests = {
  'Depression Test': {
    'desc': 'PHQ-9 — Patient Health Questionnaire',
    'questions': [
      'Little interest or pleasure in doing things',
      'Feeling down, depressed, or hopeless',
      'Trouble falling or staying asleep, or sleeping too much',
      'Feeling tired or having little energy',
      'Poor appetite or overeating',
      'Feeling bad about yourself — or feeling like a failure',
      'Trouble concentrating on things',
      'Moving or speaking so slowly that others noticed',
      'Thoughts that you would be better off dead',
    ],
  },
  'Stress Test': {
    'desc': 'PSS-10 — Perceived Stress Scale',
    'questions': [
      'Upset because of something unexpected?',
      'Felt unable to control important things?',
      'Felt nervous and stressed?',
      'Confident handling personal problems?',
      'Felt things were going your way?',
      'Could not cope with everything you had to do?',
      'Able to control irritations?',
      'Felt on top of things?',
      'Angered by things outside your control?',
      'Difficulties piling up too high?',
    ],
  },
  'Anxiety Test': {
    'desc': 'GAD-7 — Generalized Anxiety Disorder',
    'questions': [
      'Feeling nervous, anxious, or on edge',
      'Not being able to stop or control worrying',
      'Worrying too much about different things',
      'Trouble relaxing',
      'Being so restless it\'s hard to sit still',
      'Becoming easily annoyed or irritable',
      'Feeling afraid something awful might happen',
    ],
  },
};

const _options = ['Not at all', 'Several days', 'More than half', 'Nearly every day'];

String _score(String testName, int total) {
  if (testName == 'Depression Test') {
    if (total <= 4) return 'Minimal Depression';
    if (total <= 9) return 'Mild Depression';
    if (total <= 14) return 'Moderate Depression';
    if (total <= 19) return 'Moderately Severe';
    return 'Severe Depression';
  } else if (testName == 'Stress Test') {
    if (total <= 13) return 'Low Stress';
    if (total <= 26) return 'Moderate Stress';
    return 'High Stress';
  } else {
    if (total <= 4) return 'Minimal Anxiety';
    if (total <= 9) return 'Mild Anxiety';
    if (total <= 14) return 'Moderate Anxiety';
    return 'Severe Anxiety';
  }
}

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});
  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  String? _selected;
  List<int?> _answers = [];
  Map<String, dynamic>? _result;
  bool _saving = false;
  Stream<QuerySnapshot>? _historyStream;

  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthProvider>().user!.uid;
    _historyStream = FirebaseFirestore.instance
        .collection('assessments')
        .where('userId', '==', uid)
        .snapshots();
  }

  void _start(String name) {
    final qs = (_tests[name]!['questions'] as List).length;
    setState(() { _selected = name; _answers = List.filled(qs, null); _result = null; });
  }

  Future<void> _submit() async {
    if (_answers.any((a) => a == null)) { MwSnackBar.show(context, 'Answer all questions'); return; }
    final total = _answers.fold<int>(0, (s, a) => s + (a ?? 0));
    final remarks = _score(_selected!, total);
    setState(() { _result = {'total': total, 'remarks': remarks}; _saving = true; });
    try {
      final uid = context.read<AuthProvider>().user!.uid;
      await FirebaseFirestore.instance.collection('assessments').add({
        'userId': uid,
        'Assessment_Type': _selected,
        'Remarks': remarks,
        'totalScore': total,
        'Date': DateTime.now().toIso8601String(),
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) { MwSnackBar.show(context, 'Failed to save result'); }
    if (mounted) setState(() => _saving = false);
  }

  void _reset() => setState(() { _selected = null; _result = null; _answers = []; });

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
      body: _result != null ? _resultView() : _selected != null ? _questionView() : _selectView(),
    );
  }

  Widget _selectView() {
    return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), children: [
      Text('Mental Health Assessment', style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: AppTheme.foreground)),
      const SizedBox(height: 4),
      Text('Self-assessment tools to understand your wellbeing', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.mutedFg)),
      const SizedBox(height: 20),
      ..._tests.entries.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: MwCard(
          onTap: () => _start(e.key),
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(12)),
              child: const Icon(CupertinoIcons.waveform, color: AppTheme.primary, size: 20)),
            const SizedBox(height: 12),
            Text(e.key, style: GoogleFonts.dmSerifDisplay(fontSize: 17, color: AppTheme.foreground)),
            const SizedBox(height: 2),
            Text(e.value['desc'] as String, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.mutedFg)),
            const SizedBox(height: 8),
            Text('${(e.value['questions'] as List).length} questions →', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
          ]),
        ),
      )),
      if (_historyStream != null) ...[
        const SizedBox(height: 12),
        Text('Your History', style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: AppTheme.foreground)),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: _historyStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Text('No history yet.', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.mutedFg));
            }

            final history = snapshot.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList();
            // Sort by date manually if timestamp is not available yet
            history.sort((a, b) => (b['Date'] ?? '').compareTo(a['Date'] ?? ''));

            return MwCard(padding: EdgeInsets.zero, child: Column(
              children: history.asMap().entries.map((e) {
                final h = e.value;
                return Column(children: [
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(h['Assessment_Type'] ?? '', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.foreground)),
                      Text(h['Remarks'] ?? '—', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.mutedFg)),
                    ])),
                    Text(_fmtDate(h['Date']), style: GoogleFonts.inter(fontSize: 12, color: AppTheme.mutedFg)),
                  ])),
                  if (e.key < history.length - 1) const Divider(height: 1, color: AppTheme.border),
                ]);
              }).toList(),
            ));
          },
        ),
      ],
    ]);
  }

  Widget _questionView() {
    final test = _tests[_selected!]!;
    final questions = test['questions'] as List;
    return Column(children: [
      // Progress bar
      LinearProgressIndicator(
        value: _answers.where((a) => a != null).length / questions.length,
        backgroundColor: AppTheme.muted, color: AppTheme.primary, minHeight: 3,
      ),
      Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_selected!, style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: AppTheme.foreground)),
            Text(test['desc'] as String, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.mutedFg)),
          ])),
          GestureDetector(onTap: _reset, child: Text('Cancel', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.mutedFg, decoration: TextDecoration.underline))),
        ]),
        const SizedBox(height: 8),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.muted, borderRadius: BorderRadius.circular(12)),
          child: Text('Over the last 2 weeks, how often have you been bothered by the following?',
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.mutedFg))),
        const SizedBox(height: 16),
        ...questions.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${e.key + 1}. ${e.value}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.foreground)),
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: _options.asMap().entries.map((o) {
              final sel = _answers[e.key] == o.key;
              return GestureDetector(
                onTap: () => setState(() => _answers[e.key] = o.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? AppTheme.primary : AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: sel ? AppTheme.primary : AppTheme.border),
                  ),
                  child: Text(o.value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppTheme.foreground)),
                ),
              );
            }).toList()),
          ]),
        )),
        const SizedBox(height: 8),
        MwButton(label: _saving ? 'Saving…' : 'Submit Assessment', onTap: _saving ? null : _submit, loading: _saving),
      ])),
    ]);
  }

  Widget _resultView() {
    return Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: MwCard(
      padding: const EdgeInsets.all(28),
      child: Column(children: [
        Container(width: 64, height: 64, decoration: BoxDecoration(color: AppTheme.primaryLight, shape: BoxShape.circle),
          child: const Icon(CupertinoIcons.checkmark_circle_fill, color: AppTheme.primary, size: 36)),
        const SizedBox(height: 16),
        Text('Assessment Complete', style: GoogleFonts.dmSerifDisplay(fontSize: 24, color: AppTheme.foreground)),
        const SizedBox(height: 4),
        Text('Your $_selected result', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.mutedFg)),
        const SizedBox(height: 20),
        Container(
          width: double.infinity, padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.primary.withOpacity(0.2))),
          child: Column(children: [
            Text('${_result!['total']}', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: AppTheme.primary)),
            Text('Total Score', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.mutedFg)),
            const SizedBox(height: 8),
            Text(_result!['remarks'], style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.foreground)),
          ]),
        ),
        const SizedBox(height: 12),
        Text('Results saved. Please consult a professional for diagnosis.', textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.mutedFg)),
        const SizedBox(height: 20),
        MwButton(label: 'Take Another Assessment', onTap: _reset),
      ]),
    )));
  }

  String _fmtDate(dynamic d) {
    if (d == null) return '';
    try {
      final dt = DateTime.parse(d.toString());
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
    } catch (_) { return ''; }
  }
}
