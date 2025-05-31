import 'package:flutter/material.dart';
import 'package:my_tube/services/video_service.dart';
import 'package:my_tube/widgets/video_list.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  List<VideoWithExtras> _allVideos = [];
  List<VideoWithExtras> _filteredVideos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    final raw = await VideoService().fetchRawVideos();
    final videos = VideoService().mapToVideoWithExtrasList(raw);
    if (!mounted) return;

    setState(() {
      _allVideos = videos;
      _filteredVideos = videos;
      _loading = false;
    });
  }

  void _filter(String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) {
      setState(() => _filteredVideos = _allVideos);
      return;
    }

    final filtered = _allVideos.where((v) {
      final name = v.name.toLowerCase();
      return name.contains(trimmed);
    }).toList();

    setState(() => _filteredVideos = filtered);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Поиск видео')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Введите название видео',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () => _filter(_controller.text),
                      ),
                    ),
                    onChanged: _filter,
                  ),
                ),
                Expanded(
                  child: _filteredVideos.isEmpty
                      ? const Center(child: Text('Ничего не найдено'))
                      : VideoList(
                        key: ValueKey(_filteredVideos.length.toString() + _controller.text),
                        videos: _filteredVideos,
                      ),
                ),
              ],
            ),
    );
  }
}
