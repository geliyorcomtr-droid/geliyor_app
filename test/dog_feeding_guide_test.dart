import 'package:flutter_test/flutter_test.dart';
import 'package:geliyor_app/data/dog_feeding_guide.dart';

void main() {
  test('dog feeding guide uses activity range midpoint', () {
    final medium = DogFeedingGuide.fromSizeLabel('Medium (11-25 kg)');

    expect(medium, isNotNull);
    expect(medium!.gramsFor('Düşük'), 185);
    expect(medium.gramsFor('Orta'), 220);
    expect(medium.gramsFor('Yüksek'), 260);
  });

  test('giant guide uses open-ended minimum', () {
    final giant = DogFeedingGuide.fromSizeLabel('Giant (45 kg+)');

    expect(giant, isNotNull);
    expect(giant!.gramsFor('Düşük'), 355);
    expect(giant.gramsFor('Orta'), 420);
    expect(giant.gramsFor('Yüksek'), 495);
  });
}
