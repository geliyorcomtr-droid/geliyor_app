import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geliyor_app/screens/product_detail_screen.dart';
import 'package:geliyor_app/screens/splash_screen.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';

void main() {
  testWidgets('Splash screen shows logo area', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Product detail screen renders product info', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          useMaterial3: true,
        ),
        home: const ProductDetailScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Royal Canin Indoor 27'), findsWidgets);
    expect(find.text('Sepete Ekle'), findsOneWidget);
  });

  testWidgets('Standard page title has equal top and bottom spacing', (
    WidgetTester tester,
  ) async {
    const contentKey = Key('page-content');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppPageFrame.standard(
            header: const AppPageHeader(title: 'Sayfa Başlığı'),
            content: const ColoredBox(
              key: contentKey,
              color: AppColors.surface,
            ),
            showNavbar: false,
          ),
        ),
      ),
    );

    final titleRect = tester.getRect(find.text('Sayfa Başlığı'));
    final contentRect = tester.getRect(find.byKey(contentKey));
    final topSpace = titleRect.top;
    final bottomSpace = contentRect.top - titleRect.bottom;

    expect(topSpace, closeTo(bottomSpace, 1));
  });
}
