/// Display helpers for free-text tags on list cards.
class TagDisplay {
  TagDisplay._();

  static const maxZhChars = 6;
  static const maxEnChars = 10;

  /// True if [ch] is a CJK ideograph / hangul / kana code unit range.
  static bool _isCjk(int code) {
    return (code >= 0x4E00 && code <= 0x9FFF) ||
        (code >= 0x3400 && code <= 0x4DBF) ||
        (code >= 0x3040 && code <= 0x30FF) ||
        (code >= 0xAC00 && code <= 0xD7AF) ||
        (code >= 0xF900 && code <= 0xFAFF);
  }

  /// Count characters as CJK units vs latin units (runes).
  static bool looksPrimarilyChinese(String text) {
    if (text.isEmpty) return false;
    var cjk = 0;
    var other = 0;
    for (final r in text.runes) {
      if (_isCjk(r)) {
        cjk++;
      } else if (r > 32) {
        other++;
      }
    }
    return cjk >= other;
  }

  static String ellipsize(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return text;
    final max = looksPrimarilyChinese(text) ? maxZhChars : maxEnChars;
    final runes = text.runes.toList();
    if (runes.length <= max) return text;
    return '${String.fromCharCodes(runes.take(max))}…';
  }
}
