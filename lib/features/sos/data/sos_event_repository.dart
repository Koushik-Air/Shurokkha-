import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/sos_event_model.dart';
import '../../auth/data/auth_repository.dart';

class SosEventRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<SosEvent>> getSosEventsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('sos_events')
        .orderBy('startedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => SosEvent.fromMap(doc.data())).toList();
    });
  }

  Future<void> updateEventStatus(String userId, String eventId, String status) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('sos_events')
        .doc(eventId)
        .update({'status': status});
  }
}

final sosEventRepositoryProvider = Provider<SosEventRepository>((ref) {
  return SosEventRepository();
});

final sosEventsStreamProvider = StreamProvider<List<SosEvent>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();
  return ref.watch(sosEventRepositoryProvider).getSosEventsStream(user.uid);
});
