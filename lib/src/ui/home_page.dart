import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/dependencies.dart';
import 'debug/debug_settings.dart';
import 'settings/model_picker.dart';
import 'conversations/conversation_list_view.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(chatHistoryProvider);
    final controller = TextEditingController();
    final activeConversation = ref.watch(activeConversationProvider);

    // Initialize connection status (safely)
    ref.watch(initConnectionStatusProvider);

    final connectionStatus = ref.watch(connectionStatusProvider);
    final isMockMode = ref.watch(useMockGrpcProvider);

    // Initialize with a new conversation if none exists
    final conversations = ref.watch(conversationListProvider);
    final activeConversationId = ref.watch(activeConversationIdProvider);
    
    // Use a post-frame callback to ensure proper initialization
    if (conversations.isEmpty && activeConversationId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ref.read(conversationListProvider).isEmpty) {
          ref.read(conversationProvider.notifier).createNewConversation();
        }
      });
    }

    return Scaffold(
      body: Row(
        children: [
          // Sidebar with conversation list
          SizedBox(
            width: 300,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Sidebar header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'ello.AI',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        // Debug and settings buttons in sidebar
                        const ModelPicker(),
                        const SizedBox(width: 8),
                        const DebugSettingsButton(),
                      ],
                    ),
                  ),
                  // Conversation list
                  const Expanded(child: ConversationListView()),
                ],
              ),
            ),
          ),
          // Main chat area
          Expanded(
            child: _buildChatArea(context, ref, messages, controller, connectionStatus, isMockMode, activeConversation),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea(BuildContext context, WidgetRef ref, List messages, TextEditingController controller, 
      connectionStatus, bool isMockMode, activeConversation) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(activeConversation?.title ?? 'ello.AI'),
            if (ref.watch(hasActiveConversationProvider))
              GestureDetector(
                onTap: () => showConversationIdSnackbar(context, ref),
                child: Text(
                  'Active conversation',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                ),
              ),
          ],
        ),
        actions: [
          // Reset conversation button
          if (ref.watch(hasActiveConversationProvider))
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset Conversation',
              onPressed: () {
                ref.read(chatProvider.notifier).resetConversation();
              },
            ),
          // Connection status indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isMockMode
                          ? Colors.orange
                          : connectionStatus == ConnectionStatus.connected
                              ? Colors.green
                              : connectionStatus == ConnectionStatus.connecting
                                  ? Colors.blue
                                  : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isMockMode
                        ? 'Mock Mode'
                        : connectionStatus == ConnectionStatus.connected
                            ? 'Connected'
                            : connectionStatus == ConnectionStatus.connecting
                                ? 'Connecting...'
                                : 'Disconnected',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start a conversation',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ask me anything!',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return Align(
                        alignment:
                            msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: msg.isUser
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SelectableText(
                                msg.content,
                                // Enable text selection and contextual menu
                                enableInteractiveSelection: true,
                                // Match text style with the original Text widget
                                style: Theme.of(context).textTheme.bodyMedium,
                                // Optional: improved selection experience using contextMenuBuilder
                                contextMenuBuilder: (context, editableTextState) {
                                  return AdaptiveTextSelectionToolbar.buttonItems(
                                    buttonItems: [
                                      ContextMenuButtonItem(
                                        label: 'Copy',
                                        onPressed: () {
                                          editableTextState.copySelection(
                                              SelectionChangedCause.toolbar);
                                        },
                                      ),
                                      ContextMenuButtonItem(
                                        label: 'Select All',
                                        onPressed: () {
                                          editableTextState.selectAll(
                                              SelectionChangedCause.toolbar);
                                        },
                                      ),
                                    ],
                                    anchors: editableTextState.contextMenuAnchors,
                                  );
                                },
                              ),

                              // Show a button to enable Mock Mode if this is an error message
                              if (!msg.isUser && msg.content.contains('Error'))
                                Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.offline_bolt,
                                            color: Colors.orange),
                                        label: const Text('Enable Mock Mode',
                                            style: TextStyle(color: Colors.orange)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Theme.of(context).colorScheme.surface,
                                        ),
                                        onPressed: () {
                                          // Only toggle if mock mode isn't already enabled
                                          if (!ref.read(useMockGrpcProvider)) {
                                            // Toggle mock mode
                                            ref
                                                .read(useMockGrpcProvider.notifier)
                                                .toggle();

                                            // Show a confirmation
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Mock Mode enabled - using simulated responses'),
                                                backgroundColor: Colors.orange,
                                              ),
                                            );
                                          } else {
                                            // Already enabled
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Mock Mode is already enabled'),
                                                backgroundColor: Colors.blue,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.refresh,
                                            color: Colors.blue),
                                        label: const Text('Retry Connection',
                                            style: TextStyle(color: Colors.blue)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Theme.of(context).colorScheme.surface,
                                        ),
                                        onPressed: () {
                                          // Force update the client
                                          ref
                                              .read(
                                                  currentChatClientProvider.notifier)
                                              .updateClient();

                                          // Show a confirmation
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Retrying connection to server...'),
                                              backgroundColor: Colors.blue,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    onSubmitted: (value) {
                      ref.read(conversationProvider.notifier).sendMessageInConversation(value.trim());
                      controller.clear();
                    },
                    decoration:
                        const InputDecoration(hintText: 'Say something...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    ref
                        .read(conversationProvider.notifier)
                        .sendMessageInConversation(controller.text.trim());
                    controller.clear();
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

/// Display the conversation ID in a snackbar
void showConversationIdSnackbar(BuildContext context, WidgetRef ref) {
  final conversationId = ref.read(conversationIdProvider);
  if (conversationId != null && conversationId.isNotEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Current conversation ID: ${conversationId.substring(0, conversationId.length > 8 ? 8 : conversationId.length)}...'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Copy',
          onPressed: () {
            // Implement copy to clipboard if needed
          },
        ),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No active conversation'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
