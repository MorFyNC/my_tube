import 'package:flutter/material.dart';
import 'package:my_tube/services/video_service.dart';
import 'package:my_tube/widgets/video_list.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryPage extends StatefulWidget{
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _historyPageState();
}

class _historyPageState extends State<HistoryPage> {
  final supabase = Supabase.instance.client;
  final _videoService = VideoService();
  List<VideoWithExtras>? _videos;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final viewResponse = await supabase
      .from('views')
      .select()
      .eq('user_id', supabase.auth.currentUser!.id)
      .order('created_at', ascending: false);

    final rawVideos = await _videoService.fetchRawVideos();

    final viewedVideoIds = viewResponse.map((view) => view['video_id'] as int).toList();

    final filteredVideos = rawVideos.where(
      (x) => viewedVideoIds.contains(x['id']))
      .toList();

    filteredVideos.sort((a, b) {
      final aView = viewResponse.firstWhere((v) => v['video_id'] == a['id']);
      final bView = viewResponse.firstWhere((v) => v['video_id'] == b['id']);
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
            'История просмотра',
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
          'История пуста',
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