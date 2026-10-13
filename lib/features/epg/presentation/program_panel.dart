import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ip_tv/features/channels/domain/models/channel.dart';
import 'package:ip_tv/features/epg/application/epg_providers.dart';
import 'package:ip_tv/features/epg/domain/models/program.dart';

String formatProgramTime(BuildContext context, DateTime time) =>
    TimeOfDay.fromDateTime(time.toLocal()).format(context);

/// Now/next summary for [channel] with a button that opens the schedule.
class ProgramPanel extends ConsumerWidget {
  const ProgramPanel({required this.channel, this.clock, super.key});

  final Channel channel;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guide = ref.watch(epgGuideProvider).value;
    if (guide == null) return const SizedBox.shrink();

    final now = (clock ?? DateTime.now)();
    final current = guide.currentProgram(channel.epgId, now);
    final next = guide.nextProgram(channel.epgId, now);
    final schedule = guide.scheduleFor(channel.epgId, now);
    if (schedule.isEmpty) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (current != null)
                    Text(
                      'Now: ${current.title}',
                      style: textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (next != null)
                    Text(
                      'Next ${formatProgramTime(context, next.start)}: '
                      '${next.title}',
                      style: textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (context) => ProgramScheduleSheet(
                  channelName: channel.name,
                  programs: schedule,
                  now: now,
                ),
              ),
              child: const Text('Schedule'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProgramScheduleSheet extends StatelessWidget {
  const ProgramScheduleSheet({
    required this.channelName,
    required this.programs,
    required this.now,
    super.key,
  });

  final String channelName;
  final List<Program> programs;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      builder: (context, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '$channelName schedule',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: controller,
              itemCount: programs.length,
              itemBuilder: (context, index) {
                final program = programs[index];
                final isLive =
                    !program.start.isAfter(now) && program.end.isAfter(now);
                return ListTile(
                  selected: isLive,
                  title: Text(program.title),
                  subtitle: Text(
                    '${formatProgramTime(context, program.start)} - '
                    '${formatProgramTime(context, program.end)}',
                  ),
                  trailing: isLive ? const Text('LIVE') : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
