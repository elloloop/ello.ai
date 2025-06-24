import 'dart:async';
import 'package:flutter/material.dart';

/// A text widget optimized for streaming content that updates efficiently
/// without causing UI jank during rapid token arrivals
class StreamingText extends StatefulWidget {
  const StreamingText({
    super.key,
    required this.content,
    this.style,
    this.enableInteractiveSelection = true,
    this.contextMenuBuilder,
    this.updateDebounceMs = 16, // ~60fps max update rate
  });

  final String content;
  final TextStyle? style;
  final bool enableInteractiveSelection;
  final Widget Function(BuildContext, EditableTextState)? contextMenuBuilder;
  final int updateDebounceMs;

  @override
  State<StreamingText> createState() => _StreamingTextState();
}

class _StreamingTextState extends State<StreamingText> {
  Timer? _debounceTimer;
  String _displayedContent = '';
  String _pendingContent = '';

  @override
  void initState() {
    super.initState();
    _displayedContent = widget.content;
    _pendingContent = widget.content;
  }

  @override
  void didUpdateWidget(StreamingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.content != oldWidget.content) {
      _pendingContent = widget.content;
      
      // Cancel any existing timer
      _debounceTimer?.cancel();
      
      // For immediate updates (large changes or when content gets shorter)
      if (widget.content.length < _displayedContent.length ||
          widget.content.length - _displayedContent.length > 50) {
        _updateDisplayedContent();
      } else {
        // Debounce rapid updates
        _debounceTimer = Timer(Duration(milliseconds: widget.updateDebounceMs), () {
          _updateDisplayedContent();
        });
      }
    }
  }

  void _updateDisplayedContent() {
    if (mounted && _displayedContent != _pendingContent) {
      setState(() {
        _displayedContent = _pendingContent;
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      _displayedContent,
      enableInteractiveSelection: widget.enableInteractiveSelection,
      style: widget.style,
      contextMenuBuilder: widget.contextMenuBuilder,
    );
  }
}