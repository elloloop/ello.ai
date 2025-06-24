import 'package:flutter_test/flutter_test.dart';
import 'package:ello_ai/src/ui/components/streaming_text.dart';
import 'package:flutter/material.dart';

void main() {
  group('StreamingText Widget Tests', () {
    testWidgets('StreamingText displays content correctly', (WidgetTester tester) async {
      const testContent = 'Hello, this is a test message!';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StreamingText(
              content: testContent,
            ),
          ),
        ),
      );

      expect(find.text(testContent), findsOneWidget);
    });

    testWidgets('StreamingText updates content efficiently', (WidgetTester tester) async {
      String content = 'Initial';
      late StateSetter setState;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, stateSetter) {
                setState = stateSetter;
                return StreamingText(
                  content: content,
                  updateDebounceMs: 1, // Very fast for testing
                );
              },
            ),
          ),
        ),
      );

      // Initial content should be displayed
      expect(find.text('Initial'), findsOneWidget);

      // Update content multiple times rapidly
      setState(() {
        content = 'Initial content';
      });
      await tester.pump();

      setState(() {
        content = 'Initial content updated';
      });
      await tester.pump();

      setState(() {
        content = 'Initial content updated again';
      });
      await tester.pump();

      // Wait for debounced update
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Initial content updated again'), findsOneWidget);
    });
  });
}