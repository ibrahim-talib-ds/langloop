import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/countries.dart';
import '../data/languages.dart';
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

  String? _country; // ISO code, or null
  String _native = 'en';
  String _learning = 'en';
  String _level = 'beginner';
  bool _busy = false;
  String? _error;
  final _picker = ImagePicker();
  String? _localAvatarPath;

  static const _levels = ['beginner', 'intermediate', 'advanced'];

  @override
  void initState() {
    super.initState();
    final u = AuthService.instance.user ?? {};
    _name = TextEditingController(text: (u['full_name'] ?? '').toString());
    _bio = TextEditingController(text: (u['bio'] ?? '').toString());

    final savedCountry = (u['country'] ?? '').toString();
    if (savedCountry.isNotEmpty) {
      _country = savedCountry;
    } else {
      // Auto-fill from geo detection
      final detected = AuthService.instance.detectedCountry;
      if (detected != null && detected.isNotEmpty) {
        _country = detected;
        // Also try to set a sensible native language
        final countryObj = findCountry(detected);
        if (countryObj != null) {
          _native = countryObj.defaultLanguage;
        }
      }
    }

    _native = (u['native_language'] ?? _native).toString();
    _learning = (u['learning_language'] ?? 'en').toString();
    _level = (u['level'] ?? 'beginner').toString();
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _localAvatarPath = picked.path);
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Upload avatar first if picked
      if (_localAvatarPath != null) {
        await AuthService.instance.uploadAvatar(_localAvatarPath!);
      }
      await AuthService.instance.updateMe(
        fullName: _name.text.trim(),
        bio: _bio.text.trim(),
        country: _country,
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
              // ─── Avatar picker ───
              Center(
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: Stack(
                    children: [
                      AvatarCircle(
                        name: _name.text.isEmpty ? 'You' : _name.text,
                        size: 96,
                        imageUrl: _localAvatarPath,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: c.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: c.bg, width: 2),
                          ),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            size: 14,
                            color: c.primaryFg,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _localAvatarPath == null
                      ? 'Tap to change photo'
                      : 'Photo selected',
                  style: TextStyle(color: c.textSub, fontSize: 12),
                ),
              ),
              const SizedBox(height: 24),

              // ─── Name ───
              const FieldLabel('Full name'),
              const SizedBox(height: 8),
              TextField(
                controller: _name,
                style: TextStyle(color: c.text),
                decoration: const InputDecoration(hintText: 'Your name'),
              ),
              const SizedBox(height: 16),

              // ─── Bio ───
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

              // ─── Country (searchable, with flags) ───
              const FieldLabel('Country'),
              const SizedBox(height: 8),
              _countryPicker(c),
              const SizedBox(height: 16),

              // ─── Native language ───
              const FieldLabel('Native language'),
              const SizedBox(height: 8),
              _languagePicker(c, _native, (v) => setState(() => _native = v)),
              const SizedBox(height: 16),

              // ─── Learning language ───
              const FieldLabel('Learning language'),
              const SizedBox(height: 8),
              _languagePicker(
                c,
                _learning,
                (v) => setState(() => _learning = v),
              ),
              const SizedBox(height: 16),

              // ─── Level ───
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

  // ─── Country picker with search + flag ───
  Widget _countryPicker(AppColors c) {
    final selected = _country != null ? findCountry(_country!) : null;
    return GestureDetector(
      onTap: () async {
        final pick = await showModalBottomSheet<Country>(
          context: context,
          backgroundColor: c.surface,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => _CountrySheet(countries: kCountries),
        );
        if (pick != null) setState(() => _country = pick.code);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Text(
              selected?.flag ?? '🌍',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selected?.name ?? 'Select country',
                style: TextStyle(
                  color: selected == null ? c.textSub : c.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: c.textSub),
          ],
        ),
      ),
    );
  }

  // ─── Language picker with search + flag ───
  Widget _languagePicker(
    AppColors c,
    String value,
    ValueChanged<String> onChanged,
  ) {
    final selected = findLanguage(value);
    return GestureDetector(
      onTap: () async {
        final pick = await showModalBottomSheet<Language>(
          context: context,
          backgroundColor: c.surface,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => _LanguageSheet(languages: kLanguages),
        );
        if (pick != null) onChanged(pick.code);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Text(
              selected?.flag ?? '🌍',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selected == null
                    ? value.toUpperCase()
                    : '${selected.name} · ${selected.nativeName}',
                style: TextStyle(
                  color: c.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: c.textSub),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Country sheet (searchable)
// ─────────────────────────────────────────────
class _CountrySheet extends StatefulWidget {
  const _CountrySheet({required this.countries});
  final List<Country> countries;

  @override
  State<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<_CountrySheet> {
  final _search = TextEditingController();
  List<Country> _list = [];

  @override
  void initState() {
    super.initState();
    _list = widget.countries;
    _search.addListener(() {
      final q = _search.text.toLowerCase();
      setState(() {
        _list = widget.countries
            .where((c) => c.name.toLowerCase().contains(q))
            .toList();
      });
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _search,
                style: TextStyle(color: c.text),
                decoration: InputDecoration(
                  hintText: 'Search country',
                  prefixIcon:
                      Icon(Icons.search_rounded, color: c.textSub, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _list.length,
                itemBuilder: (_, i) {
                  final country = _list[i];
                  return ListTile(
                    leading: Text(
                      country.flag,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      country.name,
                      style: TextStyle(
                        color: c.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () => Navigator.pop(context, country),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Language sheet (searchable)
// ─────────────────────────────────────────────
class _LanguageSheet extends StatefulWidget {
  const _LanguageSheet({required this.languages});
  final List<Language> languages;

  @override
  State<_LanguageSheet> createState() => _LanguageSheetState();
}

class _LanguageSheetState extends State<_LanguageSheet> {
  final _search = TextEditingController();
  List<Language> _list = [];

  @override
  void initState() {
    super.initState();
    _list = widget.languages;
    _search.addListener(() {
      final q = _search.text.toLowerCase();
      setState(() {
        _list = widget.languages
            .where((l) =>
                l.name.toLowerCase().contains(q) ||
                l.nativeName.toLowerCase().contains(q))
            .toList();
      });
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _search,
                style: TextStyle(color: c.text),
                decoration: InputDecoration(
                  hintText: 'Search language',
                  prefixIcon:
                      Icon(Icons.search_rounded, color: c.textSub, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _list.length,
                itemBuilder: (_, i) {
                  final lang = _list[i];
                  return ListTile(
                    leading: Text(
                      lang.flag,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      lang.name,
                      style: TextStyle(
                        color: c.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      lang.nativeName,
                      style: TextStyle(color: c.textSub, fontSize: 12),
                    ),
                    onTap: () => Navigator.pop(context, lang),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
