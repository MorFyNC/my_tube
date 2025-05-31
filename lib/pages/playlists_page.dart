import 'package:flutter/material.dart';
import 'package:my_tube/pages/playlist_videos_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlaylistsPage extends StatefulWidget {
  final int channelId;

  const PlaylistsPage({
    required this.channelId,
    super.key,
  });

  @override
  State<PlaylistsPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistsPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _playlists = [];
  bool _loading = true;
  bool _myChannel = false;

  @override
  void initState() {
    super.initState();
    _isMyChannel();
    _loadPlaylists();
  }

  Future<void> _isMyChannel() async {
    final usersChannel = await supabase
      .from('channel')
      .select()
      .eq('id', widget.channelId)
      .eq('user_id', supabase.auth.currentUser!.id)
      .maybeSingle();

    if(!mounted) return;
    setState(() {
      _myChannel = usersChannel != null;
    });
  }

  Future<void> _loadPlaylists() async {
    final supabase = Supabase.instance.client;

    var playlists = await supabase.from('playlist')
      .select('*, playlist_video(count)')
      .eq('channel_id', widget.channelId)
      .order('created_at', ascending: false);

    if (!mounted) return;

    setState(() {
      _playlists = playlists;
      _loading = false;
    });
  }

  void _showCreatePlaylistDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
            return AlertDialog(
              title: const Text('Создать плейлист'),
              content: SingleChildScrollView(
                child: Column(
                  spacing: 12,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Название'),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Описание'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Отмена'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: const Text('Создать'),
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final description = descriptionController.text.trim();

                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Введите название плейлиста')),
                      );
                      return;
                    }
                    final supabase = Supabase.instance.client;

                    await supabase.from('playlist').insert({
                      'name': title,
                      'description': description,
                      'channel_id': widget.channelId,
                      'created_at': DateTime.now().toIso8601String(),
                    });

                    Navigator.of(context).pop();
                    _loadPlaylists();
                  },
                ),
              ],
            );
          },
        );
      }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text('Плейлисты', style: TextStyle(
            fontWeight: FontWeight.bold
          ),),
          ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [IconButton(onPressed: () {}, icon: Icon(Icons.abc, color: Colors.transparent))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(child: SizedBox
            (
            width: 750, 
            child: ListView.builder(
              itemCount: _playlists.length,
              itemBuilder: (context, index) {
                final p = _playlists[index];

                final imageUrl = p['image'] ?? '';
                final title = p['name'] ?? 'Без названия';
                final description = p['description'] ?? '';
                final count = (p['playlist_video'] as List).first['count'] ?? 0;
                return ListTile(
                  contentPadding: const EdgeInsets.all(8),
                  leading: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.playlist_play, size: 40),
                  title: Text(title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$count видео'),
                      if (description.isNotEmpty)
                        Text(description,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => 
                        PlaylistVideosPage(playlistId: p['id'])
                        ) 
                      );
                  },
                );
              },
            ),
            )
          ),
            
      floatingActionButton:  _myChannel ? FloatingActionButton(
        onPressed: _showCreatePlaylistDialog,
        tooltip: 'Создать плейлист',
        child: const Icon(Icons.add),
      ) : null,
    );
  }
}
