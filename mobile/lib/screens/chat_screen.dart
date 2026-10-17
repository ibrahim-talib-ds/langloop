import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/app_icons.dart';
import '../widgets/home_widgets.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.otherId,
    required this.otherName,
  });

  final String otherId;
  final String otherName;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<dynamic> _messages = [];
  bool _loading = true;
  Timer? _poller;
  final _myId = AuthService.instance.user?['id'] as String?;

  @override
  void initState() {
    super.initState();
    _load();
    _poller = Timer.periodic(const Duration(seconds: 3), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _poller?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    try {
      final res = await ApiClient.instance.get('/messages/${widget.otherId}');
      final list = res['data'] is List ? res['data'] as List : <dynamic>[];
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(list);
        _loading = false;
      });
    } catch (_) {
      if (!silent && mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    try {
      await ApiClient.instance.post('/messages/${widget.otherId}', body: {
        'body': text,
      });
      await _load();
      await Future.delayed(const Duration(milliseconds: 80));
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.colors.surface,
        ),
      );
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
        title: Row(
          children: [
            AvatarCircle(name: widget.otherName, size: 34, online: true),
            const SizedBox(width: 10),
            Text(
              widget.otherName,
              style: TextStyle(
                color: c.text,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: c.primary))
                : _messages.isEmpty
                    ? _emptyState(c)
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final m = _messages[i];
                          final mine = m['sender_id'] == _myId;
                          return _bubble(c, m['body'].toString(), mine);
                        },
                      ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: c.bg,
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(color: c.text),
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Type a message…',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: c.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _send,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: Icon(AppIcons.send, color: c.primaryFg),
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

  Widget _emptyState(AppColors c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 42, color: c.textSub),
            const SizedBox(height: 16),
            Text(
              'Say hi to ${widget.otherName}!',
              style: TextStyle(
                color: c.text,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Messages are private between you two.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSub, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(AppColors c, String text, bool mine) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: mine ? c.primary : c.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: mine ? c.primary : c.border),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: mine ? c.primaryFg : c.text,
            fontSize: 14,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}
