import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:shared_preferences/shared_preferences.dart';

class AesCrypto {
  static final AesCrypto _instance = AesCrypto._internal();
  factory AesCrypto() => _instance;
  AesCrypto._internal();

  static const _keyPref = 'aes_session_key';
  encrypt.Key? _key;

  bool get isReady => _key != null;

  void initFromBase64(String base64Key) {
    _key = encrypt.Key(base64Decode(base64Key));
  }

  // Encrypt the text with a new IV for each encryption
  String encryptText(String plainText) {
    if (_key == null) throw Exception("AES key not initialized.");

    // Generate a new IV for each encryption
    final iv = encrypt.IV.fromLength(16);

    // Encrypt the text
    final encrypter = encrypt.Encrypter(encrypt.AES(_key!, mode: encrypt.AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    // Return a JSON-formatted string with IV and encrypted data
    final message = jsonEncode({
      'iv': base64Encode(iv.bytes),  // Send IV as base64-encoded
      'data': encrypted.base64,      // Send encrypted data as base64
    });

    return message;
  }

  String decryptText(String encryptedText) {
    if (_key == null) throw Exception("AES key not initialized.");

    // Parse the JSON string to extract 'iv' and 'data'
    final Map<String, dynamic> message = jsonDecode(encryptedText);
    final String ivBase64 = message['iv'];
    final String dataBase64 = message['data'];

    // Decode the IV and encrypted data
    final iv = encrypt.IV.fromBase64(ivBase64);

    // Decrypt the data
    final encrypter = encrypt.Encrypter(encrypt.AES(_key!, mode: encrypt.AESMode.cbc));
    final decrypted = encrypter.decrypt64(dataBase64, iv: iv);

    return decrypted;
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
