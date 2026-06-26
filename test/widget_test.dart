import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cookest_ui/cookest_ui.dart';

void main() {
  testWidgets('CkButton layout constraints test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 127,
              child: Row(
                children: [
                  Expanded(
                    child: CkButton(
                      onPressed: () {},
                      child: const Text('Very long text that will overflow when width is constrained to 127'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CkButton), findsOneWidget);
  });
}
