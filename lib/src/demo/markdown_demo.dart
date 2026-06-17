import 'package:flutter/material.dart';
import '../ui/widgets/markdown_renderer.dart';

/// A demo page to showcase markdown rendering capabilities.
/// This can be used for testing and demonstration purposes.
class MarkdownDemo extends StatelessWidget {
  const MarkdownDemo({super.key});

  static const String demoContent = '''
# Markdown Renderer Demo

Welcome to the **ello.AI** markdown renderer demo! This showcases all supported features.

## 🚀 Code Blocks

### Dart Example
```dart
class AIMessage {
  final String content;
  final bool isUser;
  
  AIMessage({required this.content, required this.isUser});
  
  factory AIMessage.assistant(String content) =>
      AIMessage(content: content, isUser: false);
}
```

### Python Example
```python
def process_markdown(text):
    """Process markdown with LaTeX support."""
    processed = text
    
    # Handle inline LaTeX
    processed = re.sub(r'\\$(.*?)\\$', r'<latex>\\1</latex>', processed)
    
    return processed
```

### JavaScript Example
```javascript
const formatMessage = (content, isUser) => {
  return {
    content,
    isUser,
    timestamp: new Date().toISOString()
  };
};
```

## 🧮 Mathematics

### Inline LaTeX
Einstein's famous equation \$E = mc^2\$ revolutionized physics.

The quadratic formula \$x = \\frac{-b \\pm \\sqrt{b^2-4ac}}{2a}\$ solves polynomial equations.

### Block LaTeX
The fundamental theorem of calculus:

\$\$\\int_a^b f'(x) dx = f(b) - f(a)\$\$

Euler's identity:

\$\$e^{i\\pi} + 1 = 0\$\$

## 📊 Tables

| Language | Syntax Highlighting | File Extension |
|----------|-------------------|----------------|
| Dart     | ✅                | .dart          |
| Python   | ✅                | .py            |
| JavaScript | ✅              | .js            |
| TypeScript | ✅              | .ts            |
| Rust     | ✅                | .rs            |
| Go       | ✅                | .go            |

## 📝 Lists

### AI Features
- **Natural language processing** with advanced models
- **Code generation** and syntax highlighting
- **Mathematical reasoning** with LaTeX support
- **Multi-platform** support (Web, iOS, Android, Desktop)

### Implementation Steps
1. Parse markdown content
2. Extract and highlight code blocks
3. Render LaTeX expressions
4. Apply security sanitization
5. Present with copy functionality

## 💬 Blockquotes

> "The future belongs to those who believe in the beauty of their dreams."
> 
> — Eleanor Roosevelt

> **Note:** This markdown renderer provides XSS-safe content processing
> while maintaining full feature support for rich text formatting.

## 🔗 Links and Formatting

Visit the [ello.AI repository](https://github.com/elloloop/ello.ai) for more information.

**Bold text**, *italic text*, and `inline code` are all supported.

You can also use ~~strikethrough~~ text for edits.

## 🛡️ Security

The renderer includes:
- XSS protection through content sanitization
- Safe link handling (http/https only)
- Error-resistant LaTeX parsing
- Graceful degradation for unsupported content

## 🎨 Theming

This demo automatically adapts to your theme preferences:
- Material Design 3 color schemes
- Dark and light mode support
- Responsive typography scaling
- Accessible contrast ratios

---

*This demo showcases the full capabilities of the MarkdownRenderer widget.*
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Markdown Renderer Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: MarkdownRenderer(
            data: demoContent,
            selectable: true,
          ),
        ),
      ),
    );
  }
}