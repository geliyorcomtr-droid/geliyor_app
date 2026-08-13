import 'package:flutter_test/flutter_test.dart';
import 'package:geliyor_app/main.dart';

void main() {
  testWidgets('Product detail screen renders product info', (WidgetTester tester) async {
    await tester.pumpWidget(const GeliyorApp());

    expect(find.text('Royal Canin Indoor 27'), findsOneWidget);
    expect(find.text('Sepete Ekle'), findsOneWidget);
  });
}
