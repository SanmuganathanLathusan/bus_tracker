import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waygo/main.dart';

void main() {
  testWidgets('Splash screen displays WayGo title', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(MyApp());

    // Wait for a frame
    await tester.pumpAndSettle();

    // Check if the SplashScreen shows some text or widget
    expect(find.text('WayGo'), findsOneWidget); // Replace with actual text in SplashScreen
    // You can also check for images, logos, or buttons
    expect(find.byType(Image), findsWidgets); // if your splash has an image
  });
}
