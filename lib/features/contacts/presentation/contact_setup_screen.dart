import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../data/contact_repository.dart';
import '../domain/contact_model.dart';
import 'package:shurokkha/core/localization/l10n/app_localizations.dart';

class ContactSetupScreen extends ConsumerWidget {
  const ContactSetupScreen({super.key});

  Future<void> _pickDeviceContact(BuildContext context, WidgetRef ref) async {
    try {
      if (await FlutterContacts.requestPermission()) {
        final contact = await FlutterContacts.openExternalPick();
        if (contact != null) {
          final fullContact = await FlutterContacts.getContact(contact.id);
          if (fullContact != null && fullContact.phones.isNotEmpty) {
            final name = fullContact.displayName;
            final phone = fullContact.phones.first.number.replaceAll(RegExp(r'\s+'), '');
            final email = fullContact.emails.isNotEmpty ? fullContact.emails.first.address : null;

            if (context.mounted) {
              _showContactDialog(
                context,
                ref,
                prefilledName: name,
                prefilledPhone: phone,
                prefilledEmail: email,
              );
            }
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Selected contact does not have a phone number.')),
              );
            }
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contacts permission is required to select from phonebook.')),
          );
        }
      }
    } catch (e) {
      debugPrint("Error picking contact: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking contact: $e')),
        );
      }
    }
  }

  void _showContactDialog(
    BuildContext context,
    WidgetRef ref, {
    EmergencyContact? contact,
    String? prefilledName,
    String? prefilledPhone,
    String? prefilledEmail,
  }) {
    final nameController = TextEditingController(text: contact?.name ?? prefilledName);
    final phoneController = TextEditingController(text: contact?.phoneNumber ?? prefilledPhone);
    final relationController = TextEditingController(text: contact?.relationship);
    final emailController = TextEditingController(text: contact?.email ?? prefilledEmail);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(contact == null ? 'Add Contact' : 'Edit Contact'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: relationController,
                  decoration: const InputDecoration(labelText: 'Relationship'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email (Optional)'),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final repo = ref.read(contactRepositoryProvider);
                if (repo == null) return;

                final newContact = EmergencyContact(
                  id: contact?.id ?? const Uuid().v4(),
                  name: nameController.text.trim(),
                  phoneNumber: phoneController.text.trim(),
                  relationship: relationController.text.trim(),
                  email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                );

                if (contact == null) {
                  await repo.addContact(newContact);
                } else {
                  await repo.updateContact(newContact);
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsStream = ref.watch(contactsStreamProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.trustedContacts),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: contactsStream.when(
        data: (contacts) {
          if (contacts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'No emergency contacts configured yet. Please configure at least 1 contact.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return ListTile(
                title: Text(contact.name),
                subtitle: Text('${contact.relationship} • ${contact.phoneNumber}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showContactDialog(context, ref, contact: contact),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final repo = ref.read(contactRepositoryProvider);
                        if (repo != null) {
                          await repo.deleteContact(contact.id);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (context) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.contact_phone, color: Colors.redAccent),
                      title: Text(l10n.addFromContacts),
                      onTap: () {
                        Navigator.pop(context);
                        _pickDeviceContact(context, ref);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.edit, color: Colors.redAccent),
                      title: Text(l10n.enterManually),
                      onTap: () {
                        Navigator.pop(context);
                        _showContactDialog(context, ref);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        backgroundColor: Colors.redAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
