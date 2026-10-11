import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ip_tv/core/errors/app_failure.dart';
import 'package:ip_tv/core/utils/mask_url.dart';
import 'package:ip_tv/features/channels/application/channel_providers.dart';
import 'package:ip_tv/features/playlists/domain/models/playlist_source.dart';
import 'package:ip_tv/shared/widgets/error_view.dart';
import 'package:ip_tv/shared/widgets/loading_widget.dart';

class ManagePlaylistsScreen extends ConsumerWidget {
  const ManagePlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sources = ref.watch(playlistSourcesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Playlists')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add playlist'),
      ),
      body: SafeArea(
        child: sources.when(
          loading: () => const LoadingWidget(label: 'Loading playlists'),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(playlistSourcesProvider),
          ),
          data: (items) => ListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: items.length,
            itemBuilder: (context, index) => _PlaylistTile(
              source: items[index],
              onRefresh: () => _refresh(context, ref, items[index]),
              onEdit: () => _showEditor(context, ref, items[index]),
              onDelete: () => _confirmDelete(context, ref, items[index]),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refresh(
    BuildContext context,
    WidgetRef ref,
    PlaylistSource source,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    ref.read(selectedPlaylistSourceProvider.notifier).select(source);
    await ref.read(currentPlaylistProvider.notifier).loadSource(source);
    final state = ref.read(currentPlaylistProvider);
    final error = state.error;
    final message = error != null
        ? (error is AppFailure
            ? error.userMessage
            : 'Unable to refresh playlist.')
        : ref.read(playlistOfflineProvider)
            ? 'Could not refresh ${source.name}. Showing saved channels.'
            : '${source.name} updated (${state.value?.channels.length ?? 0} channels).';
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showEditor(
    BuildContext context,
    WidgetRef ref, [
    PlaylistSource? existing,
  ]) async {
    final messenger = ScaffoldMessenger.of(context);
    final failure = await showDialog<AppFailure?>(
      context: context,
      builder: (context) => _PlaylistEditorDialog(existing: existing),
    );
    if (failure != null) {
      messenger.showSnackBar(SnackBar(content: Text(failure.userMessage)));
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    PlaylistSource source,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete playlist?'),
        content: Text('"${source.name}" and its cached channels will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final failure =
        await ref.read(playlistSourcesProvider.notifier).delete(source);
    if (failure != null) {
      messenger.showSnackBar(SnackBar(content: Text(failure.userMessage)));
    }
  }
}

class _PlaylistTile extends StatelessWidget {
  const _PlaylistTile({
    required this.source,
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
  });

  final PlaylistSource source;
  final VoidCallback onRefresh;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(source.isBuiltIn ? Icons.public : Icons.playlist_play),
      title: Text(source.name),
      subtitle: Text(
        source.isBuiltIn ? 'Built-in playlist' : maskUrl(source.url),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: onRefresh,
          ),
          if (!source.isBuiltIn) ...[
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete),
              onPressed: onDelete,
            ),
          ],
        ],
      ),
    );
  }
}

class _PlaylistEditorDialog extends ConsumerStatefulWidget {
  const _PlaylistEditorDialog({this.existing});

  final PlaylistSource? existing;

  @override
  ConsumerState<_PlaylistEditorDialog> createState() =>
      _PlaylistEditorDialogState();
}

class _PlaylistEditorDialogState extends ConsumerState<_PlaylistEditorDialog> {
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _url = TextEditingController(text: widget.existing?.url);
  late final _epgUrl = TextEditingController(text: widget.existing?.epgUrl);
  String? _error;
  bool _saving = false;
  bool _hideUrls = true;

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _epgUrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final notifier = ref.read(playlistSourcesProvider.notifier);
    final existing = widget.existing;
    final failure = existing == null
        ? await notifier.add(
            name: _name.text,
            url: _url.text,
            epgUrl: _epgUrl.text,
          )
        : await notifier.edit(
            existing,
            name: _name.text,
            url: _url.text,
            epgUrl: _epgUrl.text,
          );
    if (!mounted) return;
    if (failure is PlaylistValidationFailure) {
      setState(() {
        _saving = false;
        _error = failure.message;
      });
      return;
    }
    Navigator.of(context).pop(failure);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add playlist' : 'Edit playlist'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _url,
              keyboardType: TextInputType.url,
              obscureText: _hideUrls,
              decoration: InputDecoration(
                labelText: 'M3U URL',
                errorText: _error,
                errorMaxLines: 2,
                suffixIcon: IconButton(
                  tooltip: _hideUrls ? 'Show URLs' : 'Hide URLs',
                  icon: Icon(
                    _hideUrls ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _hideUrls = !_hideUrls),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _epgUrl,
              keyboardType: TextInputType.url,
              obscureText: _hideUrls,
              decoration: const InputDecoration(
                labelText: 'Guide (XMLTV) URL - optional',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
