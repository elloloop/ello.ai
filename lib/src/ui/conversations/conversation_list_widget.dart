import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/conversation.dart';
import '../../providers/conversation_providers.dart';
import '../../utils/logger.dart';

/// Widget that displays a list of conversations with context menu support
class ConversationListWidget extends ConsumerWidget {
  const ConversationListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsProvider);
    final activeConversationId = ref.watch(activeConversationIdProvider);

    if (conversations.isEmpty) {
      return const Center(
        child: Text(
          'No conversations yet.\nStart a new conversation!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        final isActive = conversation.id == activeConversationId;

        return ConversationTile(
          conversation: conversation,
          isActive: isActive,
          onTap: () {
            ref.read(conversationsProvider.notifier).setActiveConversation(conversation.id);
          },
        );
      },
    );
  }
}

/// Individual conversation tile with context menu
class ConversationTile extends ConsumerStatefulWidget {
  const ConversationTile({
    super.key,
    required this.conversation,
    required this.isActive,
    required this.onTap,
  });

  final Conversation conversation;
  final bool isActive;
  final VoidCallback onTap;

  @override
  ConsumerState<ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends ConsumerState<ConversationTile> {
  bool _isRenaming = false;
  late TextEditingController _renameController;

  @override
  void initState() {
    super.initState();
    _renameController = TextEditingController(text: widget.conversation.name);
  }

  @override
  void dispose() {
    _renameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapDown: (details) {
        _showContextMenu(context, details.globalPosition);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: widget.isActive 
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          title: _isRenaming 
              ? TextField(
                  controller: _renameController,
                  autofocus: true,
                  onSubmitted: _submitRename,
                  onEditingComplete: _submitRename,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                )
              : Text(
                  widget.conversation.name,
                  style: TextStyle(
                    fontWeight: widget.isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
          subtitle: Text(
            widget.conversation.preview,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: widget.isActive 
              ? Icon(
                  Icons.radio_button_checked,
                  color: Theme.of(context).colorScheme.primary,
                  size: 16,
                )
              : null,
          onTap: _isRenaming ? null : widget.onTap,
          onLongPress: () {
            final RenderBox renderBox = context.findRenderObject() as RenderBox;
            final position = renderBox.localToGlobal(Offset.zero);
            _showContextMenu(
              context, 
              Offset(position.dx + renderBox.size.width / 2, position.dy),
            );
          },
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        const PopupMenuItem<String>(
          value: 'rename',
          child: Row(
            children: [
              Icon(Icons.edit, size: 16),
              SizedBox(width: 8),
              Text('Rename'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'duplicate',
          child: Row(
            children: [
              Icon(Icons.copy, size: 16),
              SizedBox(width: 8),
              Text('Duplicate'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 16, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        _handleContextMenuAction(value);
      }
    });
  }

  void _handleContextMenuAction(String action) {
    switch (action) {
      case 'rename':
        _startRenaming();
        break;
      case 'duplicate':
        _duplicateConversation();
        break;
      case 'delete':
        _showDeleteConfirmation();
        break;
    }
  }

  void _startRenaming() {
    setState(() {
      _isRenaming = true;
      _renameController.text = widget.conversation.name;
    });
  }

  void _submitRename() {
    final newName = _renameController.text.trim();
    if (newName.isNotEmpty && newName != widget.conversation.name) {
      ref.read(conversationsProvider.notifier).renameConversation(
        widget.conversation.id,
        newName,
      );
    }
    setState(() {
      _isRenaming = false;
    });
  }

  Future<void> _duplicateConversation() async {
    try {
      final newId = await ref.read(conversationsProvider.notifier).duplicateConversation(
        widget.conversation.id,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conversation duplicated: ${widget.conversation.name} (Copy)'),
            action: SnackBarAction(
              label: 'Switch',
              onPressed: () {
                ref.read(conversationsProvider.notifier).setActiveConversation(newId);
              },
            ),
          ),
        );
      }
    } catch (e) {
      Logger.error('Error duplicating conversation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error duplicating conversation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: Text(
          'Are you sure you want to delete "${widget.conversation.name}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        _deleteConversation();
      }
    });
  }

  Future<void> _deleteConversation() async {
    try {
      await ref.read(conversationsProvider.notifier).deleteConversation(
        widget.conversation.id,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted conversation: ${widget.conversation.name}'),
          ),
        );
      }
    } catch (e) {
      Logger.error('Error deleting conversation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting conversation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}