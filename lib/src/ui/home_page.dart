import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/dependencies.dart';
import '../config/app_config.dart';
import 'components/app_sidebar.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(chatHistoryProvider);
    final controller = TextEditingController();

    // Initialize connection status (safely)
    ref.watch(initConnectionStatusProvider);

    // Check screen size for responsive layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 768; // Breakpoint for wide screens

    if (isWideScreen) {
      // Two-pane layout for wide screens
      return Scaffold(
        body: Row(
          children: [
            // Sidebar
            const AppSidebar(),
            
            // Main chat area
            Expanded(
              child: _buildChatArea(context, ref, messages, controller),
            ),
          ],
        ),
      );
    } else {
      // Single-pane layout for narrow screens with drawer
      return Scaffold(
        appBar: AppBar(
          title: const Text('ello.AI'),
          actions: [
            // Theme toggle for narrow screens
            Consumer(
              builder: (context, ref, _) {
                final config = ref.watch(appConfigProvider);
                return IconButton(
                  icon: Icon(_getThemeIcon(config.themeMode)),
                  onPressed: () => _showThemeBottomSheet(context, ref),
                );
              },
            ),
          ],
        ),
        drawer: const Drawer(
          child: AppSidebar(),
        ),
        body: _buildChatArea(context, ref, messages, controller),
      );
    }
  }

  Widget _buildChatArea(BuildContext context, WidgetRef ref, List messages, TextEditingController controller) {
    return Column(
      children: [
        // Chat messages
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            // Performance optimization: cache extent for smooth scrolling
            cacheExtent: 1000,
            itemBuilder: (context, index) {
              final msg = messages[index];
              return RepaintBoundary(
                // Performance optimization: isolate repaints per message
                child: Align(
                  alignment: msg.isUser 
                      ? Alignment.centerRight 
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
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
                          enableInteractiveSelection: true,
                          style: Theme.of(context).textTheme.bodyMedium,
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

                        // Show error handling buttons if needed
                        if (!msg.isUser && msg.content.contains('Error'))
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Wrap(
                              spacing: 8,
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
                                    if (!ref.read(useMockGrpcProvider)) {
                                      ref
                                          .read(useMockGrpcProvider.notifier)
                                          .toggle();

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Mock Mode enabled - using simulated responses'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    } else {
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
                                    ref
                                        .read(currentChatClientProvider.notifier)
                                        .updateClient();

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
                ),
              );
            },
          ),
        ),
        
        // Input area - performance optimization: separate repaint boundary
        RepaintBoundary(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    onSubmitted: (value) {
                      ref.read(chatProvider.notifier).sendMessage(value.trim());
                      controller.clear();
                    },
                    decoration: const InputDecoration(
                      hintText: 'Say something...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    ref
                        .read(chatProvider.notifier)
                        .sendMessage(controller.text.trim());
                    controller.clear();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  void _showThemeBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final config = ref.watch(appConfigProvider);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Choose Theme', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.brightness_auto),
                title: const Text('System'),
                trailing: config.themeMode == ThemeMode.system ? const Icon(Icons.check) : null,
                onTap: () {
                  ref.read(appConfigProvider.notifier).setThemeMode(ThemeMode.system);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.light_mode),
                title: const Text('Light'),
                trailing: config.themeMode == ThemeMode.light ? const Icon(Icons.check) : null,
                onTap: () {
                  ref.read(appConfigProvider.notifier).setThemeMode(ThemeMode.light);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Dark'),
                trailing: config.themeMode == ThemeMode.dark ? const Icon(Icons.check) : null,
                onTap: () {
                  ref.read(appConfigProvider.notifier).setThemeMode(ThemeMode.dark);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          );
        },
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
