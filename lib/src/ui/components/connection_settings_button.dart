import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/llm_providers.dart';
import '../settings/grpc_settings_screen.dart';

class ConnectionSettingsButton extends ConsumerWidget {
  const ConnectionSettingsButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.settings),
      tooltip: 'Configure Connection Settings',
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const GrpcSettingsScreen(),
          ),
        );
      },
    );
  }
}
