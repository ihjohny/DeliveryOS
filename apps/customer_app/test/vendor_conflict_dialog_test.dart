import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/core/widgets/vendor_conflict_dialog.dart';

void main() {
  testWidgets('VendorConflictDialog displays replacement warning and calls onConfirm on button tap',
      (WidgetTester tester) async {
    bool confirmed = false;
    bool cancelled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VendorConflictDialog(
            newVendorName: "Sultan's Dine",
            onConfirm: () => confirmed = true,
            onCancel: () => cancelled = true,
          ),
        ),
      ),
    );

    expect(find.text('Replace Cart Items?'), findsOneWidget);
    expect(find.textContaining("Sultan's Dine"), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Replace & Add'), findsOneWidget);

    await tester.tap(find.text('Replace & Add'));
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
    expect(cancelled, isFalse);
  });

  testWidgets('showVendorConflictDialog helper renders modal dialog and executes replace callback',
      (WidgetTester tester) async {
    bool confirmed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showVendorConflictDialog(
                  context: context,
                  newVendorName: 'Kacchi Bhai',
                  onConfirmReplace: () => confirmed = true,
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Replace Cart Items?'), findsOneWidget);
    expect(find.textContaining('Kacchi Bhai'), findsOneWidget);

    await tester.tap(find.text('Replace & Add'));
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
    expect(find.text('Replace Cart Items?'), findsNothing);
  });
}
