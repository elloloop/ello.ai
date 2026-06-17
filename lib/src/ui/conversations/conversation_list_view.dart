import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dependencies.dart';
import '../../models/conversation.dart';

class ConversationListView extends ConsumerStatefulWidget {
  const ConversationListView({super.key});

  @override
  ConsumerState<ConversationListView> createState() => _ConversationListViewState();
}

class _ConversationListViewState extends ConsumerState<ConversationListView> {
  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(conversationListProvider);
    final activeConversationId = ref.watch(activeConversationIdProvider);

    return Column(
      children: [
        // New Chat Button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ref.read(conversationProvider.notifier).createNewConversation();
              },
              icon: const Icon(Icons.add),
              label: const Text('New Chat'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        // Conversations List
        Expanded(
          child: conversations.isEmpty
              ? const Center(
                  child: Text(
                    'No conversations yet.\nStart a new chat!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    final isActive = conversation.id == activeConversationId;

                    return ConversationListItem(
                      conversation: conversation,
                      isActive: isActive,
                      onTap: () {
                        ref.read(conversationProvider.notifier).switchToConversation(conversation.id);
                      },
                      onDelete: () {
                        ref.read(conversationProvider.notifier).deleteConversation(conversation.id);
                      },
                      onRename: (newTitle) {
                        ref.read(conversationProvider.notifier).renameConversation(conversation.id, newTitle);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class ConversationListItem extends StatelessWidget {
  final Conversation conversation;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Function(String) onRename;

  const ConversationListItem({
    super.key,
    required this.conversation,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: isActive ? 2 : 0,
      color: isActive 
          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
          : null,
      child: ListTile(
        onTap: onTap,
        title: Text(
          conversation.title,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              conversation.lastMessageSnippet,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                // Model Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getModelBadgeColor(context, conversation.model),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _getModelDisplayName(conversation.model),
                    style: TextStyle(
                      fontSize: 10,
                      color: _getModelTextColor(context, conversation.model),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                // Timestamp
                Text(
                  conversation.formattedTimestamp,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 18),
          onSelected: (value) {
            if (value == 'rename') {
              _showRenameDialog(context);
            } else if (value == 'delete') {
              _showDeleteDialog(context);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'rename',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 16),
                  SizedBox(width: 8),
                  Text('Rename'),
                ],
              ),
            ),
            const PopupMenuItem(
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
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: conversation.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Conversation'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onRename(controller.text.trim());
              }
              Navigator.of(context).pop();
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: Text('Are you sure you want to delete "${conversation.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onDelete();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getModelBadgeColor(BuildContext context, String model) {
    if (model.contains('gpt-4')) {
      return Colors.purple.withOpacity(0.2);
    } else if (model.contains('gpt-3.5')) {
      return Colors.green.withOpacity(0.2);
    } else if (model.contains('claude')) {
      return Colors.orange.withOpacity(0.2);
    } else if (model.contains('gemini')) {
      return Colors.blue.withOpacity(0.2);
    } else if (model.contains('llama')) {
      return Colors.red.withOpacity(0.2);
    }
    return Theme.of(context).colorScheme.secondary.withOpacity(0.2);
  }

  Color _getModelTextColor(BuildContext context, String model) {
    if (model.contains('gpt-4')) {
      return Colors.purple;
    } else if (model.contains('gpt-3.5')) {
      return Colors.green;
    } else if (model.contains('claude')) {
      return Colors.orange;
    } else if (model.contains('gemini')) {
      return Colors.blue;
    } else if (model.contains('llama')) {
      return Colors.red;
    }
    return Theme.of(context).colorScheme.secondary;
  }

  String _getModelDisplayName(String model) {
    // Shorten model names for display
    if (model == 'gpt-3.5-turbo') return 'GPT-3.5';
    if (model == 'gpt-4o') return 'GPT-4';
    if (model == 'claude-3-opus') return 'Claude Opus';
    if (model == 'claude-3-sonnet') return 'Claude Sonnet';
    if (model == 'gemini-pro') return 'Gemini';
    if (model == 'llama-3') return 'Llama-3';
    return model;
  }
}