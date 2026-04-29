import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:goroute_app/screens/shared/my_support_requests_screen.dart';

const _kPrimary = Color(0xFF8B0000);
const _kSupportEmail = 'adminsupport@app.com';
const _kSupportPhone = '03187994734';

// ── Screen ────────────────────────────────────────────────────────────────────

class DriverHelpSupportScreen extends StatelessWidget {
  const DriverHelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Contact ──────────────────────────────────────────────────
          _SectionCard(
            icon: Icons.support_agent,
            iconColor: Colors.teal,
            title: 'Contact Support',
            children: [
              _ActionTile(
                icon: Icons.email_outlined,
                iconBg: _kPrimary.withValues(alpha: 0.1),
                iconColor: _kPrimary,
                title: 'Email Support',
                subtitle: _kSupportEmail,
                subtitleColor: _kPrimary,
                onTap: () => _openEmail(context),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _ActionTile(
                icon: Icons.phone_outlined,
                iconBg: Colors.green.withValues(alpha: 0.1),
                iconColor: Colors.green.shade700,
                title: 'Phone Support',
                subtitle: _kSupportPhone,
                subtitleColor: Colors.green.shade700,
                onTap: () => _openDialer(context),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── My support requests ──────────────────────────────────────
          _SectionCard(
            icon: Icons.inbox_outlined,
            iconColor: Colors.indigo,
            title: 'My Support Requests',
            children: [
              _ActionTile(
                icon: Icons.chat_bubble_outline,
                iconBg: Colors.indigo.withValues(alpha: 0.1),
                iconColor: Colors.indigo,
                title: 'View My Requests',
                subtitle: 'Track status & chat with admin',
                subtitleColor: Colors.indigo,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MySupportRequestsScreen(),
                      ),
                    ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Feedback form ────────────────────────────────────────────
          _FeedbackCard(),

          const SizedBox(height: 16),

          // ── Common issues ────────────────────────────────────────────
          _SectionCard(
            icon: Icons.warning_amber_outlined,
            iconColor: Colors.orange,
            title: 'Common Issues',
            children: const [
              _IssueTile(
                issue: 'Location not updating',
                fix: 'Enable GPS: Settings → Location → Turn On.',
              ),
              _IssueTile(
                issue: 'Route not activating',
                fix: 'Check internet connection and try again.',
              ),
              _IssueTile(
                issue: 'App not loading',
                fix: 'Check internet. Switch Wi-Fi/data, then restart.',
              ),
              _IssueTile(
                issue: 'Cannot sign in',
                fix: 'Check email/password. Contact admin if locked out.',
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Email launcher ────────────────────────────────────────────────────

  static Future<void> _openEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _kSupportEmail,
      queryParameters: {
        'subject': 'GoRoute Driver Support Request',
        'body': 'Hi GoRoute Support,\n\nI need help with:\n\n',
      },
    );
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        _snack(
          context,
          'Unable to open email app. Please email $_kSupportEmail manually.',
          isError: true,
        );
      }
    } catch (_) {
      if (context.mounted) {
        _snack(
          context,
          'Unable to open Gmail. Please email $_kSupportEmail manually.',
          isError: true,
        );
      }
    }
  }

  // ── Phone dialer launcher ─────────────────────────────────────────────

  static Future<void> _openDialer(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: _kSupportPhone);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        _snack(
          context,
          'Unable to open dialer. Please call $_kSupportPhone manually.',
          isError: true,
        );
      }
    } catch (_) {
      if (context.mounted) {
        _snack(
          context,
          'Unable to make call. Please call $_kSupportPhone manually.',
          isError: true,
        );
      }
    }
  }

  static void _snack(BuildContext context, String msg, {bool isError = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green,
      ),
    );
  }
}

// ── Feedback form card ────────────────────────────────────────────────────────

class _FeedbackCard extends StatefulWidget {
  @override
  State<_FeedbackCard> createState() => _FeedbackCardState();
}

class _FeedbackCardState extends State<_FeedbackCard> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _category = 'Technical Issue';
  bool _sending = false;
  bool _done = false;

  static const _categories = [
    'Technical Issue',
    'Route Issue',
    'General Feedback',
    'Other',
  ];

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? 'anonymous';
      final name = user?.displayName ?? user?.email ?? 'Driver';
      final ts = FieldValue.serverTimestamp();
      final db = FirebaseFirestore.instance;

      // 1. Save support request — use senderId so chat screen can query it
      final docRef = await db.collection('support_requests').add({
        'senderId': uid,
        'senderRole': 'driver',
        'senderName': name,
        'senderEmail': user?.email ?? '',
        'subject': _subjectCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
        'category': _category,
        'createdAt': ts,
        'status': 'pending',
        // legacy fields kept for backward compat
        'driverId': uid,
        'driverName': name,
        'driverEmail': user?.email ?? '',
        'timestamp': ts,
        'role': 'driver',
      });

      // 2. Admin notification
      await db.collection('notifications').add({
        'title': 'New Driver Support Request',
        'message':
            'Driver $name submitted a support request: '
            '"${_subjectCtrl.text.trim()}" [$_category]',
        'type': 'driver_support',
        'userId': uid,
        'requestId': docRef.id,
        'createdAt': ts,
      });

      if (!mounted) return;
      _subjectCtrl.clear();
      _messageCtrl.clear();
      setState(() {
        _done = true;
        _sending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Support request failed: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.feedback_outlined,
      iconColor: Colors.deepPurple,
      title: 'Submit Support Request',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: _done ? _successBanner() : _form(),
        ),
      ],
    );
  }

  Widget _form() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category dropdown
          DropdownButtonFormField<String>(
            value: _category,
            decoration: InputDecoration(
              labelText: 'Category',
              prefixIcon: const Icon(Icons.category_outlined, color: _kPrimary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kPrimary, width: 2),
              ),
            ),
            items:
                _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
            onChanged: (v) => setState(() => _category = v ?? _category),
          ),
          const SizedBox(height: 12),

          // Subject
          TextFormField(
            controller: _subjectCtrl,
            decoration: InputDecoration(
              labelText: 'Subject',
              hintText: 'Brief description of your issue',
              prefixIcon: const Icon(Icons.subject, color: _kPrimary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kPrimary, width: 2),
              ),
            ),
            validator:
                (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Please enter a subject'
                        : null,
          ),
          const SizedBox(height: 12),

          // Message
          TextFormField(
            controller: _messageCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Message',
              hintText: 'Describe your issue in detail…',
              alignLabelWithHint: true,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 60),
                child: Icon(Icons.message_outlined, color: _kPrimary),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kPrimary, width: 2),
              ),
            ),
            validator:
                (v) =>
                    (v == null || v.trim().length < 10)
                        ? 'Message must be at least 10 characters'
                        : null,
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _sending ? null : _submit,
              icon:
                  _sending
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Icon(Icons.send),
              label: Text(_sending ? 'Sending…' : 'Submit Request'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _successBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 44),
          const SizedBox(height: 10),
          const Text(
            'Request Submitted!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your support request has been sent. '
            'Admin will review it shortly.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: () => setState(() => _done = false),
            child: const Text('Submit Another'),
          ),
        ],
      ),
    );
  }
}

// ── Ticket history card ───────────────────────────────────────────────────────

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color subtitleColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.subtitleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: iconBg,
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: subtitleColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}

class _IssueTile extends StatelessWidget {
  final String issue;
  final String fix;

  const _IssueTile({required this.issue, required this.fix});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  issue,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              '✓ $fix',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
