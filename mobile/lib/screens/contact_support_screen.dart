import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/app_icons.dart';

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  String _category = 'bug';
  bool _busy = false;

  static const _categories = <(String, String)>[
    ('bug', 'Bug or technical issue'),
    ('abuse', 'Report abuse'),
    ('billing', 'Billing question'),
    ('other', 'Something else'),
  ];

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_subject.text.trim().isEmpty || _message.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill both subject and message'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.colors.surface,
        ),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await ApiClient.instance.post('/support/', body: {
        'subject': _subject.text.trim(),
        'message': _message.text.trim(),
        'category': _category,
      });
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Message sent — we\'ll reply within 48h'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.colors.surface,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.colors.surface,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(AppIcons.back, color: c.text),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Contact support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'How can we help?',
            style: TextStyle(
              color: c.text,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Our team replies within 48 hours.',
            style: TextStyle(color: c.textSub, fontSize: 13),
          ),
          const SizedBox(height: 24),

          Text(
            'Category',
            style: TextStyle(
              color: c.text,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              final selected = _category == cat.$1;
              return GestureDetector(
                onTap: () => setState(() => _category = cat.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? c.primary : c.surface,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: selected ? c.primary : c.border,
                    ),
                  ),
                  child: Text(
                    cat.$2,
                    style: TextStyle(
                      color: selected ? c.primaryFg : c.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _subject,
            style: TextStyle(color: c.text),
            decoration: const InputDecoration(hintText: 'Subject'),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _message,
            maxLines: 6,
            maxLength: 2000,
            style: TextStyle(color: c.text),
            decoration: const InputDecoration(
              hintText: 'Describe your issue…',
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: Material(
              color: c.primary,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                onTap: _busy ? null : _submit,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: _busy
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: c.primaryFg,
                            ),
                          )
                        : Text(
                            'Send message',
                            style: TextStyle(
                              color: c.primaryFg,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
