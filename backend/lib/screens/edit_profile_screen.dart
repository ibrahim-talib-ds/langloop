import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/app_icons.dart';
import '../widgets/home_widgets.dart';
import '../widgets/ui_kit.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _bio;
  late final TextEditingController _country;

  String _native = 'en';
  String _learning = 'en';
  String _level = 'beginner';
  bool _busy = false;
  String? _error;

  static const _langs = [
    ('en', 'English'),
    ('es', 'Spanish'),
    ('fr', 'French'),
    ('de', 'German'),
    ('ar', 'Arabic'),
    ('ru', 'Russian'),
    ('zh', 'Chinese'),
    ('tr', 'Turkish'),
  ];

  static const _levels = ['beginner', 'intermediate', 'advanced'];

  @override
  void initState() {
    super.initState();
    final u = AuthService.instance.user ?? {};
    _name = TextEditingController(text: (u['full_name'] ?? '').toString());
    _bio = TextEditingController(text: (u['bio'] ?? '').toString());
    _country =
        TextEditingController(text: (u['country'] ?? '').toString());
    _native = (u['native_language'] ?? 'en').toString();
    _learning = (u['learning_language'] ?? 'en').toString();
    _level = (u['level'] ?? 'beginner').toString();
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _country.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthService.instance.updateMe(
        fullName: _name.text.trim(),
        bio: _bio.text.trim(),
        country: _country.text.trim(),
        nativeLanguage: _native,
        learningLanguage: _learning,
        level: _level,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString());
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
        title: const Text('Edit profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: AvatarCircle(name: 'You', size: 84)),
              const SizedBox(height: 24),

              const FieldLabel('Full name'),
              const SizedBox(height: 8),
              TextField(
                controller: _name,
                style: TextStyle(color: c.text),
                decoration: const InputDecoration(hintText: 'Your name'),
              ),
              const SizedBox(height: 16),

              const FieldLabel('Bio'),
              const SizedBox(height: 8),
              TextField(
                controller: _bio,
                maxLines: 3,
                maxLength: 280,
                style: TextStyle(color: c.text),
                decoration: const InputDecoration(
                  hintText: 'Tell others about you…',
                ),
              ),
              const SizedBox(height: 8),

              const FieldLabel('Country'),
              const SizedBox(height: 8),
              TextField(
                controller: _country,
                style: TextStyle(color: c.text),
                decoration: const InputDecoration(hintText: 'e.g. Tajikistan'),
              ),
              const SizedBox(height: 20),

              const FieldLabel('Native language'),
              const SizedBox(height: 8),
              _dropdown(
                c,
                _native,
                _langs,
                (v) => setState(() => _native = v ?? 'en'),
              ),
              const SizedBox(height: 16),

              const FieldLabel('Learning language'),
              const SizedBox(height: 8),
              _dropdown(
                c,
                _learning,
                _langs,
                (v) => setState(() => _learning = v ?? 'en'),
              ),
              const SizedBox(height: 16),

              const FieldLabel('Level'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _levels
                    .map(
                      (l) => GestureDetector(
                        onTap: () => setState(() => _level = l),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: _level == l ? c.primary : c.surface,
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: _level == l ? c.primary : c.border,
                            ),
                          ),
                          child: Text(
                            l[0].toUpperCase() + l.substring(1),
                            style: TextStyle(
                              color: _level == l ? c.primaryFg : c.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 26),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(color: c.danger, fontSize: 13),
                  ),
                ),

              PillButton(
                label: 'Save changes',
                icon: AppIcons.check,
                busy: _busy,
                onTap: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdown(
    AppColors c,
    String value,
    List<(String, String)> options,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: c.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: c.surface,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: c.textSub),
          style: TextStyle(color: c.text, fontSize: 14),
          items: options
              .map(
                (o) => DropdownMenuItem(
                  value: o.$1,
                  child: Text(o.$2),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
