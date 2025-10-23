import 'package:flutter/material.dart';
import '../../contacts/data/contacts_repo.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});
  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  late List<String> _numbers;

  @override
  void initState() {
    super.initState();
    _numbers = ContactsRepo.getAll();
  }

  Future<void> _add() async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add trusted number'),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(hintText: '+2547...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true && c.text.trim().isNotEmpty) {
      await ContactsRepo.add(c.text.trim());
      setState(() => _numbers = ContactsRepo.getAll());
    }
  }

  Future<void> _remove(String n) async {
    await ContactsRepo.remove(n);
    setState(() => _numbers = ContactsRepo.getAll());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trusted contacts')),
      floatingActionButton: FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
      body: ListView.separated(
        itemCount: _numbers.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) => ListTile(
          title: Text(_numbers[i]),
          trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _remove(_numbers[i])),
        ),
      ),
    );
  }
}
