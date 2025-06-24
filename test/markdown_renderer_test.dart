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

    testWidgets('renders inline LaTeX', (WidgetTester tester) async {
      const testMarkdown = 'The formula \$x = \\frac{-b \\pm \\sqrt{b^2-4ac}}{2a}\$ is quadratic.';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarkdownRenderer(
              data: testMarkdown,
            ),
          ),
        ),
      );

      expect(find.textContaining('The formula'), findsOneWidget);
      expect(find.textContaining('is quadratic.'), findsOneWidget);
    });

    testWidgets('renders block LaTeX', (WidgetTester tester) async {
      const testMarkdown = '''
Here's a formula:

\$\$E = mc^2\$\$

Einstein's equation.
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

      expect(find.textContaining('Here\'s a formula:'), findsOneWidget);
      expect(find.textContaining('Einstein\'s equation.'), findsOneWidget);
    });

    testWidgets('handles malformed LaTeX gracefully', (WidgetTester tester) async {
      const testMarkdown = 'Bad LaTeX: \$\\invalid{syntax\$ should not crash.';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarkdownRenderer(
              data: testMarkdown,
            ),
          ),
        ),
      );

      expect(find.textContaining('Bad LaTeX:'), findsOneWidget);
      expect(find.textContaining('should not crash.'), findsOneWidget);
    });

    testWidgets('comprehensive markdown demo', (WidgetTester tester) async {
      const testMarkdown = '''
# Comprehensive Markdown Demo

This demonstrates all supported features:

## Code Blocks

```dart
void main() {
  print('Hello, World!');
}
```

```python
def hello():
    print("Hello from Python!")
```

## Inline Code

Use `flutter run` to start the app.

## Mathematics

Inline math: \$E = mc^2\$ is Einstein's equation.

Block math:
\$\$\\int_{-\\infty}^{\\infty} e^{-x^2} dx = \\sqrt{\\pi}\$\$

## Tables

| Language | File Extension |
|----------|----------------|
| Dart     | .dart          |
| Python   | .py            |
| Java     | .java          |

## Lists

### Unordered List
- Feature 1
- Feature 2
- Feature 3

### Ordered List
1. First step
2. Second step
3. Third step

## Blockquotes

> This is a blockquote.
> It can span multiple lines.

## Links

Check out [Flutter](https://flutter.dev) for more info.

## Emphasis

**Bold text** and *italic text* are supported.
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

      // Test that all sections are rendered
      expect(find.textContaining('Comprehensive Markdown Demo'), findsOneWidget);
      expect(find.textContaining('Code Blocks'), findsOneWidget);
      expect(find.textContaining('DART'), findsOneWidget);
      expect(find.textContaining('PYTHON'), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsNWidgets(2)); // Two code blocks
      expect(find.textContaining('Mathematics'), findsOneWidget);
      expect(find.textContaining('Tables'), findsOneWidget);
      expect(find.textContaining('Language'), findsOneWidget);
      expect(find.textContaining('File Extension'), findsOneWidget);
      expect(find.textContaining('Feature 1'), findsOneWidget);
      expect(find.textContaining('First step'), findsOneWidget);
      expect(find.textContaining('This is a blockquote'), findsOneWidget);
    });
  });
}