# Markdown Renderer Features

The MarkdownRenderer widget provides comprehensive markdown support with the following features:

## ✨ Fenced Code Blocks with Copy Button

```dart
void main() {
  print('Hello, World!');
}
```

```python
def fibonacci(n):
    if n <= 1:
        return n
    return fibonacci(n-1) + fibonacci(n-2)
```

Each code block includes:
- Language-specific syntax highlighting
- One-click copy functionality
- Clean, themed presentation

## 📊 Tables

| Feature | Status | Description |
|---------|--------|-------------|
| Code highlighting | ✅ | Syntax highlighting for 100+ languages |
| Copy functionality | ✅ | One-click copy for code blocks |
| LaTeX rendering | ✅ | Inline and block math expressions |
| XSS protection | ✅ | Safe rendering of user content |

## 📝 Lists

### Unordered Lists
- Fenced code blocks with copy button
- Tables, lists, inline LaTeX
- XSS-safe sanitisation

### Ordered Lists
1. Parse markdown content
2. Apply syntax highlighting
3. Render with copy functionality
4. Ensure security

## 🧮 Mathematics (LaTeX)

### Inline Math
The quadratic formula $x = \frac{-b \pm \sqrt{b^2-4ac}}{2a}$ is fundamental in algebra.

### Block Math
$$\int_{-\infty}^{\infty} e^{-x^2} dx = \sqrt{\pi}$$

$$\sum_{n=1}^{\infty} \frac{1}{n^2} = \frac{\pi^2}{6}$$

## 💬 Blockquotes

> "The best way to predict the future is to invent it."
> 
> — Alan Kay

## 🔗 Links and Emphasis

Check out the [Flutter documentation](https://flutter.dev) for more information.

**Bold text** and *italic text* are fully supported.

## 🛡️ Security Features

- XSS-safe content rendering
- Sanitized link handling
- Protected against code injection
- Graceful error handling for malformed content

## 🎨 Theming

The renderer automatically adapts to:
- Light and dark themes
- Material Design 3 color schemes
- Responsive typography
- Accessible color contrasts