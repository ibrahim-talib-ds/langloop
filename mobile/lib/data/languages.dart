/// Comprehensive language list — code, English name, native name, flag emoji.
/// Order roughly by global speaker count.
class Language {
  const Language(this.code, this.name, this.nativeName, this.flag);
  final String code;
  final String name;
  final String nativeName;
  final String flag;
}

const kLanguages = <Language>[
  Language('en', 'English', 'English', '🇬🇧'),
  Language('zh', 'Chinese', '中文', '🇨🇳'),
  Language('hi', 'Hindi', 'हिन्दी', '🇮🇳'),
  Language('es', 'Spanish', 'Español', '🇪🇸'),
  Language('ar', 'Arabic', 'العربية', '🇸🇦'),
  Language('fr', 'French', 'Français', '🇫🇷'),
  Language('bn', 'Bengali', 'বাংলা', '🇧🇩'),
  Language('ru', 'Russian', 'Русский', '🇷🇺'),
  Language('pt', 'Portuguese', 'Português', '🇵🇹'),
  Language('id', 'Indonesian', 'Bahasa Indonesia', '🇮🇩'),
  Language('ur', 'Urdu', 'اردو', '🇵🇰'),
  Language('de', 'German', 'Deutsch', '🇩🇪'),
  Language('ja', 'Japanese', '日本語', '🇯🇵'),
  Language('sw', 'Swahili', 'Kiswahili', '🇰🇪'),
  Language('mr', 'Marathi', 'मराठी', '🇮🇳'),
  Language('te', 'Telugu', 'తెలుగు', '🇮🇳'),
  Language('tr', 'Turkish', 'Türkçe', '🇹🇷'),
  Language('ta', 'Tamil', 'தமிழ்', '🇮🇳'),
  Language('vi', 'Vietnamese', 'Tiếng Việt', '🇻🇳'),
  Language('ko', 'Korean', '한국어', '🇰🇷'),
  Language('fa', 'Persian', 'فارسی', '🇮🇷'),
  Language('it', 'Italian', 'Italiano', '🇮🇹'),
  Language('th', 'Thai', 'ไทย', '🇹🇭'),
  Language('gu', 'Gujarati', 'ગુજરાતી', '🇮🇳'),
  Language('pl', 'Polish', 'Polski', '🇵🇱'),
  Language('uk', 'Ukrainian', 'Українська', '🇺🇦'),
  Language('ml', 'Malayalam', 'മലയാളം', '🇮🇳'),
  Language('kn', 'Kannada', 'ಕನ್ನಡ', '🇮🇳'),
  Language('or', 'Odia', 'ଓଡ଼ିଆ', '🇮🇳'),
  Language('my', 'Burmese', 'မြန်မာ', '🇲🇲'),
  Language('pa', 'Punjabi', 'ਪੰਜਾਬੀ', '🇮🇳'),
  Language('ro', 'Romanian', 'Română', '🇷🇴'),
  Language('nl', 'Dutch', 'Nederlands', '🇳🇱'),
  Language('ha', 'Hausa', 'Hausa', '🇳🇬'),
  Language('am', 'Amharic', 'አማርኛ', '🇪🇹'),
  Language('yo', 'Yoruba', 'Yorùbá', '🇳🇬'),
  Language('ms', 'Malay', 'Bahasa Melayu', '🇲🇾'),
  Language('ig', 'Igbo', 'Igbo', '🇳🇬'),
  Language('uz', 'Uzbek', 'Oʻzbek', '🇺🇿'),
  Language('sd', 'Sindhi', 'سنڌي', '🇵🇰'),
  Language('ne', 'Nepali', 'नेपाली', '🇳🇵'),
  Language('si', 'Sinhala', 'සිංහල', '🇱🇰'),
  Language('km', 'Khmer', 'ខ្មែរ', '🇰🇭'),
  Language('tk', 'Turkmen', 'Türkmençe', '🇹🇲'),
  Language('az', 'Azerbaijani', 'Azərbaycan', '🇦🇿'),
  Language('kk', 'Kazakh', 'Қазақша', '🇰🇿'),
  Language('ky', 'Kyrgyz', 'Кыргызча', '🇰🇬'),
  Language('tg', 'Tajik', 'Тоҷикӣ', '🇹🇯'),
  Language('hy', 'Armenian', 'Հայերեն', '🇦🇲'),
  Language('ka', 'Georgian', 'ქართული', '🇬🇪'),
  Language('he', 'Hebrew', 'עברית', '🇮🇱'),
  Language('el', 'Greek', 'Ελληνικά', '🇬🇷'),
  Language('cs', 'Czech', 'Čeština', '🇨🇿'),
  Language('hu', 'Hungarian', 'Magyar', '🇭🇺'),
  Language('sv', 'Swedish', 'Svenska', '🇸🇪'),
  Language('no', 'Norwegian', 'Norsk', '🇳🇴'),
  Language('da', 'Danish', 'Dansk', '🇩🇰'),
  Language('fi', 'Finnish', 'Suomi', '🇫🇮'),
  Language('is', 'Icelandic', 'Íslenska', '🇮🇸'),
  Language('ga', 'Irish', 'Gaeilge', '🇮🇪'),
  Language('cy', 'Welsh', 'Cymraeg', '🇬🇧'),
  Language('sr', 'Serbian', 'Српски', '🇷🇸'),
  Language('hr', 'Croatian', 'Hrvatski', '🇭🇷'),
  Language('bg', 'Bulgarian', 'Български', '🇧🇬'),
  Language('sk', 'Slovak', 'Slovenčina', '🇸🇰'),
  Language('sl', 'Slovenian', 'Slovenščina', '🇸🇮'),
  Language('lt', 'Lithuanian', 'Lietuvių', '🇱🇹'),
  Language('lv', 'Latvian', 'Latviešu', '🇱🇻'),
  Language('et', 'Estonian', 'Eesti', '🇪🇪'),
  Language('sq', 'Albanian', 'Shqip', '🇦🇱'),
  Language('mk', 'Macedonian', 'Македонски', '🇲🇰'),
  Language('af', 'Afrikaans', 'Afrikaans', '🇿🇦'),
  Language('zu', 'Zulu', 'isiZulu', '🇿🇦'),
  Language('xh', 'Xhosa', 'isiXhosa', '🇿🇦'),
  Language('so', 'Somali', 'Soomaali', '🇸🇴'),
  Language('mg', 'Malagasy', 'Malagasy', '🇲🇬'),
  Language('fil', 'Filipino', 'Filipino', '🇵🇭'),
  Language('jv', 'Javanese', 'Basa Jawa', '🇮🇩'),
  Language('su', 'Sundanese', 'Basa Sunda', '🇮🇩'),
  Language('ceb', 'Cebuano', 'Cebuano', '🇵🇭'),
  Language('gl', 'Galician', 'Galego', '🇪🇸'),
  Language('ca', 'Catalan', 'Català', '🇪🇸'),
  Language('eu', 'Basque', 'Euskara', '🇪🇸'),
  Language('mt', 'Maltese', 'Malti', '🇲🇹'),
  Language('lb', 'Luxembourgish', 'Lëtzebuergesch', '🇱🇺'),
  Language('la', 'Latin', 'Latina', '🏛️'),
  Language('eo', 'Esperanto', 'Esperanto', '🌍'),
];

Language? findLanguage(String code) {
  for (final l in kLanguages) {
    if (l.code == code) return l;
  }
  return null;
}

String flagFor(String code) => findLanguage(code)?.flag ?? '🌍';
String nameFor(String code) => findLanguage(code)?.name ?? code.toUpperCase();
