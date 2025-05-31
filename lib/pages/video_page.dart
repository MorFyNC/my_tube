// ignore_for_file: deprecated_member_use, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:my_tube/pages/channel_page.dart';
import 'package:my_tube/widgets/comments.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:my_tube/services/video_service.dart';

class VideoPage extends StatefulWidget {
  final VideoWithExtras video;

  const VideoPage({super.key, required this.video});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isLiked = false;
  bool _isDisliked = false;
  bool _togglingLikeDislike = false;
  final supabase = Supabase.instance.client;
  int likesCount = 0;
  int dislikesCount = 0;

  @override
  void initState() {
    super.initState();
    if(!mounted) return;
    _checkMyLikesDislikes();
    _checkLikesDislikes();
    _initPlayer();
  }

  void _initPlayer() {
    _controller = VideoPlayerController.network(widget.video.videoUrl)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _isPlaying = _controller.value.isPlaying;
          });
          _controller.play();
          _controller.addListener(() {
            if (mounted) {
              setState(() {
                _isPlaying = _controller.value.isPlaying;
              });
            }
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    _createView();
    super.dispose();
  }

  Future<void> _createView() async {
    var existingView = await Supabase.instance.client
      .from('views')
      .select()
      .eq('user_id', Supabase.instance.client.auth.currentUser!.id)
      .eq('video_id', widget.video.id)
      .order('created_at', ascending: false)
      .limit(1)
      .maybeSingle();
    
    if(existingView != null) {
      await Supabase.instance.client
        .from('views')
        .update({'created_at' : DateTime.now().toIso8601String()})
        .eq('id', existingView['id']);
    }

    await Supabase.instance.client
      .from('views')
      .insert({
        'video_id': widget.video.id,
        'user_id': Supabase.instance.client.auth.currentUser!.id 
      });
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  void _enterFullScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenVideoPage(controller: _controller),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${duration.inHours > 0 ? '${duration.inHours}:' : ''}$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.video;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MyTube'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        children: [
          AspectRatio(
            aspectRatio: _isInitialized ? _controller.value.aspectRatio : 16 / 9,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                _isInitialized
                    ? VideoPlayer(_controller)
                    : const Center(child: CircularProgressIndicator()),
                if (_isInitialized)
                  _buildControls(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(video.description),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(
                      child: Text(
                        video.channel.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChannelPage(channel: video.channel),
                    ),
                  );
                      },
                    ),
                    const SizedBox(width: 16),
                    Text('${video.viewCount} просмотров'),
                    const SizedBox(width: 16),
                    Text('${video.createdAt.day.toString().padLeft(2, '0')}.${video.createdAt.month.toString().padLeft(2, '0')}.${video.createdAt.year}'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                      ),
                      onPressed: () {
                        if(_togglingLikeDislike) return;
                        if(!mounted) return;
                        setState(() {
                          _isLiked = !_isLiked;
                          if (_isLiked && _isDisliked) {
                            _isDisliked = false;
                          }
                        });
                        _toggleLikeDislike();
                      },
                    ),
                    const SizedBox(width: 4),
                    Text(likesCount.toString()),

                    const SizedBox(width: 24),

                    IconButton(
                      icon: Icon(
                        _isDisliked ? Icons.thumb_down_alt : Icons.thumb_down_alt_outlined,
                      ),
                      onPressed: () {
                        if(_togglingLikeDislike) return;
                        if(!mounted) return;
                        setState(() {
                          _isDisliked = !_isDisliked;
                          if (_isDisliked && _isLiked) {
                            _isLiked = false;
                          }
                        });
                        _toggleLikeDislike();
                      },
                    ),
                    const SizedBox(width: 4),
                    Text(dislikesCount.toString()),
                  ],
                ),

              ],
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Комментарии',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          CommentsSection(videoId: widget.video.id)
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
            onPressed: _togglePlayPause,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              _formatDuration(_controller.value.position),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Expanded(
            child: VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              colors: VideoProgressColors(
                playedColor: Colors.yellow,
                backgroundColor: Colors.white30,
                bufferedColor: Colors.white54,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              _formatDuration(_controller.value.duration),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen, color: Colors.white),
            onPressed: _enterFullScreen,
          ),
        ],
      ),
    );
  }

  Future<void> _toggleLikeDislike() async {
    try {
      _togglingLikeDislike = true;
      
      final userId = supabase.auth.currentUser!.id;
      final videoId = widget.video.id;

      if (!_isLiked && !_isDisliked) {
        await supabase
          .from('liked_disliked')
          .delete()
          .eq('video_id', videoId)
          .eq('user_id', userId);

        return;
      }

      final existingRow = await supabase
        .from('liked_disliked')
        .select()
        .eq('video_id', videoId)
        .eq('user_id', userId)
        .maybeSingle();

      final isLikedValue = _isLiked ? true : (_isDisliked ? false : null);

      await (existingRow != null
        ? supabase
            .from('liked_disliked')
            .update({'is_liked': isLikedValue})
            .eq('id', existingRow['id'])
        : supabase
            .from('liked_disliked')
            .insert({
              'video_id': videoId,
              'is_liked': isLikedValue,
              'user_id': userId
            }));
    } finally {
      _togglingLikeDislike = false;
      _checkLikesDislikes();
    }
  }

  Future<void> _checkLikesDislikes() async {
    final likes = await supabase
      .from('liked_disliked')
      .select()
      .eq('video_id', widget.video.id)
      .eq('is_liked', true)
      .count(CountOption.exact);

    final dislikes = await supabase
      .from('liked_disliked')
      .select()
      .eq('video_id', widget.video.id)
      .eq('is_liked', false)
      .count(CountOption.exact);

    if(mounted) {
      setState(() {
        likesCount = likes.count;
        dislikesCount = dislikes.count;
      });
    }
  }

  Future<void> _checkMyLikesDislikes() async {
    var data = await supabase
      .from('liked_disliked')
      .select()
      .eq('video_id', widget.video.id)
      .eq('user_id', supabase.auth.currentUser!.id)
      .maybeSingle();

    if(data == null || !mounted) return;

    setState(() {
      bool liked = data['is_liked'];
      if(liked) {
        _isLiked = true;
      } else {
        _isDisliked = true;
      }
    });
  }

}
class FullScreenVideoPage extends StatefulWidget {
  final VideoPlayerController controller;

  const FullScreenVideoPage({super.key, required this.controller});

  @override
  _FullScreenVideoPageState createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<FullScreenVideoPage> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              VideoPlayer(_controller),
              _buildControls(context),
            ],
          ),
        ),
      ),
    );
  }

 Widget _buildControls(BuildContext context) {
  return Container(
    color: Colors.black54,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: Row(
      children: [
        IconButton(
          icon: Icon(
            _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
          ),
          onPressed: () {
            if (_controller.value.isPlaying) {
              _controller.pause();
            } else {
              _controller.play();
            }
          },
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Text(
            _formatDuration(_controller.value.position),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        Expanded(
          child: VideoProgressIndicator(
            _controller,
            allowScrubbing: true,
            colors: VideoProgressColors(
              playedColor: Colors.yellow,
              backgroundColor: Colors.white30,
              bufferedColor: Colors.white54,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            _formatDuration(_controller.value.duration),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}


  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${duration.inHours > 0 ? '${duration.inHours}:' : ''}$minutes:$seconds';
  }
}
