import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/dependencies.dart';
import 'debug/debug_settings.dart';
import 'settings/model_picker.dart';
import 'components/streaming_text.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(chatHistoryProvider);
    final controller = TextEditingController();
    final chatState = ref.watch(chatProvider);
    final scrollController = ScrollController();

    // Initialize connection status (safely)
    ref.watch(initConnectionStatusProvider);

    final connectionStatus = ref.watch(connectionStatusProvider);
    final isMockMode = ref.watch(useMockGrpcProvider);

    // Auto-scroll to bottom when new messages arrive, but throttle during streaming
    ref.listen(chatHistoryProvider, (previous, current) {
      if (current.isNotEmpty) {
        final isNewMessage = previous?.length != current.length;
        final isStreamingUpdate = current.last.isStreaming && 
            current.last.content != (previous?.isNotEmpty == true ? previous!.last.content : '');
        
        if (isNewMessage || (isStreamingUpdate && current.last.content.length % 50 == 0)) {
          // Only auto-scroll on new messages or every 50 characters during streaming
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (scrollController.hasClients) {
              scrollController.animateTo(
                scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOut,
              );
            }
          });
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('ello.AI'),
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
          // Interrupt button for streaming responses
          if (chatState is AsyncLoading)
            IconButton(
              icon: const Icon(Icons.stop, color: Colors.red),
              tooltip: 'Stop Response',
              onPressed: () {
                ref.read(chatProvider.notifier).cancelCurrentStream();
              },
            ),
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
          const ModelPicker(),
          const DebugSettingsButton(),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
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
                        // Use StreamingText for efficient streaming updates
                        StreamingText(
                          content: msg.content,
                          style: Theme.of(context).textTheme.bodyMedium,
                          enableInteractiveSelection: true,
                          updateDebounceMs: msg.isStreaming ? 16 : 0, // Faster updates for streaming
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

                        // Show streaming indicator for active streaming messages
                        if (msg.isStreaming)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Streaming...',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
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
                    enabled: chatState is! AsyncLoading,
                    onSubmitted: chatState is AsyncLoading ? null : (value) {
                      ref.read(chatProvider.notifier).sendMessage(value.trim());
                      controller.clear();
                    },
                    decoration: InputDecoration(
                      hintText: chatState is AsyncLoading 
                          ? 'Waiting for response...' 
                          : 'Say something...',
                      suffixIcon: chatState is AsyncLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Show stop button during streaming, send button otherwise
                if (chatState is AsyncLoading)
                  IconButton(
                    icon: const Icon(Icons.stop, color: Colors.red),
                    onPressed: () {
                      ref.read(chatProvider.notifier).cancelCurrentStream();
                    },
                    tooltip: 'Stop Response',
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: controller.text.trim().isEmpty ? null : () {
                      ref
                          .read(chatProvider.notifier)
                          .sendMessage(controller.text.trim());
                      controller.clear();
                    },
                  ),
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
