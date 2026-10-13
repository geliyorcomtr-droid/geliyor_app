class IngredientSection {
  const IngredientSection({required this.title, required this.body});

  final String title;
  final String body;
}

abstract final class ProductIngredients {
  static bool looksLike(String raw) {
    final text = raw.toLowerCase();
    return text.contains('içindekiler') ||
        text.contains('icindekiler') ||
        text.contains('katkı maddeleri') ||
        text.contains('katki maddeleri');
  }

  static List<IngredientSection> parse(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return const [];

    final pattern = RegExp(
      r'(içindekiler|icindekiler|katkı maddeleri|katki maddeleri)\s*:',
      caseSensitive: false,
    );
    final matches = pattern.allMatches(text).toList();
    if (matches.isEmpty) {
      return [IngredientSection(title: 'İçindekiler', body: text)];
    }

    final sections = <IngredientSection>[];
    for (var i = 0; i < matches.length; i++) {
      final label = matches[i].group(1)!.toLowerCase();
      final title = label.contains('katk') ? 'Katkı Maddeleri' : 'İçindekiler';
      final start = matches[i].end;
      final end = i + 1 < matches.length ? matches[i + 1].start : text.length;
      final body = text.substring(start, end).trim();
      if (body.isEmpty) continue;
      sections.add(IngredientSection(title: title, body: body));
    }
    return sections;
  }
}
