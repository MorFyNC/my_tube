import 'package:flutter/material.dart';
import 'package:my_tube/services/video_service.dart';
import 'package:my_tube/widgets/video_list.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LikedPage extends StatefulWidget{
  const LikedPage({super.key});

  @override
  State<LikedPage> createState() => _likedPageState();
}

class _likedPageState extends State<LikedPage> {
  final supabase = Supabase.instance.client;
  final _videoService = VideoService();
  List<VideoWithExtras>? _videos;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLiked();
  }

  Future<void> _loadLiked() async {
    final likesResponse = await supabase
      .from('liked_disliked')
      .select()
      .eq('user_id', supabase.auth.currentUser!.id)
      .eq('is_liked', true)
      .order('created_at', ascending: false);

    final rawVideos = await _videoService.fetchRawVideos();

    final viewedVideoIds = likesResponse.map((like) => like['video_id'] as int?).toList();

    final filteredVideos = rawVideos.where(
      (x) => viewedVideoIds.contains(x['id']))
      .toList();

    filteredVideos.sort((a, b) {
      final aView = likesResponse.firstWhere((v) => v['video_id'] == a['id']);
      final bView = likesResponse.firstWhere((v) => v['video_id'] == b['id']);
      return bView['created_at'].compareTo(aView['created_at']);
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
            'Лайкнутые видео',
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
          'Здесь пока что пусто..',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 36
          ),
        ),
      ) : Center(
            child: SizedBox(
              width: 750,
              child: 
                VideoList(videos: _videos!)
            )
        ),
    );
  }
}