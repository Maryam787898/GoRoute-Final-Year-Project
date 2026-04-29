import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:goroute_app/services/notification_service.dart';
import 'package:goroute_app/main.dart' show navigatorKey;

const _kPrimary = Color(0xFF8B0000);

/// Real-time chat screen used by both Driver and Passenger.
/// Shows the message thread for a single support request and lets
/// the user send replies. Admin replies appear instantly via StreamBuilder.
class SupportChatScreen extends StatefulWidget {
  final String requestId;
  final String subject;

  const SupportChatScreen({
    super.key,
    required this.requestId,
    required this.subject,
  });

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  final _db = FirebaseFirestore.instance;
  final _user = FirebaseAuth.instance.currentUser!;

  // ── Lifecycle ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Ensure FCM token is saved whenever user opens a chat
    NotificationService().init(navigatorKey);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Message stream ────────────────────────────────────────────────────

  Stream<QuerySnapshot> get _messagesStream =>
      _db
          .collection('support_requests')
          .doc(widget.requestId)
          .collection('messages')
          .orderBy('createdAt')
          .snapshots();

  // ── Send message ──────────────────────────────────────────────────────

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    _msgCtrl.clear();

    try {
      // 1. Save message to Firestore
      await _db
          .collection('support_requests')
          .doc(widget.requestId)
          .collection('messages')
          .add({
            'senderId': _user.uid,
            'senderRole': 'user',
            'senderName': _user.displayName ?? _user.email ?? 'User',
            'text': text,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // 2. Update request status to 'open'
      await _db.collection('support_requests').doc(widget.requestId).update({
        'status': 'open',
      });

      // 3. Notify admin via FCM (fire-and-forget)
      _notifyAdmin();

      // 4. Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Finds the admin user and sends them an FCM push notification.
  Future<void> _notifyAdmin() async {
    try {
      final adminSnap =
          await _db
              .collection('users')
              .where('role', isEqualTo: 'admin')
              .limit(1)
              .get();
      if (adminSnap.docs.isEmpty) return;
      final adminUid = adminSnap.docs.first.id;
      await NotificationService.sendSupportReplyNotification(
        receiverUid: adminUid,
        requestId: widget.requestId,
        subject: widget.subject,
        senderName: _user.displayName ?? _user.email ?? 'User',
      );
    } catch (_) {
      // Notification failure must not block the chat
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Support Chat',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.subject,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          // Live status badge
          StreamBuilder<DocumentSnapshot>(
            stream:
                _db
                    .collection('support_requests')
                    .doc(widget.requestId)
                    .snapshots(),
            builder: (context, snap) {
              final status =
                  (snap.data?.data() as Map<String, dynamic>?)?['status']
                      as String? ??
                  'pending';
              Color c;
              switch (status) {
                case 'resolved':
                  c = Colors.green;
                  break;
                case 'open':
                  c = Colors.blue;
                  break;
                default:
                  c = Colors.orange;
              }
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: TextStyle(
                      color: c,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Message list ─────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 56,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Send a message to start the conversation',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                // Auto-scroll to bottom on new messages
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollCtrl.hasClients) {
                    _scrollCtrl.animateTo(
                      _scrollCtrl.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == _user.uid;
                    final isAdmin = data['senderRole'] == 'admin';
                    return _MessageBubble(
                      text: data['text'] as String? ?? '',
                      senderName:
                          data['senderName'] as String? ??
                          (isAdmin ? 'Admin' : 'You'),
                      isMe: isMe,
                      isAdmin: isAdmin,
                      timestamp: data['createdAt'],
                    );
                  },
                );
              },
            ),
          ),

          // ── Input bar ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a message…',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sending ? null : _send,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _kPrimary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _kPrimary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child:
                          _sending
                              ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 20,
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final String text;
  final String senderName;
  final bool isMe;
  final bool isAdmin;
  final dynamic timestamp;

  const _MessageBubble({
    required this.text,
    required this.senderName,
    required this.isMe,
    required this.isAdmin,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = _formatTime(timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Sender label
          Padding(
            padding: const EdgeInsets.only(bottom: 3, left: 4, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isAdmin) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Admin',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _kPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  isMe ? 'You' : senderName,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),

          // Bubble
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color:
                  isMe
                      ? _kPrimary
                      : isAdmin
                      ? Colors.blue.shade50
                      : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isMe ? Colors.white : Colors.black87,
                height: 1.4,
              ),
            ),
          ),

          // Timestamp
          if (timeStr.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
              child: Text(
                timeStr,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(dynamic ts) {
    if (ts == null) return '';
    try {
      final dt = (ts as dynamic).toDate() as DateTime;
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }
}
