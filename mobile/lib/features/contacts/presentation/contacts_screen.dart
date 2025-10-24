import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../contacts/data/contacts_repo.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});
  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  late List<Map<String, String>> _items;

  @override
  void initState() {
    super.initState();
    _items = ContactsRepo.getAll();
  }

  Future<void> _addManual() async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add trusted contact'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone (+254...)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true && (phone.text.trim().isNotEmpty)) {
      await ContactsRepo.add(
        name: name.text.trim().isEmpty ? phone.text.trim() : name.text.trim(),
        phone: phone.text.trim(),
      );
      setState(() => _items = ContactsRepo.getAll());
    }
  }

  Future<void> _importFromPhone() async {
    final granted = await FlutterContacts.requestPermission(readonly: true);
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contacts permission denied')));
      return;
    }
    final list = await FlutterContacts.getContacts(withProperties: true);
    if (!mounted) return;

    final picked = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Pick a contact'),
        children: [
          SizedBox(
            width: 320,
            height: 420,
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) {
                final c = list[i];
                final name = c.displayName;
                final phone = (c.phones.isNotEmpty) ? c.phones.first.number : '';
                return ListTile(
                  title: Text(name),
                  subtitle: Text(phone),
                  onTap: () => Navigator.pop(context, {'name': name, 'phone': phone.replaceAll(' ', '')}),
                );
              },
            ),
          ),
        ],
      ),
    );

    if (picked != null && (picked['phone'] ?? '').isNotEmpty) {
      await ContactsRepo.add(name: picked['name']!, phone: picked['phone']!);
      setState(() => _items = ContactsRepo.getAll());
    }
  }

  Future<void> _remove(String phone) async {
    await ContactsRepo.remove(phone);
    setState(() => _items = ContactsRepo.getAll());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trusted contacts')),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            onPressed: _importFromPhone,
            icon: const Icon(Icons.download),
            label: const Text('Import'),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(onPressed: _addManual, child: const Icon(Icons.add)),
        ],
      ),
      body: ListView.separated(
        itemCount: _items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final m = _items[i];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(m['name'] ?? ''),
            subtitle: Text(m['phone'] ?? ''),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _remove(m['phone']!),
            ),
          );
        },
      ),
    );
  }
}
