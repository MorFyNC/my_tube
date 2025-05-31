import 'package:flutter/material.dart';
import 'package:my_tube/widgets/channel_list.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubscribesPage extends StatefulWidget{
  const SubscribesPage({super.key});

  @override
  State<StatefulWidget> createState() => _SubscribesPageState();
}

class _SubscribesPageState extends State<SubscribesPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>>? subscribes;
  bool _loading = true;

  @override
  void initState() {
    _loadSubscribes();
    super.initState();
  }

  Future<void> _loadSubscribes() async { 
    final subscribes = await supabase
      .from('subscribe')
      .select('channel_id')
      .eq('user_id', supabase.auth.currentUser!.id);

    final channelIds = (subscribes as List)
      .map((item) => item['channel_id'] as int)
      .toList();

    final channelsRaw = await supabase
        .from('channel')
        .select();

    final filteredChannels = (channelsRaw)
        .where((channel) => channelIds.contains(channel['id']))
        .toList();

    if(!mounted) return;

    setState(() {
      this.subscribes = filteredChannels;      
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text('Плейлист', style: TextStyle(
            fontWeight: FontWeight.bold
          ),),
          ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [IconButton(onPressed: () {}, icon: Icon(Icons.abc, color: Colors.transparent))],
      ),
      body: _loading ? Center(child: CircularProgressIndicator()) :
      subscribes!.isEmpty ? 
      Center(
        child: Text(
          'Здесь пока пусто..',
          style: TextStyle
          (
            fontSize: 36,
            fontWeight: FontWeight.bold
          )
        )
      ) :
      Center(
        child: SizedBox(
          width: 750,
          child: ChannelList
          (
            channels: subscribes!
          ),
        )
      )
    );
  }
}