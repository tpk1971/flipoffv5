import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flipoff/game/splash_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SplashPage renders candidate image and glowing FlippOff text logo',
      (WidgetTester tester) async {
    // Pump the SplashPage inside a test environment
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashPage(),
      ),
    );

    // Verify the visual structure is laid out
    expect(find.byType(SplashPage), findsOneWidget);
    expect(find.text('FlippOff'), findsOneWidget);

    // Verify the candidate image asset is loaded
    final imageFinder = find.byType(Image);
    expect(imageFinder, findsOneWidget);

    final imageWidget = tester.widget<Image>(imageFinder);
    expect(imageWidget.image, isA<AssetImage>());
    expect((imageWidget.image as AssetImage).assetName, equals('assets/images/splash.png'));

    // Verify styling of the FlippOff text logo (font size, weight, and glow shadows)
    final textWidget = tester.widget<Text>(find.text('FlippOff'));
    expect(textWidget.style?.fontSize, equals(48));
    expect(textWidget.style?.fontWeight, equals(FontWeight.bold));
    expect(textWidget.style?.color, equals(Colors.white));
    expect(textWidget.style?.shadows, isNotNull);
    expect(textWidget.style?.shadows?.length, equals(2));
  });
}
