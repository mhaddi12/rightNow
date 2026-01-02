import 'package:chats/services/encryption_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/foundation.dart';

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
      'expiresAt': DateTime.now()
          .toUtc()
          .add(const Duration(hours: 1))
          .toIso8601String(),
    });
    return roomId;
  }

  Stream<List<Map<String, dynamic>>> getNearbyRooms(String activity) {
    // We combine the Firestore stream with a periodic timer so it refreshes even if database is quiet
    final firestoreStream = _rooms
        .where('activity', isEqualTo: activity)
        .snapshots();
    // Ensure the periodic stream starts immediately
    final periodicStream = Stream.periodic(
      const Duration(seconds: 30),
      (i) => i,
    ).startWith(0);

    return Rx.combineLatest2(
      firestoreStream,
      periodicStream,
      (snapshot, _) => snapshot,
    ).map((snapshot) {
      final now = DateTime.now().toUtc();
      final List<Map<String, dynamic>> rooms = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final expiresAt = data['expiresAt'];
        if (expiresAt is String) {
          try {
            final expiresDate = DateTime.parse(expiresAt).toUtc();
            if (expiresDate.isAfter(now)) {
              rooms.add(data);
            } else {
              // Proactively delete the room from Firestore if it's expired
              _rooms.doc(data['id']).delete().catchError((e) {
                debugPrint('Failed to auto-delete expired room: $e');
              });
            }
          } catch (e) {
            rooms.add(data);
          }
        } else {
          rooms.add(data);
        }
      }
      return rooms;
    });
  }

  // Chat Sub-collection
  Stream<List<Map<String, dynamic>>> getMessages(String roomId) {
    final encryption = EncryptionService(roomId);
    return _rooms
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // Include doc ID for marking as seen

            // Decrypt the message text
            final encryptedText = data['text'] as String?;
            if (encryptedText != null) {
              data['text'] = encryption.decrypt(encryptedText);
            }

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
    final encryption = EncryptionService(roomId);
    final encryptedText = encryption.encrypt(text);

    await _rooms.doc(roomId).collection('messages').add({
      'text': encryptedText,
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

  /// Sweeps all rooms globally and deletes any that have expired.
  Future<void> cleanupExpiredRooms() async {
    try {
      final now = DateTime.now().toUtc();
      final expiredRooms = await _rooms
          .where('expiresAt', isLessThan: now.toIso8601String())
          .get();

      if (expiredRooms.docs.isEmpty) return;

      final batch = _db.batch();
      for (var doc in expiredRooms.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint(
        'Global cleanup: Deleted ${expiredRooms.docs.length} expired rooms.',
      );
    } catch (e) {
      debugPrint('Global cleanup error: $e');
    }
  }
}
