import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:goroute_app/screens/shared/my_support_requests_screen.dart';

// ── App-wide constants ────────────────────────────────────────────────────────

const _kPrimary = Color(0xFF8B0000);
const _kSupportEmail = 'adminsupport@app.com';
const _kSupportPhone = '03187994734';

// ── Screen ────────────────────────────────────────────────────────────────────

class PassengerHelpSupportScreen extends StatelessWidget {
  const PassengerHelpSupportScreen({super.key});

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
          // ── Contact Support ──────────────────────────────────────────
          _SectionCard(
            icon: Icons.support_agent,
            iconColor: Colors.teal,
            title: 'Contact Support',
            children: [
              // Email tile
              _ActionTile(
                icon: Icons.email_outlined,
                iconBg: _kPrimary.withValues(alpha: 0.1),
                iconColor: _kPrimary,
                title: 'Email Support (Gmail)',
                subtitle: _kSupportEmail,
                subtitleColor: _kPrimary,
                onTap: () => _openEmail(context),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              // Phone tile
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

          // ── In-App Feedback ──────────────────────────────────────────
          _FeedbackCard(),

          const SizedBox(height: 16),

          // ── How to use the app ───────────────────────────────────────
          _SectionCard(
            icon: Icons.directions_bus,
            iconColor: _kPrimary,
            title: 'How to Use the App',
            children: const [
              _StepTile(
                number: '1',
                title: 'Login or Register',
                body:
                    'Choose your role (Passenger) and sign in with '
                    'email or Google.',
              ),
              _StepTile(
                number: '2',
                title: 'Select a Route',
                body: 'Go to the Routes tab to see all active routes.',
              ),
              _StepTile(
                number: '3',
                title: 'Track a Bus',
                body:
                    'Tap "Track Live" on any route to follow the bus '
                    'on the map in real time.',
              ),
              _StepTile(
                number: '4',
                title: 'Save a Route',
                body:
                    'Tap the bookmark icon on any route card to save '
                    'it for quick access.',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Managing routes ──────────────────────────────────────────
          _SectionCard(
            icon: Icons.bookmark_outline,
            iconColor: Colors.blue.shade700,
            title: 'Managing Routes',
            children: [
              _InfoRow(
                icon: Icons.visibility_outlined,
                title: 'View Active Routes',
                body: 'Routes tab → green "Active" badge.',
              ),
              _InfoRow(
                icon: Icons.bookmark_add_outlined,
                title: 'Save a Route',
                body: 'Tap the bookmark icon on any route card.',
              ),
              _InfoRow(
                icon: Icons.bookmarks_outlined,
                title: 'Access Saved Routes',
                body: 'Profile → Saved Routes.',
              ),
              _InfoRow(
                icon: Icons.delete_outline,
                title: 'Remove a Saved Route',
                body: 'Saved Routes → tap the trash icon.',
              ),
            ],
          ),

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
                issue: 'App not loading',
                fix: 'Check internet. Switch Wi-Fi/data, then restart.',
              ),
              _IssueTile(
                issue: 'Route not visible',
                fix: 'Routes appear only when a driver is online.',
              ),
              _IssueTile(
                issue: 'Map is blank',
                fix: 'Map tiles need internet. Check your connection.',
              ),
              _IssueTile(
                issue: 'Cannot sign in',
                fix: 'Check email/password. Use Forgot Password if needed.',
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Email launcher — opens Gmail directly, falls back to any email app ──

  static Future<void> _openEmail(BuildContext context) async {
    // Standard mailto: URI — Android routes this to Gmail if it is the
    // default email app, or shows a chooser if multiple apps are installed.
    // On Android 11+ the <queries> block in AndroidManifest.xml is required
    // for canLaunchUrl to work; we skip that check and call launchUrl directly
    // to avoid false negatives on devices where the query isn't pre-declared.
    final mailtoUri = Uri(
      scheme: 'mailto',
      path: _kSupportEmail,
      queryParameters: {
        'subject': 'GoRoute Support Request',
        'body': 'Hi GoRoute Support,\n\nI need help with:\n\n',
      },
    );

    try {
      final launched = await launchUrl(
        mailtoUri,
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

// ── Feedback card (StatefulWidget — owns form state) ─────────────────────────

class _FeedbackCard extends StatefulWidget {
  @override
  State<_FeedbackCard> createState() => _FeedbackCardState();
}

class _FeedbackCardState extends State<_FeedbackCard> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _sending = false;
  bool _done = false;

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
      final name = user?.displayName ?? user?.email ?? 'Passenger';
      final ts = FieldValue.serverTimestamp();
      final db = FirebaseFirestore.instance;

      // 1. Save feedback as a support request so chat works
      final docRef = await db.collection('support_requests').add({
        'senderId': uid,
        'senderRole': 'passenger',
        'senderName': name,
        'senderEmail': user?.email ?? '',
        'subject': _subjectCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
        'createdAt': ts,
        'status': 'pending',
        // legacy feedback fields
        'userId': uid,
        'userName': name,
        'userEmail': user?.email ?? '',
        'timestamp': ts,
      });

      // 2. Write admin notification (admin panel reads this in real-time)
      await db.collection('notifications').add({
        'title': 'New Feedback Received',
        'message':
            'New passenger feedback submitted by $name: '
            '"${_subjectCtrl.text.trim()}"',
        'type': 'passenger_feedback',
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
          content: Text('Feedback submission failed: $e'),
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
      title: 'Send Feedback',
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
        children: [
          // Subject
          TextFormField(
            controller: _subjectCtrl,
            decoration: InputDecoration(
              labelText: 'Subject',
              hintText: 'e.g. App issue, suggestion…',
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
              hintText: 'Describe your feedback in detail…',
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

          // Submit
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
              label: Text(_sending ? 'Sending…' : 'Submit Feedback'),
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
            'Feedback Submitted!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Thank you! Our team will review your feedback shortly.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: () => setState(() => _done = false),
            child: const Text('Send Another'),
          ),
        ],
      ),
    );
  }
}

// ── Reusable section card ─────────────────────────────────────────────────────

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
          // Header
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

// ── Clickable action tile (email / phone) ─────────────────────────────────────

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

// ── Numbered step tile ────────────────────────────────────────────────────────

class _StepTile extends StatelessWidget {
  final String number;
  final String title;
  final String body;

  const _StepTile({
    required this.number,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: _kPrimary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info row tile ─────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _InfoRow({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Issue tile ────────────────────────────────────────────────────────────────

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
