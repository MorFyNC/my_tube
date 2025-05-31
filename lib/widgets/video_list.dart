import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_tube/services/video_service.dart';
import 'package:my_tube/pages/video_page.dart';

class VideoList extends StatefulWidget {
  final List<VideoWithExtras> videos;
  final bool enableTap;
  final int playlistId;
  final bool enableAddingToPlaylist;

  const VideoList({
    super.key,
    required this.videos,
    this.enableTap = true,
    this.playlistId = 0,
    this.enableAddingToPlaylist = false,
  });

  @override
  State<VideoList> createState() => _VideoListState();
}

class _VideoListState extends State<VideoList> {
  late List<VideoWithExtras> _videos;

  @override
  void initState() {
    super.initState();
    _videos = List.from(widget.videos);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: _videos.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final video = _videos[index];

        final content = Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: video.localImageFile != null
                    ? Image.file(
                        video.localImageFile!,
                        width: 120,
                        height: 70,
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        video.imageUrl,
                        width: 120,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(width: 120, height: 70, color: Colors.grey),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            video.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${video.viewCount} просмотров',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            video.channel.name,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        Text(
                          'Создано: ${_formatDate(video.createdAt)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[800],
                          ),
                        )
                      ],
                    ),
                    Text(
                      video.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (widget.playlistId != 0)
                IconButton(
                  icon: const Icon(Icons.playlist_remove),
                  onPressed: () => _removeFromPlaylist(video.id),
                ),
              if (widget.enableAddingToPlaylist)
                IconButton(
                  icon: const Icon(Icons.playlist_add),
                  onPressed: () => _showAddToPlaylistDialog(video.id),
                ),
            ],
          ),
        );

        return widget.enableTap
            ? InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VideoPage(video: video),
                    ),
                  );
                },
                child: content,
              )
            : content;
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  Future<void> _removeFromPlaylist(int videoId) async {
    final supabase = Supabase.instance.client;

    await supabase
        .from('playlist_video')
        .delete()
        .match({'playlist_id': widget.playlistId, 'video_id': videoId});

    setState(() {
      _videos.removeWhere((v) => v.id == videoId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Видео удалено из плейлиста')),
    );
  }

  Future<void> _showAddToPlaylistDialog(int videoId) async {
    final supabase = Supabase.instance.client;

    final channelRes = await supabase
        .from('channel')
        .select('id')
        .eq('user_id', supabase.auth.currentUser!.id)
        .maybeSingle();

    if (channelRes == null) return;

    final playlists = await supabase
        .from('playlist')
        .select('id, name')
        .eq('channel_id', channelRes['id']);

    int? selectedPlaylistId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Добавить в плейлист'),
            content: DropdownButtonFormField<int>(
              value: selectedPlaylistId,
              hint: const Text('Выберите плейлист'),
              items: playlists
                  .map<DropdownMenuItem<int>>((pl) => DropdownMenuItem<int>(
                        value: pl['id'],
                        child: Text(pl['name']),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => selectedPlaylistId = value),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: selectedPlaylistId == null
                    ? null
                    : () async {
                        await supabase.from('playlist_video').insert({
                          'playlist_id': selectedPlaylistId,
                          'video_id': videoId,
                        });

                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Добавлено в плейлист')),
                        );
                      },
                child: const Text('ОК'),
              ),
            ],
          ),
        );
      },
    );
  }
}
