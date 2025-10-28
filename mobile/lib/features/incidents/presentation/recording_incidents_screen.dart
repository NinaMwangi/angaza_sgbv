import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../../sos/domain/recording_service.dart';
import '../../sos/domain/outbox_service.dart';
import '../data/incidents_repo.dart';

class RecordingsIncidentsScreen extends StatefulWidget {
  const RecordingsIncidentsScreen({super.key});
  @override State<RecordingsIncidentsScreen> createState()=>_SState();
}
class _SState extends State<RecordingsIncidentsScreen>{
  late List<Map<String,dynamic>> _items;
  final _player = AudioPlayer();

  @override void initState(){ super.initState(); _items = IncidentsRepo.all()..sort((a,b)=> (b['ts'] as String).compareTo(a['ts'] as String)); }
  @override void dispose(){ _player.dispose(); super.dispose(); }

  Future<void> _play(String path) async {
    if (await File(path).exists()) { await _player.play(DeviceFileSource(path)); }
    else { if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File missing'))); }
  }

  @override Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: const Text('Recordings & incidents')),
      body: ListView.separated(
        itemCount: _items.length, separatorBuilder: (_, __)=>const Divider(height:1),
        itemBuilder: (_, i){
          final it = _items[i];
          final names = (it['contacts'] as List).map((m)=> (m['name'] ?? m['phone'])).join(', ');
          return ListTile(
            title: Text('${it['ts']}  •  $names'),
            subtitle: Text('Lat:${it['lat'] ?? '-'}, Lng:${it['lng'] ?? '-'}'),
            trailing: (it['audioPath']!=null)
              ? IconButton(icon: const Icon(Icons.play_arrow), onPressed: ()=>_play(it['audioPath']))
              : null,
          );
        },
      ),
    );
  }
}
