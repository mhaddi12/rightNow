import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Rooms Collection
  CollectionReference get _rooms => _db.collection('rooms');

  Future<String> createRoom({
    required String activity,
    required double latitude,
    required double longitude,
    required String creatorId,
  }) async {
    final roomId = const Uuid().v4();
    await _rooms.doc(roomId).set({
      'id': roomId,
      'activity': activity,
      'latitude': latitude,
      'longitude': longitude,
      'creatorId': creatorId,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': DateTime.now().add(const Duration(hours: 1)),
    });
    return roomId;
  }

  Stream<List<Map<String, dynamic>>> getNearbyRooms(String activity) {
    return _rooms.where('activity', isEqualTo: activity).snapshots().map((
      snapshot,
    ) {
      final now = DateTime.now();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .where((room) {
            final expiresAt = room['expiresAt'];
            if (expiresAt is Timestamp) {
              return expiresAt.toDate().isAfter(now);
            }
            return true;
          })
          .toList();
    });
  }

  // Chat Sub-collection
  Stream<List<Map<String, dynamic>>> getMessages(String roomId) {
    return _rooms
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // Include doc ID for marking as seen
            return data;
          }).toList();
        });
  }

  Future<void> sendMessage({
    required String roomId,
    required String text,
    required String userId,
    required String senderName,
  }) async {
    await _rooms.doc(roomId).collection('messages').add({
      'text': text,
      'userId': userId,
      'senderName': senderName,
      'timestamp': FieldValue.serverTimestamp(),
      'seenBy': [], // Initialize empty
    });
  }

  Future<void> markMessageAsSeen({
    required String roomId,
    required String messageId,
    required String userName,
  }) async {
    await _rooms.doc(roomId).collection('messages').doc(messageId).update({
      'seenBy': FieldValue.arrayUnion([userName]),
    });
  }
}
