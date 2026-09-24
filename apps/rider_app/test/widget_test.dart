import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rider_app/core/storage/local_storage.dart';
import 'package:rider_app/main.dart';

void main() {
  testWidgets('DeliveryOSRiderApp smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final localStorage = LocalStorage(prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
        ],
        child: const DeliveryOSRiderApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DeliveryOS Rider Fleet'), findsOneWidget);
  });
}
