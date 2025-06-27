// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_tube/services/video_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/video_list.dart';

class UploadVideoPage extends StatefulWidget {
  const UploadVideoPage({super.key});

  @override
  State<UploadVideoPage> createState() => _UploadVideoPageState();
}

class _UploadVideoPageState extends State<UploadVideoPage> {
  List<dynamic> _allTags = [];
  List<dynamic> _selectedTags = [];
  File? _videoFile;
  File? _imageFile;
  String _name = '';
  String _description = '';
  bool _uploading = false;
  bool _hasChannel = true;
  bool _loading = true;
  final _formKey = GlobalKey<FormState>();
  Channel? _channel;

  @override
  void initState() {
    super.initState();
    _userHasChannel();
    _fetchTags();
  }

  Future<void> _fetchTags() async {
  final response = await Supabase.instance.client
    .from('tag')
    .select('*');

  if (mounted) {
    setState(() {
      _allTags = response as List<dynamic>;
    });
  } 
  }

  Future<void> _userHasChannel() async {
  try {
    final channel = await Supabase.instance.client
        .from('channel')
        .select('*')
        .eq('user_id', Supabase.instance.client.auth.currentUser!.id)
        .maybeSingle();

    if (!mounted) return;

    if (channel == null) {
      setState(() {
        _hasChannel = false;
        _loading = false;
      });
    } else {
      setState(() {
        _channel = Channel.fromMap(channel);
        _hasChannel = true;
        _loading = false;
      });
    }
  } catch (e) {
    if (!mounted) return;
    setState(() {
      _hasChannel = false;
      _loading = false;
    });
  }
}


  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _videoFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _uploadVideo() async {
    if (!_formKey.currentState!.validate() || _videoFile == null || _imageFile == null) return;

    setState(() => _uploading = true);
    final supabase = Supabase.instance.client;

    try {
      final videoFilename = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final imageFilename = 'preview_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await supabase.storage.from('videos').upload(videoFilename, _videoFile!);

      await supabase.storage.from('thumbnails').upload(imageFilename, _imageFile!);

      final channel = await Supabase.instance.client
        .from('channel')
        .select('id')
        .eq('user_id', Supabase.instance.client.auth.currentUser!.id)
        .single();

      final channelId = channel['id'];

      await supabase.from('video').insert({
        'name': _name,
        'description': _description,
        'video': videoFilename,
        'image': imageFilename,
        'channel_id': channelId,
      });

      final insertResponse = await supabase.from('video').insert({
        'name': _name,
        'description': _description,
        'video': videoFilename,
        'image': imageFilename,
        'channel_id': channelId,
      }).select().single();

      final videoId = insertResponse['id'];

      for (final tag in _selectedTags) {
        await supabase.from('video_tags').insert({
          'video_id': videoId,
          'tag_id': tag['id'],
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Видео успешно загружено')),
        );
        setState(() {
          _name = '';
          _description = '';
          _videoFile = null;
          _imageFile = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки: $e')),
      );
    } finally {
      setState(() => _uploading = false);
    }
  }

  void _chooseTags() async {
  final selected = await showDialog<List<dynamic>>(
    context: context,
    builder: (context) {
      List<dynamic> tempSelected = List<dynamic>.from(_selectedTags);

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Выберите тэги'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _allTags.map((tag) {
                  final isChecked = tempSelected.any((t) => t['id'] == tag['id']);
                  return CheckboxListTile(
                    value: isChecked,
                    title: Text(tag['name']),
                    onChanged: (bool? checked) {
                      setState(() {
                        if (checked == true) {
                          if (!isChecked) tempSelected.add(tag);
                        } else {
                          tempSelected.removeWhere((t) => t['id'] == tag['id']);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, tempSelected),
                child: const Text('Выбрать'),
              ),
            ],
          );
        },
      );
    },
  );

  if (selected != null) {
    setState(() {
      _selectedTags = selected;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    final preview = _videoFile != null && _imageFile != null
    ? VideoWithExtras(
        id: 0,
        createdAt: DateTime.now(),
        name: _name,
        description: _description,
        videoUrl: '',
        imageUrl: '', 
        channel: _channel!,
        viewCount: 0,
        localImageFile: _imageFile, 
      )
    : null;


    return Scaffold(
      appBar: AppBar(title: Center(child: const Text('Загрузка видео'))),
      body: _loading ? Center(child: CircularProgressIndicator()) : _hasChannel ? Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Form(
              key: _formKey,
              child: Column(
                spacing: 12,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Название видео'),
                    onChanged: (val) => setState(() => _name = val),
                    validator: (val) => val == null || val.isEmpty ? 'Введите название' : null,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Описание'),
                    maxLines: 3,
                    onChanged: (val) => setState(() => _description = val),
                    validator: (val) => val == null || val.isEmpty ? 'Введите описание' : null,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.video_library),
                    onPressed: _pickVideo,
                    label: const Text('Выбрать видео'),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.image),
                    onPressed: _pickImage,
                    label: const Text('Выбрать превью'),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.tag),
                    onPressed: _chooseTags,
                    label: const Text('Выбрать тэги')
                  ),
                  const SizedBox(height: 20),
                  if (_uploading) const CircularProgressIndicator(),
                  if (!_uploading)
                    ElevatedButton(
                      onPressed: _uploadVideo,
                      child: const Text('Загрузить видео'),
                    ),
                  const SizedBox(height: 30),
                  if (preview != null) ...[
                    const Text('Предпросмотр:'),
                    SizedBox(
                      height: 300,
                      width: 500,
                      child: VideoList(videos: [preview], enableTap: false,),
                    )
                  ],
                ],
              ),
            ),
          ],
        ),
      ) : Center(
        child: 
          Text('Вам необходимо создать канал, для того чтобы загружать видео',
           style: 
            TextStyle(fontSize: 36,
            fontWeight: FontWeight.bold))),
    );
  }
}
