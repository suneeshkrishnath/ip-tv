import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ip_tv/features/disclaimer/application/disclaimer_providers.dart';

const disclaimerTitle = '😂 ഒരു ചെറിയ മുന്നറിയിപ്പ്! 📺👀';
const disclaimerMessage =
    'ടിവി കണ്ടോ, കണ്ടോ… മണിക്കൂറുകളോളം കണ്ണും തുറിച്ച് ഇരുന്ന് കണ്ണിന് വല്ല പണിയും '
    'കിട്ടിയാൽ, അതിന് എന്നെ കുറ്റം പറയാൻ വരല്ലേട്ടോ! 🤣\n\n'
    'കണ്ണ് നിങ്ങളുടേത്, ടിവി കാണുന്നത് നിങ്ങള്, ഉത്തരവാദിത്തവും നിങ്ങള് തന്നെ! 😜 '
    'ഇടയ്ക്കൊക്കെ കണ്ണിന് വിശ്രമം കൊടുക്കണം, കേട്ടോ… അല്ലെങ്കിൽ പിന്നെ എന്നോട് '
    'പരാതി പറഞ്ഞിട്ട് കാര്യമില്ല! 😂';
const disclaimerCheckboxLabel = 'ഞാൻ മനസ്സിലാക്കി';
const disclaimerConfirmLabel = 'ശരി';

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
