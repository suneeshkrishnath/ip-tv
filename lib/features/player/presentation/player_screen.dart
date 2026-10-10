import 'package:flutter/material.dart';
import 'package:ip_tv/features/channels/domain/models/channel.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({required this.channel, super.key});

  final Channel channel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(channel.name)),
      body: Center(
        child: Text(
          channel.streamUrl,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}