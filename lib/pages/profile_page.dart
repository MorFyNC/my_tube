// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:my_tube/pages/subscribes_page.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final supabase = Supabase.instance.client;

  String? _nickname;
  DateTime? _createdAt;
  String? _avatarUrl;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = supabase.auth.currentUser;
    try {
      final response = await supabase
          .from('user')
          .select('name, created_at, image')
          .eq('id', user!.id)
          .single();

      
        final data = response;

        if(!mounted) return;

        setState(() {
          _nickname = data['name'] as String?;
          _createdAt = DateTime.tryParse(data['created_at'] as String? ?? '');
          _avatarUrl = data['image'] as String? ??
              'https://i.pravatar.cc/150?img=1';
          _loading = false;
        });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _changeNickname() async {
    final newNickname = await showDialog<String>(
      context: context,
      builder: (context) {
        String tempNick = _nickname ?? '';
        return AlertDialog(
          title: Text('Изменить никнейм'),
          content: TextField(
            autofocus: true,
            decoration: InputDecoration(hintText: 'Введите новый ник'),
            controller: TextEditingController(text: tempNick),
            onChanged: (value) => tempNick = value,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Отмена')),
            TextButton(onPressed: () => Navigator.pop(context, tempNick), child: Text('Сохранить')),
          ],
        );
      },
    );

    if (newNickname != null && newNickname.trim().isNotEmpty) {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      try{

      await supabase
          .from('user')
          .update({'name': newNickname.trim()})
          .eq('id', user.id);

      
        setState(() {
          _nickname = newNickname.trim();
        });
      }
       catch(e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при обновлении никнейма: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _changeAvatar() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 75,
  );

  if (pickedFile == null) {
    return;
  }

  final filePath = pickedFile.path;
  final file = File(filePath);

  final fileExt = path.extension(filePath);
  final mimeType = lookupMimeType(filePath);

  final user = supabase.auth.currentUser;
  if (user == null) return;

  final storagePath = 'avatars/${user.id}$fileExt';

  try {
    await supabase.storage.from('avatars').uploadBinary(
      storagePath,
      await file.readAsBytes(),
      fileOptions: FileOptions(
        upsert: true,
        contentType: mimeType,
      ),
    );

    final publicUrl = supabase.storage.from('avatars').getPublicUrl(storagePath);

    await supabase.from('user').update({
      'image': publicUrl,
    }).eq('id', user.id);

    setState(() {
      _avatarUrl = publicUrl;
    });
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Не удалось загрузить аватар')),
      );
    }
  }


  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2,'0')}.${date.month.toString().padLeft(2,'0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final black = Colors.black;
    final white = Colors.white;
    final grey = Colors.grey[700]!;

    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        title: Center( child: Text('Профиль', style: TextStyle(color: black, fontWeight: FontWeight.bold))),
        backgroundColor: white,
        elevation: 0,
        iconTheme: IconThemeData(color: black),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _avatarUrl != null
                            ? NetworkImage(_avatarUrl!)
                            : null,
                        backgroundColor: grey,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: InkWell(
                          onTap: _changeAvatar,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: black,
                            child: Icon(Icons.edit, size: 18, color: white),
                          ),
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _nickname ?? 'Пользователь',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold, color: black),
                      ),
                      SizedBox(width: 10),
                      InkWell(
                        onTap: _changeNickname,
                        child: Icon(Icons.edit, size: 20, color: grey),
                      )
                    ],
                  ),
                  SizedBox(height: 5),
                  Text(
                    _createdAt != null ? 'Аккаунт создан: ${_formatDate(_createdAt)}' : '',
                    style: TextStyle(color: grey),
                  ),
                  SizedBox(height: 30),
                  Expanded(
                    child: ListView(
                      children: [
                        Divider(),
                        _buildButton(Icons.history, 'История просмотра', () {
                          Navigator.pushNamed(context, '/history');
                        }),
                        _buildButton(Icons.thumb_up_outlined, 'Лайкнутые видео', () {
                          Navigator.pushNamed(context, '/liked');
                        }),
                        _buildButton(Icons.contacts_outlined, 'Подписки', () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => 
                                SubscribesPage()
                              )
                          );
                        }),
                        _buildButton(Icons.video_collection_outlined, 'Перейти к каналу', () {
                          Navigator.pushNamed(context, '/channel');
                        }),
                        Divider(),
                        _buildButton(Icons.logout, 'Выйти', () async {
                          await supabase.auth.signOut();
                          
                          Navigator.pushReplacementNamed(context, '/login');
                        }),
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
      contentPadding: EdgeInsets.symmetric(horizontal: 0),
    );
  }
}
