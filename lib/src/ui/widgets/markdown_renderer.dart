import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlighter/flutter_highlighter.dart';
import 'package:flutter_highlighter/themes/github.dart';
import 'package:flutter_highlighter/themes/github-dark.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

/// A widget that renders markdown content with enhanced code block support,
/// syntax highlighting, and copy functionality.
class MarkdownRenderer extends StatelessWidget {
  const MarkdownRenderer({
    super.key,
    required this.data,
    this.selectable = true,
  });

  final String data;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Process LaTeX in the markdown before rendering
    final processedData = _processLatex(data);
    
    return MarkdownBody(
      data: processedData,
      selectable: selectable,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        // Style code blocks
        codeblockDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        codeblockPadding: const EdgeInsets.all(12.0),
        // Style inline code
        code: TextStyle(
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          fontFamily: 'monospace',
          fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
        ),
        // Style tables
        tableHead: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        tableBorder: TableBorder.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: 1.0,
        ),
        tableColumnWidth: const FlexColumnWidth(),
        // Style blockquotes
        blockquoteDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderLeft: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 4.0,
          ),
        ),
        blockquotePadding: const EdgeInsets.all(8.0),
      ),
      builders: {
        'pre': CodeBlockBuilder(isDark: isDark),
        'latex': LatexBuilder(), // Custom builder for LaTeX
      },
      // Enhanced link handling
      onTapLink: (text, href, title) {
        if (href != null) {
          // Handle link taps securely
          _handleLinkTap(context, href);
        }
      },
    );
  }

  /// Process LaTeX expressions in markdown text
  String _processLatex(String text) {
    // Convert inline LaTeX ($...$) to custom HTML elements
    final inlineLatexRegex = RegExp(r'\$([^$]+)\$');
    String processed = text.replaceAllMapped(inlineLatexRegex, (match) {
      final latex = match.group(1)!;
      return '<latex data-inline="true">$latex</latex>';
    });

    // Convert block LaTeX ($$...$$) to custom HTML elements
    final blockLatexRegex = RegExp(r'\$\$([^$]+)\$\$');
    processed = processed.replaceAllMapped(blockLatexRegex, (match) {
      final latex = match.group(1)!;
      return '<latex data-block="true">$latex</latex>';
    });

    return processed;
  }

  void _handleLinkTap(BuildContext context, String href) {
    // Basic XSS protection - only allow http/https links
    if (href.startsWith('http://') || href.startsWith('https://')) {
      // In a real app, you'd use url_launcher here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Link: $href')),
      );
    }
  }
}

/// Custom builder for code blocks with syntax highlighting and copy functionality
class CodeBlockBuilder extends MarkdownElementBuilder {
  CodeBlockBuilder({required this.isDark});

  final bool isDark;

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final String textContent = element.textContent;
    
    if (textContent.isEmpty) {
      return const SizedBox.shrink();
    }

    // Extract language from class attribute (e.g., "language-dart")
    String? language;
    final className = element.attributes['class'];
    if (className != null && className.startsWith('language-')) {
      language = className.substring(9); // Remove "language-" prefix
    }

    return CodeBlock(
      code: textContent,
      language: language,
      isDark: isDark,
    );
  }
}

/// A widget that displays code with syntax highlighting and a copy button
class CodeBlock extends StatelessWidget {
  const CodeBlock({
    super.key,
    required this.code,
    this.language,
    required this.isDark,
  });

  final String code;
  final String? language;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with language label and copy button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8.0),
                topRight: Radius.circular(8.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  language?.toUpperCase() ?? 'CODE',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                IconButton(
                  onPressed: () => _copyToClipboard(context),
                  icon: Icon(
                    Icons.copy,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  tooltip: 'Copy code',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Code content with syntax highlighting
          Container(
            padding: const EdgeInsets.all(12.0),
            child: _buildHighlightedCode(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedCode(BuildContext context) {
    // Try to apply syntax highlighting if language is specified
    if (language != null && language!.isNotEmpty) {
      try {
        return HighlightView(
          code,
          language: language!,
          theme: isDark ? githubDarkTheme : githubTheme,
          padding: EdgeInsets.zero,
          textStyle: TextStyle(
            fontFamily: 'monospace',
            fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
          ),
        );
      } catch (e) {
        // Fall back to plain text if highlighting fails
        return _buildPlainCode(context);
      }
    }
    
    return _buildPlainCode(context);
  }

  Widget _buildPlainCode(BuildContext context) {
    return SelectableText(
      code,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// Custom builder for LaTeX expressions
class LatexBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final latex = element.textContent;
    
    if (latex.isEmpty) {
      return const SizedBox.shrink();
    }

    final isBlock = element.attributes['data-block'] == 'true';
    
    try {
      return Container(
        margin: isBlock 
          ? const EdgeInsets.symmetric(vertical: 8.0)
          : EdgeInsets.zero,
        child: Math.tex(
          latex,
          mathStyle: isBlock ? MathStyle.display : MathStyle.text,
          textStyle: preferredStyle,
        ),
      );
    } catch (e) {
      // If LaTeX parsing fails, show the original text
      return Text(
        isBlock ? '\$\$$latex\$\$' : '\$$latex\$',
        style: preferredStyle?.copyWith(
          fontFamily: 'monospace',
          color: Colors.red.withOpacity(0.7),
        ),
      );
    }
  }
}

