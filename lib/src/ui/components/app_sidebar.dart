import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dependencies.dart';
import '../debug/debug_settings.dart';
import '../settings/model_picker.dart';
import 'theme_toggle_button.dart';

/// Sidebar for the two-pane layout
class AppSidebar extends ConsumerWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatus = ref.watch(connectionStatusProvider);
    final isMockMode = ref.watch(useMockGrpcProvider);

    return RepaintBoundary(
      // Performance optimization: isolate sidebar repaints
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            right: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            // Header with app name and logo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 24,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'ello.AI',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
            ),

            // Connection status
            Container(
              padding: const EdgeInsets.all(16),
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isMockMode
                          ? 'Mock Mode'
                          : connectionStatus == ConnectionStatus.connected
                              ? 'Connected'
                              : connectionStatus == ConnectionStatus.connecting
                                  ? 'Connecting...'
                                  : 'Disconnected',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),

            // Reset conversation button
            if (ref.watch(hasActiveConversationProvider))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset Conversation'),
                    onPressed: () {
                      ref.read(chatProvider.notifier).resetConversation();
                    },
                  ),
                ),
              ),

            const Divider(),

            // Settings section
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Settings',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Theme settings
                  ListTile(
                    leading: const Icon(Icons.palette),
                    title: const Text('Theme'),
                    trailing: const ThemeToggleButton(),
                    contentPadding: EdgeInsets.zero,
                  ),

                  // Model picker
                  ListTile(
                    leading: const Icon(Icons.smart_toy),
                    title: const Text('AI Model'),
                    trailing: const ModelPicker(),
                    contentPadding: EdgeInsets.zero,
                  ),

                  const SizedBox(height: 16),

                  // Debug settings (only in debug mode)
                  const DebugSettingsButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}