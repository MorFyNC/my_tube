import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommentsSection extends StatefulWidget {
  final int videoId;

  const CommentsSection({super.key, required this.videoId});

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final supabase = Supabase.instance.client;
  final TextEditingController commentController = TextEditingController();
  List<Map<String, dynamic>> comments = [];
  Map<int, List<Map<String, dynamic>>> answers = {};
  Map<String, int> likes = {};
  Map<String, int> dislikes = {};
  Map<String, bool?> userLikes = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
  final userId = supabase.auth.currentUser!.id;

  final commentData = await supabase
      .from('comment')
      .select('''
        *,
        user: user_id(name, image),
        liked_disliked(*)
      ''')
      .eq('video_id', widget.videoId)
      .order('created_at');

  final commentIds = commentData.map((c) => c['id'] as int).toList();

  final answerData = await supabase
      .from('anwser')
      .select('''
        *,
        user: user_id(name, image),
        liked_disliked(*)
      ''')
      .inFilter('comment_id', commentIds);

  final groupedAnswers = <int, List<Map<String, dynamic>>>{};
  for (final a in answerData) {
    final commentId = a['comment_id'] as int;
    groupedAnswers.putIfAbsent(commentId, () => []).add(a);
  }

  for (final c in commentData) {
    final key = c['id'].toString();
    final List<dynamic> likedList = c['liked_disliked'] ?? [];

    likes[key] = likedList.where((l) => l['is_liked'] == true).length;
    dislikes[key] = likedList.where((l) => l['is_liked'] == false).length;

    final userLike = likedList.firstWhere(
      (l) => l['user_id'] == userId,
      orElse: () => null,
    );
    userLikes[key] = userLike?['is_liked'];
  }

  for (final a in answerData) {
    final key = 'a_${a['id']}';
    final List<dynamic> likedList = a['liked_disliked'] ?? [];

    likes[key] = likedList.where((l) => l['is_liked'] == true).length;
    dislikes[key] = likedList.where((l) => l['is_liked'] == false).length;

    final userLike = likedList.firstWhere(
      (l) => l['user_id'] == userId,
      orElse: () => null,
    );
    userLikes[key] = userLike?['is_liked'];
  }

  setState(() {
    comments = List<Map<String, dynamic>>.from(commentData);
    answers = groupedAnswers;
  });
}


  Future<void> _sendComment() async {
    final text = commentController.text.trim();
    if (text.isEmpty) return;

    await supabase.from('comment').insert({
      'video_id': widget.videoId,
      'user_id': supabase.auth.currentUser!.id,
      'content': text,
    });

    commentController.clear();
    _loadData();
  }

  Future<void> _sendAnswer(int commentId, String text) async {
    if (text.trim().isEmpty) return;

    await supabase.from('anwser').insert({
      'comment_id': commentId,
      'user_id': supabase.auth.currentUser!.id,
      'content': text.trim(),
    });

    _loadData();
  }

  Future<void> _toggleLike(String key, bool like, {bool isAnswer = false}) async {
    final userId = supabase.auth.currentUser!.id;
    final filterKey = isAnswer ? 'anwser_id' : 'comment_id';
    final id = int.parse(key.replaceFirst('a_', ''));

    final existing = await supabase
        .from('liked_disliked')
        .select()
        .eq(filterKey, id)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing == null) {
      await supabase.from('liked_disliked').insert({
        'user_id': userId,
        filterKey: id,
        'is_liked': like,
      });
    } else if (existing['is_liked'] == like) {
      await supabase.from('liked_disliked').delete().eq('id', existing['id']);
    } else {
      await supabase.from('liked_disliked').update({'is_liked': like}).eq('id', existing['id']);
    }

    _loadData();
  }

  Widget _buildActions(String key, bool isAnswer) {
    return Row(
      children: [
        IconButton(
          icon: Icon(userLikes[key] == true ? Icons.thumb_up : Icons.thumb_up_outlined),
          onPressed: () => _toggleLike(key, true, isAnswer: isAnswer),
        ),
        Text((likes[key] ?? 0).toString()),
        IconButton(
          icon: Icon(userLikes[key] == false ? Icons.thumb_down : Icons.thumb_down_outlined),
          onPressed: () => _toggleLike(key, false, isAnswer: isAnswer),
        ),
        Text((dislikes[key] ?? 0).toString()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      hintText: 'Добавить комментарий...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendComment,
                )
              ],
            ),
          ),
          const Divider(),
          ListView.builder(
            itemCount: comments.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final c = comments[index];
              final commentId = c['id'];
              final key = commentId.toString();
              final replyController = TextEditingController();

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundImage: c['user']['image'] != null
                              ? NetworkImage(c['user']['image'])
                              : null,
                          child: c['user']['image'] == null ? const Icon(Icons.person) : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c['user']['name'] ?? 'Пользователь',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(c['content']),
                              _buildActions(key, false),
                              TextButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Ответить'),
                                      content: TextField(
                                        controller: replyController,
                                        decoration: const InputDecoration(hintText: 'Введите ответ'),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Отмена'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _sendAnswer(commentId, replyController.text);
                                          },
                                          child: const Text('Отправить'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: const Text('Ответить'),
                              ),
                              if (answers[commentId] != null)
                                ...answers[commentId]!.map((a) {
                                  final aid = a['id'];
                                  final akey = 'a_$aid';
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 14,
                                              backgroundImage: a['user']['image'] != null
                                                  ? NetworkImage(a['user']['image'])
                                                  : null,
                                              child: a['user']['image'] == null ? const Icon(Icons.person, size: 16) : null,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              a['user']['name'] ?? 'Пользователь',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        Text(a['content']),
                                        _buildActions(akey, true),
                                      ],
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
