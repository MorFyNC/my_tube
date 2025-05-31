// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:my_tube/pages/channel_videos_page.dart';
import 'package:my_tube/pages/playlists_page.dart';
import 'package:my_tube/services/video_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class ChannelPage extends StatefulWidget {
  final dynamic channel;
  
  const ChannelPage({super.key, this.channel});

  @override
  State<ChannelPage> createState() => _ChannelPageState();
}

class _ChannelPageState extends State<ChannelPage> {
  final supabase = Supabase.instance.client;
  Channel? _channel;
  int _subscriberCount = 0;
  bool _loading = true;
  bool _myChannel = false;
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _loadChannel();
  }

  Future<void> _loadChannel() async {
    if(widget.channel != null) {
            final countResult = await supabase
          .from('subscribe')
          .select('id')
          .eq('channel_id', widget.channel.id);

      final subscriberCount = countResult.length;

      if(!mounted) return;

      _isSubscribedFetch();

      setState(() {
        _channel = widget.channel;
        _myChannel = _channel!.user_id == supabase.auth.currentUser!.id;
        _subscriberCount = subscriberCount;
        _loading = false;
      });
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final channelResponse = await supabase
          .from('channel')
          .select('*')
          .eq('user_id', user.id)
          .maybeSingle();

      if (!mounted) return;

      if (channelResponse == null) {
        setState(() {
          _channel = null;
          _subscriberCount = 0;
          _loading = false;
        });
        return;
      }

      final channelId = channelResponse['id'] as int;

      final countResult = await supabase
          .from('subscribe')
          .select('id')
          .eq('channel_id', channelId);

      final subscriberCount = countResult.length;

      setState(() {
        _channel = Channel.fromMap(channelResponse);
        _subscriberCount = subscriberCount;
        _myChannel = _channel!.user_id == supabase.auth.currentUser!.id;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _channel = null;
        _subscriberCount = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки канала')),
      );
    }
  }

  Future<void> _isSubscribedFetch() async {
    var mySubscribtion = await supabase
      .from('subscribe')
      .select()
      .eq('channel_id', widget.channel.id)
      .eq('user_id', supabase.auth.currentUser!.id)
      .maybeSingle();

      setState(() {
        _isSubscribed = mySubscribtion != null;
      }); 
  }

  Future<void> _showCreateChannelDialog() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    String name = '';
    String description = '';
    File? imageFile;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Center(child: Text('Создать канал')),
              content: SingleChildScrollView(
                child: Column(
                  spacing: 12,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                        if (picked != null) {
                          setModalState(() {
                            imageFile = File(picked.path);
                          });
                        }
                      },
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: imageFile != null ? FileImage(imageFile!) : null,
                        backgroundColor: Colors.grey[300],
                        child: imageFile == null
                            ? Icon(Icons.camera_alt, size: 30)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(labelText: 'Название канала'),
                      onChanged: (value) => name = value,
                    ),
                    TextField(
                      decoration: InputDecoration(labelText: 'Описание'),
                      onChanged: (value) => description = value,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    String? imageUrl;
                    if (imageFile != null) {
                      final fileExt = path.extension(imageFile!.path);
                      final mimeType = lookupMimeType(imageFile!.path);
                      final storagePath = 'channel_avatars/${user.id}$fileExt';

                      try {
                        await supabase.storage.from('avatars').uploadBinary(
                          storagePath,
                          await imageFile!.readAsBytes(),
                          fileOptions: FileOptions(
                            upsert: true,
                            contentType: mimeType,
                          ),
                        );
                        imageUrl = supabase.storage.from('avatars').getPublicUrl(storagePath);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Ошибка загрузки изображения: $e')),
                        );
                      }
                    }

                    try {
                      await supabase.from('channel').insert({
                        'user_id': user.id,
                        'name': name,
                        'description': description,
                        'image': imageUrl,
                      });
                      Navigator.pop(context);
                      _loadChannel();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Ошибка создания канала: $e')),
                      );
                    }
                  },
                  child: const Text('Создать'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final black = Colors.black;
    final white = Colors.white;
    final grey = Colors.grey[700]!;

    return Scaffold(
      appBar: AppBar(
        title: Center(child: const Text('MyTube', style: TextStyle(fontWeight: FontWeight.bold))),
        backgroundColor: white,
        foregroundColor: black,
        elevation: 0,
        actions: [IconButton(onPressed: () {}, icon: Icon(Icons.abc, color: Colors.transparent))],
      ),
      backgroundColor: white,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _channel == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('У вас еще нет канала'),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _showCreateChannelDialog,
                        child: const Text('Создать канал'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: grey,
                                backgroundImage: _channel!.image != null
                                    ? NetworkImage(_channel!.image!)
                                    : null,
                              ),

                              _myChannel ? Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _updateAvatar,
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.white,
                                    child: Icon(Icons.edit, size: 16, color: black),
                                  ),
                                ),
                              ) : Align(),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _channel!.name,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _myChannel ? GestureDetector(
                            onTap: _updateChannelName,
                            child: Icon(Icons.edit, size: 18, color: grey),
                          ) : Align(),
                        ],
                      ),
                        Text(
                          'Создан: ${_formatDate(_channel!.created_at)}',
                          style: TextStyle(color: grey, fontSize: 12),
                        ),
                      const SizedBox(height: 5),
                      Text(
                        'Подписчиков: $_subscriberCount',
                        style: TextStyle(color: grey),
                      ),
                      if (!_myChannel)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: ElevatedButton(
                            onPressed: _toggleSubscription,
                            child: Text(_isSubscribed ? 'Отписаться' : 'Подписаться'),
                          ),
                        ),
                      const SizedBox(height: 30),
                      Expanded(
                        child: ListView(
                          children: [
                            Divider(),
                            _buildButton(Icons.video_library_outlined, 'Видео', () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChannelVideosPage(channelId: _channel!.id, isMyChannel: true),
                                ),
                              );
                            }),
                            _buildButton(Icons.playlist_play, 'Плейлисты', () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlaylistsPage(channelId: _channel!.id)
                                  ),
                              );
                            }),
                            _myChannel ? Divider() : Align(),
                            _myChannel ? _buildButton(Icons.person_outline, 'Вернуться к профилю', () {
                              Navigator.pop(context);
                            }) : Align(),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
    );
  }

  Widget _buildButton(IconData icon, String text, VoidCallback onTap) {
    final black = Colors.black;
    final grey = Colors.grey[700]!;

    return ListTile(
      leading: Icon(icon, color: black),
      title: Text(text, style: TextStyle(color: black, fontSize: 16)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: grey),
      onTap: onTap,
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2,'0')}.${date.month.toString().padLeft(2,'0')}.${date.year}';
  }

  Future<void> _updateAvatar() async {
  final user = supabase.auth.currentUser;
  if (user == null || _channel == null) return;

  final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (picked == null) return;

  final file = File(picked.path);
  final fileExt = path.extension(file.path);
  final mimeType = lookupMimeType(file.path);
  final storagePath = 'channel_avatars/${user.id}$fileExt';

  try {
    await supabase.storage.from('avatars').uploadBinary(
      storagePath,
      await file.readAsBytes(),
      fileOptions: FileOptions(upsert: true, contentType: mimeType),
    );

    final imageUrl = supabase.storage.from('avatars').getPublicUrl(storagePath);

    await supabase
        .from('channel')
        .update({'image': imageUrl})
        .eq('id', _channel!.id);

    _loadChannel();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ошибка обновления аватарки: $e')),
      );
    }
  }

  Future<void> _updateChannelName() async {
    String updatedName = _channel!.name;
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Изменить название канала'),
          content: TextField(
            decoration: InputDecoration(hintText: 'Новое название'),
            controller: TextEditingController(text: updatedName),
            onChanged: (value) => updatedName = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await supabase
                      .from('channel')
                      .update({'name': updatedName})
                      .eq('id', _channel!.id);
                  Navigator.pop(context);
                  _loadChannel();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка обновления имени: $e')),
                  );
                }
              },
              child: Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  bool _togglingSubscription = false;

  Future<void> _toggleSubscription() async {
    if(_togglingSubscription) return;
    _togglingSubscription = true;
    final user = supabase.auth.currentUser;
    if (user == null || _channel == null) return;

    try {
      if (_isSubscribed) {
        await supabase
            .from('subscribe')
            .delete()
            .eq('channel_id', _channel!.id)
            .eq('user_id', user.id);
      } else {
        await supabase.from('subscribe').insert({
          'channel_id': _channel!.id,
          'user_id': user.id,
        });
      }

      await _isSubscribedFetch();
      final countResult = await supabase
          .from('subscribe')
          .select('id')
          .eq('channel_id', _channel!.id);
      setState(() {
        _togglingSubscription = false;
        _subscriberCount = countResult.length;
      });

    } catch (e) {
      _togglingSubscription = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при ${_isSubscribed ? 'отписке' : 'подписке'}: $e')),
      );
    }
}

}
