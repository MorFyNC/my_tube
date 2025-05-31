import 'package:flutter/material.dart';
import 'package:my_tube/services/video_service.dart';
import 'package:my_tube/widgets/video_list.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChannelVideosPage extends StatefulWidget{
  final int channelId;
  final bool isMyChannel;
  const ChannelVideosPage({super.key, required this.channelId, this.isMyChannel = false});

  @override
  State<ChannelVideosPage> createState() => _ChannelVideosPageState();
}

class _ChannelVideosPageState extends State<ChannelVideosPage> {
  final supabase = Supabase.instance.client;
  final _videoService = VideoService();
  List<VideoWithExtras>? _videos;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {

    final rawVideos = await _videoService.fetchRawVideos();

    final filteredVideos = rawVideos.where(
      (x) => x['channel']['id'] == widget.channelId)
      .toList();

    filteredVideos.sort((a, b) {
      final dateA = DateTime.parse(a['created_at']);
      final dateB = DateTime.parse(b['created_at']);
    return dateB.compareTo(dateA);
  });

    if(!mounted) return;

    setState(() {
      _videos = _videoService.mapToVideoWithExtrasList(filteredVideos);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Видео с канала',
            style: TextStyle(
              fontWeight: FontWeight.bold
            )
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [IconButton(onPressed: () {}, icon: Icon(Icons.abc, color: Colors.transparent))],
      ),
      backgroundColor: Colors.white,
      body: _loading ? Center(  
        child: CircularProgressIndicator()
      ) : _videos!.isEmpty ? Center(
        child: Text(
          'Здесь пока пусто..',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 36
          ),
        ),
      ) : Center(
            child: SizedBox(
              width: 750,
              child:               
                VideoList(videos: _videos!, enableAddingToPlaylist: widget.isMyChannel,)
            )
        ),
    );
  }
}