import 'package:flutter/material.dart';
import 'package:my_tube/services/video_service.dart';
import 'package:my_tube/widgets/video_list.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<VideoWithExtras>? _videos;
  final _videoService = VideoService(client: Supabase.instance.client);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    final raw = await _videoService.fetchRawVideos();
    final videosList = _videoService.mapToVideoWithExtrasList(raw);
    
    if(!mounted) return;
    
    setState(() {
      _loading = false;
      _videos = videosList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading ? 
        Center(child: CircularProgressIndicator(),) : 
        _videos!.isEmpty ? 
          Center(
            child: 
              Text(
                "Здесь пока ничего нет", 
                style: 
                  TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 36)
                  )
                ) : 
        Center(child: SizedBox(width: 750, child: VideoList(videos: _videos!))),
    );
  }
}