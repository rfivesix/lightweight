// lib/util/encryption_util.dart
import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';

class EncryptionUtil {
  static final _algo = AesGcm.with256bits();
  static const wrapperVersion = 'LWENC-1';

  static Future<Map<String, dynamic>> encryptString(
    String plaintext,
    String passphrase,
  ) async {
    final salt = _randomBytes(16);
    final nonce = _randomBytes(12);
    final key = await _deriveKey(passphrase, salt);
    final box = await _algo.encrypt(
      utf8.encode(plaintext),
      secretKey: key,
      nonce: nonce,
    );
    return {
      'enc': wrapperVersion,
      'salt': base64Encode(salt),
      'nonce': base64Encode(nonce),
      'cipher': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    };
  }

  static Future<String> decryptToString(
    Map<String, dynamic> wrapper,
    String passphrase,
  ) async {
    if (wrapper['enc'] != wrapperVersion) {
      throw ArgumentError('Unknown encryption wrapper');
    }
    final salt = base64Decode(wrapper['salt'] as String);
    final nonce = base64Decode(wrapper['nonce'] as String);
    final cipher = base64Decode(wrapper['cipher'] as String);
    final mac = Mac(base64Decode(wrapper['mac'] as String));
    final key = await _deriveKey(passphrase, salt);
    final clear = await _algo.decrypt(
      SecretBox(cipher, nonce: nonce, mac: mac),
      secretKey: key,
    );
    return utf8.decode(clear);
  }

  static Future<SecretKey> _deriveKey(String passphrase, List<int> salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 150000,
      bits: 256,
    );
    return await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(passphrase)),
      nonce: salt,
    );
  }

  static List<int> _randomBytes(int length) {
    final rnd = Random.secure();
    return List<int>.generate(length, (_) => rnd.nextInt(256));
  }
}
