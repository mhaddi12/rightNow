import 'package:encrypt/encrypt.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

// Hide Flutter's Key to avoid conflict with encrypt's Key
import 'package:flutter/foundation.dart' hide Key;

class EncryptionService {
  late final Key _key;
  late final IV _iv;

  EncryptionService(String roomId) {
    // Generate a 32-byte key from the roomId hash
    final digest = sha256.convert(utf8.encode(roomId));
    _key = Key(Uint8List.fromList(digest.bytes));

    // Fixed 16-byte IV
    _iv = IV(Uint8List(16));
  }

  String encrypt(String text) {
    try {
      final encrypter = Encrypter(AES(_key, mode: AESMode.sic));
      final encrypted = encrypter.encrypt(text, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      debugPrint("Encryption error: $e");
      return text;
    }
  }

  String decrypt(String encryptedBase64) {
    if (encryptedBase64.isEmpty) return "";
    try {
      final encrypter = Encrypter(AES(_key, mode: AESMode.sic));
      return encrypter.decrypt64(encryptedBase64, iv: _iv);
    } catch (e) {
      // If decryption fails, it's likely an old unencrypted message
      // Return the original text as a fallback
      return encryptedBase64;
    }
  }
}
