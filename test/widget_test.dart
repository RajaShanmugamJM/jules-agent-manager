import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:app/main.dart';

void main() {
  testWidgets('Initial screen is Setup', (WidgetTester tester) async {
    // Mock secure storage
    FlutterSecureStorage.setMockInitialValues({});
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(const JulesApp());
    
    // Wait for animations and async tasks
    await tester.pumpAndSettle();

    // Verify that we are on Setup Screen
    expect(find.text('Authentication & API\nSetup'), findsOneWidget);
    expect(find.text('Jules API Key'), findsOneWidget);
  });
}
