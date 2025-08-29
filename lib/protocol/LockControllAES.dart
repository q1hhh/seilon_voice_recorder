import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';

class LockControlAES {
  static Uint8List encryptAES(Uint8List data, String encryptKey) {
    final key = Key.fromBase16(encryptKey);

    final encrypter = Encrypter(AES(key, mode: AESMode.ecb, padding: null));

    final encrypted = encrypter.encryptBytes(data.toList());

    return Uint8List.fromList(encrypted.bytes);
  }


  static Uint8List decryptAES(Uint8List data, String decryptKey) {
    final key = Key.fromBase16(decryptKey);
    final encrypter = Encrypter(AES(key, mode: AESMode.ecb, padding: null));

    final decrypted = encrypter.decryptBytes(Encrypted(data));
    return Uint8List.fromList(decrypted);
  }

}