import 'package:flutter/material.dart';
import 'package:my_tube/services/video_service.dart';
import 'package:my_tube/widgets/video_list.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  List<dynamic> _allTags = [];
  List<dynamic> _selectedTags = []; 

  @override
  void initState() {
    super.initState();
    _loadVideos();
    _loadTags();
  }

  Future<void> _loadTags() async {
    final response = await Supabase.instance.client.from('tag').select('*');

    setState(() {
      _allTags = response as List<dynamic>;
    });
  }

  void _filter(String query) async {
    final trimmed = query.trim().toLowerCase();
    final hasTags = _selectedTags.isNotEmpty;

    final filtered = await Future.wait(
      _allVideos.map((v) async {
        final nameMatches = v.name.toLowerCase().contains(trimmed);

        if (!hasTags) return nameMatches;

        // Получаем ID тэгов для видео асинхронно
        final videoTagIds = await _getTagIdsForVideo(v.id);

        // Проверяем пересечение выбранных тэгов с тэгами видео
        final selectedTagIds = _selectedTags.map((t) => t['id']).toSet();
        final tagMatches = videoTagIds.intersection(selectedTagIds).isNotEmpty;

        return nameMatches && tagMatches;
      }).toList(),
    );

    // Отфильтровываем видео, которые удовлетворяют фильтрам
    setState(() {
      _filteredVideos = _allVideos
          .asMap()
          .entries
          .where((entry) => filtered[entry.key]) // фильтрация по результатам
          .map((entry) => entry.value)
          .toList();
    });
  }

// Асинхронный метод для получения tag_id для видео
  Future<Set<int>> _getTagIdsForVideo(int videoId) async {
    final response = await Supabase.instance.client
        .from('video_tags')
        .select('tag_id')
        .eq('video_id', videoId);

    final tagIds = (response as List<dynamic>)
        .map((tag) => tag['tag_id'] as int)
        .toSet();
    return tagIds;
  }



  Future<void> _loadVideos() async {
    final raw = await VideoService().fetchRawVideos();
    final videos = await VideoService().mapToVideoWithExtrasList(raw);
    if (!mounted) return;

    setState(() {
      _allVideos = videos;
      _filteredVideos = videos;
      _loading = false;
    });
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
                if (_allTags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allTags.map((tag) {
                        final isSelected = _selectedTags.any((t) => t['id'] == tag['id']);
                        return FilterChip(
                          label: Text(tag['name']),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTags.add(tag);
                              } else {
                                _selectedTags.removeWhere((t) => t['id'] == tag['id']);
                              }
                            });
                            _filter(_controller.text);
                          },
                        );
                      }).toList(),
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
