import 'package:geliyor_app/data/pet_life_stage.dart';

/// Birlikte alınan önerisi için katalog satırı.
class TogetherCandidate {
  const TogetherCandidate({
    required this.id,
    required this.title,
    required this.brand,
    required this.mainCategory,
    required this.category,
    this.stock = 0,
    this.active = true,
  });

  final String id;
  final String title;
  final String brand;
  final String mainCategory;
  final String category;
  final int stock;
  final bool active;
}

/// Ürün kartındaki 3 birlikte alınan önerisini kategoriye göre seçer.
///
/// Elle kaydedilmiş liste varsa o kullanılır. Bu sınıf yalnızca boş liste
/// için en mantıklı 3 ürünü üretir.
abstract final class BoughtTogetherSuggestions {
  static const limit = 3;

  static List<String> idsFor({
    required TogetherCandidate source,
    required List<TogetherCandidate> catalog,
  }) {
    final picks = <TogetherCandidate>[];
    final used = <String>{};
    final usedTitles = <String>{};

    void take(TogetherCandidate? item) {
      if (item == null || picks.length >= limit) return;
      used.add(item.id);
      final title = _fold(item.title);
      if (title.isNotEmpty) usedTitles.add(title);
      picks.add(item);
    }

    TogetherCandidate? best(
      Iterable<TogetherCandidate> pool,
      int Function(TogetherCandidate item) score,
    ) {
      final available = _available(pool, source, used, usedTitles);
      TogetherCandidate? winner;
      var bestScore = -1 << 30;
      for (final item in available) {
        final value = score(item);
        if (winner == null ||
            value > bestScore ||
            (value == bestScore &&
                item.title.toLowerCase().compareTo(winner.title.toLowerCase()) <
                    0)) {
          winner = item;
          bestScore = value;
        }
      }
      return winner;
    }

    final kind = _kindOf(source);
    final main = _mainOf(source);

    switch (kind) {
      case _TogetherKind.catFood:
        take(best(_of(catalog, _TogetherKind.litter, main: 'cat'), _stockScore));
        take(best(_of(catalog, _TogetherKind.malt, main: 'cat'), _maltScore));
        take(best(_of(catalog, _TogetherKind.treat, main: 'cat'), _treatScore));
      case _TogetherKind.dogFood:
        while (picks.length < limit) {
          final next = best(
            _of(catalog, _TogetherKind.dogFood),
            (item) => _dogFoodScore(source, item),
          );
          if (next == null) break;
          take(next);
        }
      case _TogetherKind.treat:
        while (picks.length < limit) {
          final next = best(
            _of(catalog, _TogetherKind.treat, main: main),
            (item) => _sameBrandScore(source, item) + _treatScore(item),
          );
          if (next == null) break;
          take(next);
        }
      case _TogetherKind.care:
        while (picks.length < limit) {
          final next = best(
            _of(catalog, _TogetherKind.care, main: main),
            (item) => _sameBrandScore(source, item) + _stockScore(item),
          );
          if (next == null) break;
          take(next);
        }
      case _TogetherKind.litter:
        take(best(_of(catalog, _TogetherKind.catFood), _adultFoodScore));
        take(best(_of(catalog, _TogetherKind.malt, main: 'cat'), _maltScore));
        take(
          best(
            _of(catalog, _TogetherKind.care, main: 'cat'),
            (item) => _keywordScore(item, const ['kum']) + _stockScore(item),
          ),
        );
      case _TogetherKind.malt:
        take(best(_of(catalog, _TogetherKind.catFood), _adultFoodScore));
        take(best(_of(catalog, _TogetherKind.treat, main: 'cat'), _treatScore));
        take(
          best(
            _of(catalog, _TogetherKind.care, main: 'cat'),
            (item) =>
                _keywordScore(item, const ['tuy', 'tarak', 'sprey']) +
                _stockScore(item),
          ),
        );
      case _TogetherKind.vitamin:
        take(best(_of(catalog, _TogetherKind.catFood), _adultFoodScore));
        take(best(_of(catalog, _TogetherKind.malt, main: 'cat'), _maltScore));
        take(best(_of(catalog, _TogetherKind.treat, main: 'cat'), _treatScore));
      case _TogetherKind.other:
        while (picks.length < limit) {
          final next = best(
            catalog.where((item) => _kindOf(item) == _kindOf(source)),
            (item) => _sameBrandScore(source, item) + _stockScore(item),
          );
          if (next == null) break;
          take(next);
        }
    }

    if (picks.length < limit) {
      final fillers = switch (kind) {
        _TogetherKind.catFood ||
        _TogetherKind.litter ||
        _TogetherKind.malt ||
        _TogetherKind.vitamin =>
          [
            ..._of(catalog, _TogetherKind.treat, main: 'cat'),
            ..._of(catalog, _TogetherKind.care, main: 'cat'),
            ..._of(catalog, _TogetherKind.vitamin, main: 'cat'),
          ],
        _TogetherKind.dogFood => _of(catalog, _TogetherKind.dogFood),
        _ => catalog.where((item) => _mainOf(item) == main),
      };
      while (picks.length < limit) {
        final next = best(fillers, _stockScore);
        if (next == null) break;
        take(next);
      }
    }

    return [for (final item in picks) item.id];
  }

  static List<TogetherCandidate> _of(
    List<TogetherCandidate> catalog,
    _TogetherKind kind, {
    String? main,
  }) {
    return [
      for (final item in catalog)
        if (_kindOf(item) == kind && (main == null || _mainOf(item) == main))
          item,
    ];
  }

  static List<TogetherCandidate> _available(
    Iterable<TogetherCandidate> pool,
    TogetherCandidate source,
    Set<String> used,
    Set<String> usedTitles,
  ) {
    bool ok(TogetherCandidate item, {required bool requireStock}) {
      if (!item.active) return false;
      final id = item.id.trim();
      if (id.isEmpty || id == source.id.trim() || used.contains(id)) {
        return false;
      }
      final title = _fold(item.title);
      if (title.isNotEmpty &&
          (title == _fold(source.title) || usedTitles.contains(title))) {
        return false;
      }
      if (requireStock && item.stock <= 0) return false;
      return true;
    }

    final stocked = [for (final item in pool) if (ok(item, requireStock: true)) item];
    if (stocked.isNotEmpty) return stocked;
    final stockKnown = pool.any((item) => item.stock > 0);
    if (stockKnown) return const [];
    return [for (final item in pool) if (ok(item, requireStock: false)) item];
  }

  static int _stockScore(TogetherCandidate item) => item.stock.clamp(0, 500);

  static int _sameBrandScore(TogetherCandidate source, TogetherCandidate item) {
    final brand = _fold(source.brand);
    if (brand.isEmpty || brand == 'marka') return 0;
    return _fold(item.brand) == brand ? 100000 : 0;
  }

  static int _keywordScore(TogetherCandidate item, List<String> words) {
    final title = _fold(item.title);
    var score = 0;
    for (final word in words) {
      if (title.contains(word)) score += 20000;
    }
    return score;
  }

  static int _maltScore(TogetherCandidate item) {
    final title = _fold(item.title);
    var score = _stockScore(item);
    if (title.contains('malt') || title.contains('yumak')) score += 8000;
    if (title.contains('vitamin')) score -= 4000;
    return score;
  }

  static int _treatScore(TogetherCandidate item) {
    final title = _fold(item.title);
    var score = _stockScore(item);
    if (title.contains('citir') ||
        title.contains('crunch') ||
        title.contains('odul')) {
      score += 8000;
    } else if (title.contains('ezme') ||
        title.contains('krem') ||
        title.contains('corba')) {
      score += 3000;
    }
    if (title.contains('konserve') ||
        title.contains('yas mama') ||
        title.contains('yas kedi')) {
      score -= 4000;
    }
    return score;
  }

  static int _adultFoodScore(TogetherCandidate item) {
    var score = _stockScore(item);
    if (_stage(item.category) == 'yetiskin' && _mainOf(item) == 'cat') {
      score += 10000;
    }
    return score;
  }

  static int _dogFoodScore(TogetherCandidate source, TogetherCandidate item) {
    var score = _stockScore(item);
    if (_stage(item.category) == _stage(source.category)) {
      score += 100000;
    }
    return score;
  }

  static _TogetherKind _kindOf(TogetherCandidate item) {
    final category = _fold(item.category);
    if (category.contains('odul')) return _TogetherKind.treat;
    if (category.contains('bakim') || category.contains('saglik')) {
      return _TogetherKind.care;
    }
    if (category.contains('kum')) return _TogetherKind.litter;
    if (category.contains('malt')) return _TogetherKind.malt;
    if (category.contains('vitamin') || category.contains('takviye')) {
      return _TogetherKind.vitamin;
    }
    if (_isFoodCategory(item.category)) {
      return _mainOf(item) == 'dog'
          ? _TogetherKind.dogFood
          : _TogetherKind.catFood;
    }
    return _TogetherKind.other;
  }

  static bool _isFoodCategory(String category) {
    final stage = _stage(category);
    return stage == 'yetiskin' ||
        stage == 'yavru' ||
        stage == 'mini irk' ||
        stage == 'mini irk yavru' ||
        stage == 'mama';
  }

  static String _stage(String category) {
    final folded = _fold(category);
    if (folded == 'mama') return 'yetiskin';
    return folded;
  }

  static String _mainOf(TogetherCandidate item) {
    final main = item.mainCategory.trim().toLowerCase();
    if (main.isEmpty) return 'cat';
    return main;
  }

  static String _fold(String raw) {
    return PetLifeStage.normalizeTitle(raw)
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i');
  }
}

enum _TogetherKind { catFood, dogFood, treat, care, litter, malt, vitamin, other }
