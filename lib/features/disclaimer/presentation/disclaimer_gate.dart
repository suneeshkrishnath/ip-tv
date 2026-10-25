import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ip_tv/features/disclaimer/application/disclaimer_providers.dart';

const disclaimerTitle = 'Disclaimer';
const disclaimerMessage =
    'This app is a media player and does not provide, host, or control the '
    'channels, streams, playlists, or programme information accessed through '
    'it. You are responsible for ensuring that you have the right to access '
    'and view any content you add or play, and for complying with applicable '
    'laws. Content and services may be provided by third parties; the app '
    'does not endorse them and cannot guarantee their availability, accuracy, '
    'legality, or suitability. The app’s developers are not responsible for '
    'third-party content or services, or for your use of them.';
const disclaimerCheckboxLabel = 'I have read and agree';
const disclaimerConfirmLabel = 'Continue';

/// Shows the disclaimer once until the user confirms it.
class DisclaimerGate extends ConsumerStatefulWidget {
  const DisclaimerGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<DisclaimerGate> createState() => _DisclaimerGateState();
}

class _DisclaimerGateState extends ConsumerState<DisclaimerGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !ref.read(disclaimerAcceptedProvider)) _show();
    });
  }

  Future<void> _show() async {
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _DisclaimerDialog(),
    );
    if (accepted ?? false) {
      await ref.read(disclaimerAcceptedProvider.notifier).accept();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _DisclaimerDialog extends StatefulWidget {
  const _DisclaimerDialog();

  @override
  State<_DisclaimerDialog> createState() => _DisclaimerDialogState();
}

class _DisclaimerDialogState extends State<_DisclaimerDialog> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text(disclaimerTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(disclaimerMessage),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _confirmed,
                onChanged: (value) =>
                    setState(() => _confirmed = value ?? false),
                title: const Text(disclaimerCheckboxLabel),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: _confirmed ? () => Navigator.of(context).pop(true) : null,
            child: const Text(disclaimerConfirmLabel),
          ),
        ],
      ),
    );
  }
}
