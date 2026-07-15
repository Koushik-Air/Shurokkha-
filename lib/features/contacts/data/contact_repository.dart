import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/contact_model.dart';

class ContactRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId;

  ContactRepository(this._userId);

  CollectionReference<Map<String, dynamic>> get _contactsCollection =>
      _firestore.collection('users').doc(_userId).collection('contacts');

  Stream<List<EmergencyContact>> getContacts() {
    return _contactsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => EmergencyContact.fromMap(doc.data())).toList();
    });
  }

  Future<void> addContact(EmergencyContact contact) async {
    await _contactsCollection.doc(contact.id).set(contact.toMap());
  }

  Future<void> updateContact(EmergencyContact contact) async {
    await _contactsCollection.doc(contact.id).update(contact.toMap());
  }

  Future<void> deleteContact(String contactId) async {
    await _contactsCollection.doc(contactId).delete();
  }
}

final contactRepositoryProvider = Provider<ContactRepository?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  return ContactRepository(user.uid);
});

final contactsStreamProvider = StreamProvider<List<EmergencyContact>>((ref) {
  final repo = ref.watch(contactRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.getContacts();
});
