import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ello_ai/src/ui/widgets/markdown_renderer.dart';

void main() {
  group('MarkdownRenderer', () {
    testWidgets('renders basic markdown text', (WidgetTester tester) async {
      const testMarkdown = '# Hello World\n\nThis is a test.';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarkdownRenderer(
              data: testMarkdown,
            ),
          ),
        ),
      );

      expect(find.text('Hello World'), findsOneWidget);
      expect(find.text('This is a test.'), findsOneWidget);
    });

    testWidgets('renders code blocks with copy button', (WidgetTester tester) async {
      const testMarkdown = '''
# Code Example

```dart
void main() {
  print('Hello World');
}
```
''';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarkdownRenderer(
              data: testMarkdown,
            ),
          ),
        ),
      );

      expect(find.text('Code Example'), findsOneWidget);
      expect(find.text('DART'), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsOneWidget);
      expect(find.textContaining('void main()'), findsOneWidget);
    });

    testWidgets('copy button works', (WidgetTester tester) async {
      const testMarkdown = '''
```dart
print('test');
```
''';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarkdownRenderer(
              data: testMarkdown,
            ),
          ),
        ),
      );

      // Tap the copy button
      await tester.tap(find.byIcon(Icons.copy));
      await tester.pump();

      // Verify snackbar appears
      expect(find.text('Code copied to clipboard'), findsOneWidget);
    });

    testWidgets('renders tables', (WidgetTester tester) async {
      const testMarkdown = '''
| Name | Age |
|------|-----|
| John | 30  |
| Jane | 25  |
''';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarkdownRenderer(
              data: testMarkdown,
            ),
          ),
        ),
      );

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Age'), findsOneWidget);
      expect(find.text('John'), findsOneWidget);
      expect(find.text('Jane'), findsOneWidget);
    });

    testWidgets('renders lists', (WidgetTester tester) async {
      const testMarkdown = '''
# Features

- Feature 1
- Feature 2
- Feature 3

1. First item
2. Second item
''';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarkdownRenderer(
              data: testMarkdown,
            ),
          ),
        ),
      );

      expect(find.text('Features'), findsOneWidget);
      expect(find.text('Feature 1'), findsOneWidget);
      expect(find.text('Feature 2'), findsOneWidget);
      expect(find.text('First item'), findsOneWidget);
      expect(find.text('Second item'), findsOneWidget);
    });

    testWidgets('handles inline code', (WidgetTester tester) async {
      const testMarkdown = 'Use the `print()` function to output text.';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarkdownRenderer(
              data: testMarkdown,
            ),
          ),
        ),
      );

      expect(find.textContaining('print()'), findsOneWidget);
    });
  });
}