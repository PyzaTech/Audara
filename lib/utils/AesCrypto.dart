import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AesCrypto {
  static final AesCrypto _instance = AesCrypto._internal();
  factory AesCrypto() => _instance;
  AesCrypto._internal();

  static const _keyPref = 'aes_session_key';
  encrypt.Key? _key;
  encrypt.Key? get key => _key;

  void initFromBase64(String base64Key) {
    _key = encrypt.Key(base64Decode(base64Key));
  }

  String encryptText(String plainText) {
    if (_key == null) throw Exception("AES key not initialized.");
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(_key!, mode: encrypt.AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    return jsonEncode({
      'iv': base64Encode(iv.bytes),
      'data': encrypted.base64,
    });
  }

  String decryptText(String encryptedText) {
    if (_key == null) throw Exception("AES key not initialized.");
    final Map<String, dynamic> message = jsonDecode(encryptedText);
    final iv = encrypt.IV.fromBase64(message['iv']);
    final data = message['data'];
    final encrypter = encrypt.Encrypter(encrypt.AES(_key!, mode: encrypt.AESMode.cbc));
    return encrypter.decrypt64(data, iv: iv);
  }

  Future<void> saveToPrefs() async {
    if (_key == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPref, base64Encode(_key!.bytes));
  }

  Future<bool> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final base64Key = prefs.getString(_keyPref);
    if (base64Key == null) return false;
    initFromBase64(base64Key);
    return true;
  }
}

class DecryptionPayload {
  final String encryptedJson;
  final String base64Key;
  const DecryptionPayload({required this.encryptedJson, required this.base64Key});
}

Map<String, dynamic> decryptAndParseWithAES(DecryptionPayload payload) {
  final key = encrypt.Key(base64Decode(payload.base64Key));
  final Map<String, dynamic> message = jsonDecode(payload.encryptedJson);
  final iv = encrypt.IV.fromBase64(message['iv']);
  final data = message['data'];
  final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
  final decrypted = encrypter.decrypt64(data, iv: iv);
  return jsonDecode(decrypted);
}

Uint8List decodeBase64(String base64Str) {
  return base64Decode(base64Str);
}
