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
import '../widgets/mw_text_field.dart';

const _presets = [300, 500, 700, 1000, 1500];
const _modes = [
  {'id': 'UPI',  'label': 'UPI',  'icon': CupertinoIcons.device_phone_portrait, 'desc': 'Google Pay, PhonePe'},
  {'id': 'Card', 'label': 'Card', 'icon': CupertinoIcons.creditcard,            'desc': 'Debit / Credit card'},
  {'id': 'Cash', 'label': 'Cash', 'icon': CupertinoIcons.money_dollar,          'desc': 'Pay at the clinic'},
];

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Stream<QuerySnapshot>? _historyStream;
  final _amountCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();
  final _cardCtrl = TextEditingController();
  String _mode = 'UPI';
  bool _paying = false;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthProvider>().user!.uid;
    _historyStream = FirebaseFirestore.instance
        .collection('payments')
        .where('userId', '==', uid)
        .snapshots();
  }

  @override
  void dispose() { _amountCtrl.dispose(); _upiCtrl.dispose(); _cardCtrl.dispose(); super.dispose(); }

  Future<void> _pay() async {
    final amt = double.tryParse(_amountCtrl.text);
    if (amt == null || amt <= 0) { MwSnackBar.show(context, 'Enter a valid amount'); return; }
    if (_mode == 'UPI' && _upiCtrl.text.trim().isEmpty) { MwSnackBar.show(context, 'Enter UPI ID'); return; }
    if (_mode == 'Card' && _cardCtrl.text.replaceAll(' ', '').length < 12) { MwSnackBar.show(context, 'Enter valid card number'); return; }
    setState(() => _paying = true);
    try {
      final uid = context.read<AuthProvider>().user!.uid;
      await FirebaseFirestore.instance.collection('payments').add({
        'userId': uid,
        'Amount': amt,
        'Payment_Mode': _mode,
        'Status': 'Completed',
        'Date': DateTime.now().toIso8601String(),
        'timestamp': FieldValue.serverTimestamp(),
      });
      setState(() { _success = true; _amountCtrl.clear(); _upiCtrl.clear(); _cardCtrl.clear(); });
      Future.delayed(const Duration(seconds: 3), () { if (mounted) setState(() => _success = false); });
    } catch (_) { MwSnackBar.show(context, 'Payment failed'); }
    if (mounted) setState(() => _paying = false);
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
        leading: IconButton(icon: const Icon(CupertinoIcons.back), onPressed: () => context.go('/dashboard')),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _historyStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }
          final history = snapshot.hasData 
              ? snapshot.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList()
              : <Map<String, dynamic>>[];
          
          history.sort((a, b) => (b['Date'] ?? '').compareTo(a['Date'] ?? ''));

          final total = history.where((p) => p['Status'] == 'Completed').fold<double>(0, (s, p) => s + (double.tryParse('${p['Amount']}') ?? 0));

          return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), children: [
            if (history.isNotEmpty)
              Wrap(spacing: 8, children: [
                _Pill(icon: Icons.currency_rupee, label: '₹${total.toStringAsFixed(0)} paid total', color: AppTheme.primaryLight, textColor: AppTheme.primary),
                _Pill(icon: CupertinoIcons.creditcard, label: '${history.length} transaction${history.length != 1 ? 's' : ''}', color: AppTheme.muted, textColor: AppTheme.mutedFg),
              ]),
            const SizedBox(height: 16),

            MwCard(
              padding: const EdgeInsets.all(20),
              child: _success ? _successView() : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Make a Payment', style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: AppTheme.foreground)),
                const SizedBox(height: 16),
                Text('AMOUNT (₹)', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppTheme.mutedFg)),
                const SizedBox(height: 8),
                MwTextField(controller: _amountCtrl, hint: '0.00', keyboardType: TextInputType.number,
                  prefix: Padding(padding: const EdgeInsets.only(left: 14), child: Text('₹', style: GoogleFonts.inter(fontSize: 16, color: AppTheme.mutedFg)))),
                const SizedBox(height: 10),
                Wrap(spacing: 6, children: _presets.map((a) {
                  final sel = _amountCtrl.text == '$a';
                  return GestureDetector(
                    onTap: () => setState(() => _amountCtrl.text = '$a'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? AppTheme.primary : AppTheme.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: sel ? AppTheme.primary : AppTheme.border),
                      ),
                      child: Text('₹$a', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppTheme.mutedFg)),
                    ),
                  );
                }).toList()),
                const SizedBox(height: 16),
                Text('PAYMENT MODE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppTheme.mutedFg)),
                const SizedBox(height: 8),
                Row(children: (_modes).map((m) {
                  final sel = _mode == m['id'];
                  return Expanded(child: Padding(padding: const EdgeInsets.only(right: 6), child: GestureDetector(
                    onTap: () => setState(() => _mode = m['id'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: sel ? AppTheme.primary.withOpacity(0.08) : AppTheme.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: sel ? AppTheme.primary : AppTheme.border),
                      ),
                      child: Column(children: [
                        Icon(m['icon'] as IconData, size: 20, color: sel ? AppTheme.primary : AppTheme.mutedFg),
                        const SizedBox(height: 4),
                        Text(m['label'] as String, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? AppTheme.primary : AppTheme.foreground)),
                        Text(m['desc'] as String, style: GoogleFonts.inter(fontSize: 9, color: AppTheme.mutedFg)),
                      ]),
                    ),
                  )));
                }).toList()),
                if (_mode == 'UPI') ...[
                  const SizedBox(height: 12),
                  Text('UPI ID', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppTheme.mutedFg)),
                  const SizedBox(height: 6),
                  MwTextField(controller: _upiCtrl, hint: 'yourname@upi'),
                ],
                if (_mode == 'Card') ...[
                  const SizedBox(height: 12),
                  Text('CARD NUMBER', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppTheme.mutedFg)),
                  const SizedBox(height: 6),
                  MwTextField(controller: _cardCtrl, hint: '1234 5678 9012 3456', keyboardType: TextInputType.number),
                ],
                const SizedBox(height: 20),
                MwButton(label: _paying ? 'Processing…' : 'Pay ${_amountCtrl.text.isNotEmpty ? "₹${_amountCtrl.text}" : "Now"}', onTap: _paying ? null : _pay, loading: _paying),
                const SizedBox(height: 8),
                Center(child: Text('🔒 Demo — no real money charged', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.mutedFg))),
              ]),
            ),
            const SizedBox(height: 20),

            Text('Transaction History', style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: AppTheme.foreground)),
            const SizedBox(height: 12),
            if (history.isEmpty)
              MwCard(child: Padding(padding: const EdgeInsets.symmetric(vertical: 32), child: Column(children: [
                Icon(CupertinoIcons.creditcard, size: 36, color: AppTheme.mutedFg),
                const SizedBox(height: 8),
                Text('No transactions yet', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.mutedFg)),
              ])))
            else
              MwCard(padding: EdgeInsets.zero, child: Column(
                children: history.asMap().entries.map((e) {
                  final p = e.value;
                  final status = p['Status'] ?? '';
                  final statusColor = status == 'Completed' ? const Color(0xFF059669) : status == 'Pending' ? const Color(0xFFD97706) : AppTheme.destructive;
                  final statusBg = status == 'Completed' ? const Color(0xFFECFDF5) : status == 'Pending' ? const Color(0xFFFFFBEB) : const Color(0xFFFEF2F2);
                  return Column(children: [
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
                          child: Text(status, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor))),
                        const SizedBox(height: 4),
                        Text('${p['Payment_Mode']}${p['therapist_name'] != null ? ' · ${p['therapist_name']}' : ''}',
                            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.mutedFg)),
                      ])),
                      Text('₹${double.tryParse('${p['Amount']}')?.toStringAsFixed(0) ?? p['Amount']}',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
                    ])),
                    if (e.key < history.length - 1) const Divider(height: 1, color: AppTheme.border),
                  ]);
                }).toList(),
              )),
          ]);
        },
      ),
    );
  }

  Widget _successView() => Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Column(children: [
    Container(width: 64, height: 64, decoration: const BoxDecoration(color: Color(0xFFD1FAE5), shape: BoxShape.circle),
      child: const Icon(CupertinoIcons.checkmark_circle_fill, color: Color(0xFF059669), size: 36)),
    const SizedBox(height: 12),
    Text('Payment Successful!', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.foreground)),
    const SizedBox(height: 4),
    Text('Transaction recorded.', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.mutedFg)),
  ]));
}

class _Pill extends StatelessWidget {
  final IconData icon; final String label; final Color color; final Color textColor;
  const _Pill({required this.icon, required this.label, required this.color, required this.textColor});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: textColor), const SizedBox(width: 6),
      Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
    ]),
  );
}
