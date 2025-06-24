import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/dependencies.dart';
import 'debug/debug_settings.dart';
import 'settings/model_picker.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(chatHistoryProvider);
    final controller = TextEditingController();

    // Initialize connection status (safely)
    ref.watch(initConnectionStatusProvider);

    final connectionStatus = ref.watch(connectionStatusProvider);
    final isMockMode = ref.watch(useMockGrpcProvider);

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
          // System Prompt Section
          Consumer(
            builder: (context, ref, _) {
              final systemPrompt = ref.watch(systemPromptProvider);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: ExpansionTile(
                  title: Row(
                    children: [
                      const Icon(Icons.psychology, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'System Prompt Override',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (systemPrompt.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Active',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Override the default system prompt for new conversations:',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          SystemPromptTextField(
                            initialValue: systemPrompt,
                            onChanged: (value) {
                              ref.read(systemPromptProvider.notifier).setSystemPrompt(value);
                            },
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  ref.read(systemPromptProvider.notifier).clearSystemPrompt();
                                },
                                child: const Text('Clear'),
                              ),
                              const Spacer(),
                              Text(
                                systemPrompt.isEmpty 
                                  ? 'Using default system prompt' 
                                  : '${systemPrompt.length} characters',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    onSubmitted: (value) {
                      ref.read(chatProvider.notifier).sendMessage(value.trim());
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
                        .read(chatProvider.notifier)
                        .sendMessage(controller.text.trim());
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

/// A StatefulWidget for managing the system prompt text field
class SystemPromptTextField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const SystemPromptTextField({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<SystemPromptTextField> createState() => _SystemPromptTextFieldState();
}

class _SystemPromptTextFieldState extends State<SystemPromptTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(SystemPromptTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      maxLines: 3,
      decoration: const InputDecoration(
        hintText: 'Enter custom system prompt (optional)...',
        border: OutlineInputBorder(),
      ),
      onChanged: widget.onChanged,
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
