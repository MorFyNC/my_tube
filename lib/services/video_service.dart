// ignore_for_file: non_constant_identifier_names

import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class VideoService {
  final SupabaseClient supabase;

  VideoService({SupabaseClient? client})
      : supabase = client ?? Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchRawVideos() async {
    final response = await supabase
      .from('video')
      .select('''
        id,
        created_at,
        name,
        description,
        video,
        image,
        channel:channel_id(*),
        view:views(count)
      ''');


      return response.cast<Map<String, dynamic>>(); 
  }

  List<VideoWithExtras> mapToVideoWithExtrasList(List<Map<String, dynamic>> data) {
    return data.map((video) {
      final imagePath = video['image'] as String;
      final videoPath = video['video'] as String;

      final imageUrl = supabase.storage
          .from('thumbnails')
          .getPublicUrl(imagePath);
      final videoUrl = supabase.storage
          .from('videos')
          .getPublicUrl(videoPath);

      int viewCount = 0;
      if (video['view'] != null && video['view'] is List && video['view'].isNotEmpty) {
        final firstEntry = video['view'][0];
        if (firstEntry is Map<String, dynamic> && firstEntry['count'] != null) {
          viewCount = firstEntry['count'] as int;
        }
      }

      return VideoWithExtras(
        id: video['id'] as int,
        createdAt: DateTime.parse(video['created_at']),
        name: video['name'] ?? '',
        description: video['description'] ?? '',
        videoUrl: videoUrl,
        imageUrl: imageUrl,
        channel: Channel.fromMap(video['channel']),
        viewCount: viewCount,
      );
    }).toList();
  }
}



class VideoWithExtras {
  final int id;
  final DateTime createdAt;
  final String name;
  final String description;
  final String videoUrl;
  final String imageUrl;
  final Channel channel;
  final int viewCount;
  final File? localImageFile;

  VideoWithExtras({
    required this.id,
    required this.createdAt,
    required this.name,
    required this.description,
    required this.videoUrl,
    required this.imageUrl,
    required this.channel,
    required this.viewCount,
    this.localImageFile,
  });
}

class Channel {
  final int id;
  final String name;
  final String? image;
  final DateTime created_at;
  final String user_id;
  final String? description;

  Channel({
    required this.id,
    required this.name,
    this.image,
    required this.created_at,
    required this.user_id,
    this.description,
  });

  factory Channel.fromMap(Map<String, dynamic> map) {
    return Channel(
      id: map['id'] as int,
      name: map['name'] ?? '',
      image: map['image'],
      created_at: DateTime.parse(map['created_at']),
      user_id: map['user_id'],
      description: map['description'],
    );
  }
}
