import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String? _activeChatId;
  Map<String, dynamic>? _activeChatData;
  final _inputCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() { _inputCtrl.dispose(); super.dispose(); }

  void _openChat(Map<String, dynamic> chat) {
    setState(() {
      _activeChatId = chat['Chat_ID'];
      _activeChatData = chat;
      _inputCtrl.clear();
    });
  }

  void _goBack() {
    setState(() {
      _activeChatId = null;
      _activeChatData = null;
    });
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _activeChatId == null || _sending) return;
    _inputCtrl.clear();
    setState(() => _sending = true);
    try {
      final chatId = _activeChatId!;
      await FirebaseFirestore.instance.collection('messages').add({
        'chatId': chatId,
        'Message_Text': text,
        'Sender_Type': 'user',
        'timestamp': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
        'last_message': text,
        'last_updated': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
    if (mounted) setState(() => _sending = false);
  }

  String _initials(String name) => name.toString().split(' ').where((s) => s.isNotEmpty).map((s) => s[0].toUpperCase()).take(2).join();

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().user!.uid;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: _activeChatId != null
            ? Row(children: [
                CircleAvatar(radius: 16, backgroundColor: AppTheme.primaryLight,
                  child: Text(_initials(_activeChatData?['therapist_name'] ?? ''), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary))),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_activeChatData?['therapist_name'] ?? '', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.foreground)),
                  Text(_activeChatData?['Specialization'] ?? '', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.mutedFg)),
                ]),
              ])
            : Row(
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
        leading: _activeChatId != null
            ? IconButton(icon: const Icon(CupertinoIcons.back), onPressed: _goBack)
            : null,
      ),
      body: _activeChatId != null
          ? _chatView(_activeChatId!)
          : _listView(uid),
    );
  }

  Widget _listView(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('chats').where('userId', '==', uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 60, height: 60, decoration: BoxDecoration(color: AppTheme.primaryLight, shape: BoxShape.circle),
              child: const Icon(CupertinoIcons.chat_bubble_2, color: AppTheme.primary, size: 28)),
            const SizedBox(height: 16),
            Text('No conversations yet', style: GoogleFonts.inter(fontSize: 14, color: AppTheme.mutedFg)),
            const SizedBox(height: 8),
            GestureDetector(onTap: () => context.go('/therapists'),
              child: Text('Book a session to start chatting →', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary))),
          ])));
        }

        final chats = snapshot.data!.docs.map((d) => {'Chat_ID': d.id, ...d.data() as Map<String, dynamic>}).toList();

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: chats.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 72, color: AppTheme.border),
          itemBuilder: (_, i) {
            final c = chats[i];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: CircleAvatar(radius: 22, backgroundColor: AppTheme.primaryLight,
                child: Text(_initials(c['therapist_name'] ?? ''), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primary))),
              title: Text(c['therapist_name'] ?? '', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.foreground)),
              subtitle: Text(c['last_message'] ?? c['Specialization'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.mutedFg)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () => _openChat(c),
            );
          },
        );
      },
    );
  }

  Widget _chatView(String chatId) {
    return Column(children: [
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('messages').where('chatId', '==', chatId).orderBy('timestamp', descending: false).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No messages yet. Say hello!', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.mutedFg)));
            }

            final messages = snapshot.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList();

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              itemCount: messages.length,
              itemBuilder: (_, i) {
                final m = messages[i];
                final isUser = m['Sender_Type'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isUser ? AppTheme.primary : AppTheme.muted,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isUser ? 18 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 18),
                      ),
                      border: isUser ? null : Border.all(color: AppTheme.border),
                    ),
                    child: Text(m['Message_Text'] ?? '',
                        style: GoogleFonts.inter(fontSize: 14, color: isUser ? Colors.white : AppTheme.foreground, height: 1.4)),
                  ),
                );
              },
            );
          },
        ),
      ),
      // Input
      Container(
        padding: EdgeInsets.fromLTRB(12, 8, 8, MediaQuery.of(context).viewPadding.bottom + 8),
        decoration: const BoxDecoration(color: AppTheme.cardColor, border: Border(top: BorderSide(color: AppTheme.border, width: 0.5))),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              maxLines: 4, minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              style: GoogleFonts.inter(fontSize: 14, color: AppTheme.foreground),
              decoration: InputDecoration(
                hintText: 'Type a message…',
                hintStyle: GoogleFonts.inter(fontSize: 14, color: AppTheme.mutedFg),
                filled: true, fillColor: AppTheme.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppTheme.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppTheme.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(14)),
              child: const Icon(CupertinoIcons.arrow_up, color: Colors.white, size: 18),
            ),
          ),
        ]),
      ),
    ]);
  }
}
