import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/mw_card.dart';
import '../widgets/mw_button.dart';

const _focusColors = {
  'Stress':      Color(0xFFDBEAFE),
  'Anxiety':     Color(0xFFEDE9FE),
  'Depression':  Color(0xFFFFE4E6),
  'Mindfulness': Color(0xFFDCFCE7),
};
const _focusTextColors = {
  'Stress':      Color(0xFF1D4ED8),
  'Anxiety':     Color(0xFF7C3AED),
  'Depression':  Color(0xFFE11D48),
  'Mindfulness': Color(0xFF16A34A),
};

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});
  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  Stream<QuerySnapshot>? _stream;
  String? _actionId;

  @override
  void initState() {
    super.initState();
    _stream = FirebaseFirestore.instance.collection('groups').snapshots();
  }

  Future<void> _join(String groupId) async {
    setState(() => _actionId = groupId);
    try {
      final uid = context.read<AuthProvider>().user!.uid;
      await FirebaseFirestore.instance.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayUnion([uid])
      });
    } catch (_) { MwSnackBar.show(context, 'Failed to join group'); }
    if (mounted) setState(() => _actionId = null);
  }

  Future<void> _leave(String groupId) async {
    setState(() => _actionId = groupId);
    try {
      final uid = context.read<AuthProvider>().user!.uid;
      await FirebaseFirestore.instance.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayRemove([uid])
      });
    } catch (_) { MwSnackBar.show(context, 'Failed to leave group'); }
    if (mounted) setState(() => _actionId = null);
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().user!.uid;

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
      body: StreamBuilder<QuerySnapshot>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
             return Center(child: Text('No support groups found.', style: GoogleFonts.inter(color: AppTheme.mutedFg)));
          }

          final groups = snapshot.data!.docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            final members = List<String>.from(data['members'] ?? []);
            return {
              'Group_ID': d.id,
              ...data,
              'member_count': members.length,
              'joined': members.contains(uid) ? 1 : 0,
            };
          }).toList();

          final my = groups.where((g) => g['joined'] == 1).toList();
          final other = groups.where((g) => g['joined'] == 0).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              if (my.isNotEmpty) ...[
                Row(children: [
                  Text('Your Groups', style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: AppTheme.foreground)),
                  const SizedBox(width: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(10)),
                    child: Text('${my.length}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary))),
                ]),
                const SizedBox(height: 12),
                ...my.map((g) => _GroupCard(g: g, joined: true, loading: _actionId == g['Group_ID'], onAction: () => _leave(g['Group_ID']))),
                const SizedBox(height: 24),
              ],
              if (other.isNotEmpty) ...[
                Text('Available Groups', style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: AppTheme.foreground)),
                const SizedBox(height: 12),
                ...other.map((g) => _GroupCard(g: g, joined: false, loading: _actionId == g['Group_ID'], onAction: () => _join(g['Group_ID']))),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final Map<String, dynamic> g;
  final bool joined;
  final bool loading;
  final VoidCallback onAction;
  const _GroupCard({required this.g, required this.joined, required this.loading, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final focus = g['Focus_Area'] ?? '';
    final bgColor = _focusColors[focus] ?? const Color(0xFFF3F4F6);
    final textColor = _focusTextColors[focus] ?? const Color(0xFF4B5563);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MwCard(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(
              color: joined ? AppTheme.primaryLight : AppTheme.muted, borderRadius: BorderRadius.circular(12)),
              child: Icon(CupertinoIcons.person_3_fill, size: 18, color: joined ? AppTheme.primary : AppTheme.mutedFg)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(g['Group_Name'] ?? '', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
              const SizedBox(height: 3),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                child: Text(focus, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: textColor))),
            ])),
            if (joined) Icon(CupertinoIcons.checkmark_circle_fill, color: AppTheme.primary, size: 20),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Icon(CupertinoIcons.person_2, size: 13, color: AppTheme.mutedFg), const SizedBox(width: 4),
            Text('${g['member_count'] ?? 0} members', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.mutedFg)),
          ]),
          const SizedBox(height: 14),
          if (joined) ...[
            Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFBBF7D0))),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(CupertinoIcons.checkmark_circle_fill, color: Color(0xFF16A34A), size: 14),
                const SizedBox(width: 6),
                Text('Joined', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF16A34A))),
              ])),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, height: 40, child: OutlinedButton(
              onPressed: loading ? null : onAction,
              style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: const BorderSide(color: AppTheme.border)),
              child: Text(loading ? 'Leaving…' : 'Leave Group', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.mutedFg)),
            )),
          ] else
            MwButton(label: loading ? 'Joining…' : 'Join Group', onTap: loading ? null : onAction, loading: loading),
        ]),
      ),
    );
  }
}
