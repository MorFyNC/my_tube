import 'package:flutter/material.dart';
import 'package:my_tube/services/video_service.dart';
import 'package:my_tube/widgets/video_list.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlaylistVideosPage extends StatefulWidget{
  final int playlistId;
  const PlaylistVideosPage({super.key, required this.playlistId});

  @override
  State<StatefulWidget> createState() => _PlaylistVideosPageState();
}

class _PlaylistVideosPageState extends State<PlaylistVideosPage> {
  final supabase = Supabase.instance.client;
  final _videoService = VideoService();
  List<VideoWithExtras>? _videos;
  bool _loading = true;

  @override
  void initState() {
    _loadVideos();
    super.initState();
  }

  Future<void> _loadVideos() async {
    final playlistVideos = await supabase
      .from('playlist_video')
      .select('video_id')
      .eq('playlist_id', widget.playlistId);

    final videoIds = (playlistVideos as List)
      .map((item) => item['video_id'] as int)
      .toList();

    final raw = await _videoService.fetchRawVideos();
    final videoWithExtrasList = _videoService.mapToVideoWithExtrasList(raw)
      .where((x) => videoIds.contains(x.id)).toList();

    videoWithExtrasList.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if(!mounted) return;

    setState(() {
      _videos = videoWithExtrasList;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text('Плейлист', style: TextStyle(
            fontWeight: FontWeight.bold
          ),),
          ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [IconButton(onPressed: () {}, icon: Icon(Icons.abc, color: Colors.transparent))],
      ),
      body: _loading ? Center(
        child: CircularProgressIndicator(),
        ) : _videos!.isEmpty ? Center(
            child: Text(
            'Здесь пока пусто..',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 36
            ),
          ),
        ) : Center( child: SizedBox(
          width: 750,
          child: 
            VideoList(videos: _videos!, playlistId: widget.playlistId,)
        ) 
        ),

    );
  }
}