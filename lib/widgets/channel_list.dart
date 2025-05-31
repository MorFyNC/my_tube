import 'package:flutter/material.dart';
import 'package:my_tube/pages/channel_page.dart';
import 'package:my_tube/services/video_service.dart';

class ChannelList extends StatelessWidget {
  final List<Map<String, dynamic>> channels;

  const ChannelList({super.key, required this.channels});

  @override
  Widget build(BuildContext context) {
    if (channels.isEmpty) {
      return const Center(child: Text('Нет доступных каналов'));
    }

    return ListView.separated(
      itemCount: channels.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final channel = Channel.fromMap(channels[index]);
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: channel.image != null
                ? NetworkImage(channel.image!)
                : null,
            backgroundColor: Colors.grey[300],
            child: channel.image == null
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(channel.name),
          subtitle: Text(
            channel.description ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChannelPage(channel: channel),
              ),
            );
          },
        );
      },
    );
  }
}
