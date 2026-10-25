import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ip_tv/core/errors/app_failure.dart';
import 'package:ip_tv/core/result/result.dart';
import 'package:ip_tv/features/channels/application/channel_providers.dart';
import 'package:ip_tv/features/epg/application/epg_providers.dart';
import 'package:ip_tv/features/settings/application/settings_providers.dart';
import 'package:ip_tv/features/settings/domain/repositories/settings_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final appInfo = ref.watch(appInfoProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionTitle('Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<AppThemeMode>(
              segments: const [
                ButtonSegment(
                  value: AppThemeMode.system,
                  icon: Icon(Icons.brightness_auto),
                  label: Text('System'),
                ),
                ButtonSegment(
                  value: AppThemeMode.light,
                  icon: Icon(Icons.light_mode),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: AppThemeMode.dark,
                  icon: Icon(Icons.dark_mode),
                  label: Text('Dark'),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (selection) =>
                  _setTheme(context, ref, selection.single),
            ),
          ),
          const Divider(height: 32),
          const _SectionTitle('Playback data'),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Refresh current playlist'),
            subtitle: const Text('Download the selected playlist again'),
            onTap: () => _refresh(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined),
            title: const Text('Clear cached data'),
            subtitle: const Text('Remove saved channels, guides, and logos'),
            onTap: () => _confirmClear(context, ref),
          ),
          const Divider(height: 32),
          const _SectionTitle('About'),
          appInfo.when(
            loading: () => const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Nerampokku'),
              subtitle: Text('Loading version'),
            ),
            error: (error, _) => ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Nerampokku'),
              subtitle: Text(
                error is AppFailure
                    ? error.userMessage
                    : 'Version information unavailable.',
              ),
            ),
            data: (info) => ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Nerampokku'),
              subtitle: Text('Version ${info.version} (${info.buildNumber})'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setTheme(
    BuildContext context,
    WidgetRef ref,
    AppThemeMode mode,
  ) async {
    final failure = await ref.read(themeModeProvider.notifier).update(mode);
    if (failure != null && context.mounted) _showFailure(context, failure);
  }

  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    final source = ref.read(selectedPlaylistSourceProvider);
    await ref.read(currentPlaylistProvider.notifier).loadSource(source);
    if (!context.mounted) return;
    final state = ref.read(currentPlaylistProvider);
    final failure = state.error;
    if (failure is AppFailure) {
      _showFailure(context, failure);
      return;
    }
    final message = ref.read(playlistOfflineProvider)
        ? 'Refresh failed. Showing saved channels.'
        : '${source.name} refreshed (${state.value?.channels.length ?? 0} channels).';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear cached data?'),
        content: const Text(
          'Saved channel lists, TV guides, and downloaded logos will be '
          'removed. Favorites, watch history, playlist sources, and settings '
          'will stay.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear cache'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref.read(settingsRepositoryProvider).clearCache();
    switch (result) {
      case Success<void>():
        ref.read(currentPlaylistProvider.notifier).clearVisiblePlaylist();
        ref.read(playlistOfflineProvider.notifier).set(false);
        ref.invalidate(epgGuideProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Cached data cleared.')));
        }
      case FailureResult<void>(:final failure):
        if (context.mounted) _showFailure(context, failure);
    }
  }

  void _showFailure(BuildContext context, AppFailure failure) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(failure.userMessage)));
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    child: Text(label, style: Theme.of(context).textTheme.titleSmall),
  );
}
