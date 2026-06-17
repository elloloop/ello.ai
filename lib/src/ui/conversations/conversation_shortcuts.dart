import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/conversation_providers.dart';

/// Widget that handles keyboard shortcuts for conversation management
class ConversationShortcuts extends ConsumerWidget {
  const ConversationShortcuts({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): 
            const NewConversationIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyD): 
            const DuplicateConversationIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyD): 
            const DeleteConversationIntent(),
      },
      child: Actions(
        actions: {
          NewConversationIntent: CallbackAction<NewConversationIntent>(
            onInvoke: (intent) => _handleNewConversation(ref),
          ),
          DuplicateConversationIntent: CallbackAction<DuplicateConversationIntent>(
            onInvoke: (intent) => _handleDuplicateConversation(ref),
          ),
          DeleteConversationIntent: CallbackAction<DeleteConversationIntent>(
            onInvoke: (intent) => _handleDeleteConversation(ref, context),
          ),
        },
        child: child,
      ),
    );
  }

  Future<void> _handleNewConversation(WidgetRef ref) async {
    await ref.read(conversationsProvider.notifier)
        .createConversation(name: 'New Conversation');
  }

  Future<void> _handleDuplicateConversation(WidgetRef ref) async {
    final activeId = ref.read(activeConversationIdProvider);
    if (activeId != null) {
      await ref.read(conversationsProvider.notifier)
          .duplicateConversation(activeId);
    }
  }

  Future<void> _handleDeleteConversation(WidgetRef ref, BuildContext context) async {
    final activeId = ref.read(activeConversationIdProvider);
    final activeConv = ref.read(activeConversationProvider);
    
    if (activeId != null && activeConv != null && context.mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Conversation'),
          content: Text('Delete "${activeConv.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await ref.read(conversationsProvider.notifier)
            .deleteConversation(activeId);
      }
    }
  }
}

/// Intents for keyboard shortcuts
class NewConversationIntent extends Intent {
  const NewConversationIntent();
}

class DuplicateConversationIntent extends Intent {
  const DuplicateConversationIntent();
}

class DeleteConversationIntent extends Intent {
  const DeleteConversationIntent();
}