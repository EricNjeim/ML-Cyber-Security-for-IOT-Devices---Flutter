import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iotframework/features/security/presentation/widgets/ongoing_attacks_list.dart';
import 'package:iotframework/features/security/presentation/providers/ongoing_attacks_provider.dart';

class SecurityLogsScreen extends ConsumerWidget {
  const SecurityLogsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ongoingAttacksState = ref.watch(ongoingAttacksProvider);

    return Scaffold(
      appBar: AppBar(
        title: ongoingAttacksState.when(
          data: (attacks) => Text('Ongoing Attacks (${attacks.length})'),
          loading: () => const Text('Ongoing Attacks'),
          error: (_, __) => const Text('Ongoing Attacks'),
        ),
        automaticallyImplyLeading: false,
      ),
      body: const OngoingAttacksList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            ref.read(ongoingAttacksProvider.notifier).loadOngoingAttacks(),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
