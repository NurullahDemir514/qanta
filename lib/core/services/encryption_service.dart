import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';

/// Encryption Service for secure file handling
/// Provides end-to-end encryption for user data
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  static EncryptionService get instance => _instance;

  encrypt.Encrypter? _encrypter;
  encrypt.Key? _key;
  encrypt.IV? _iv;
  String? _currentUserId;

  /// Initialize encryption with user-specific key
  Future<void> initialize(String userId) async {
    try {
      // Skip if already initialized for the same user
      if (_currentUserId == userId && _encrypter != null) {
        debugPrint(
          '🔐 EncryptionService already initialized for user: $userId',
        );
        return;
      }

      // Generate user-specific key from user ID
      final keyBytes = _generateUserKey(userId);
      _key = encrypt.Key(keyBytes);
      
      // Use deterministic IV based on user ID for consistency
      _iv = _generateUserIV(userId);
      
      _encrypter = encrypt.Encrypter(
        encrypt.AES(_key!, mode: encrypt.AESMode.cbc),
      );
      _currentUserId = userId;

      debugPrint('🔐 EncryptionService initialized for user: $userId');
    } catch (e) {
      debugPrint('❌ EncryptionService initialization failed: $e');
      rethrow;
    }
  }

  /// Generate user-specific encryption key
  Uint8List _generateUserKey(String userId) {
    // Use user ID + app secret to generate consistent key
    const appSecret =
        'QantaAppSecret2024'; // In production, use environment variable
    final combined = '$userId$appSecret';
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    return Uint8List.fromList(digest.bytes);
  }

  /// Generate user-specific IV for consistent encryption/decryption
  encrypt.IV _generateUserIV(String userId) {
    // Use user ID + different secret for IV to ensure consistency
    const ivSecret = 'QantaIVSecret2024';
    final combined = '$userId$ivSecret';
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    
    // Take first 16 bytes for IV
    final ivBytes = digest.bytes.take(16).toList();
    return encrypt.IV(Uint8List.fromList(ivBytes));
  }

  /// Encrypt file data
  Future<Uint8List> encryptFile(File file) async {
    try {
      if (_encrypter == null || _iv == null) {
        throw Exception('EncryptionService not initialized');
      }

      final fileBytes = await file.readAsBytes();
      final encrypted = _encrypter!.encryptBytes(fileBytes, iv: _iv!);
      return Uint8List.fromList(encrypted.bytes);
    } catch (e) {
      debugPrint('❌ File encryption failed: $e');
      rethrow;
    }
  }

  /// Decrypt file data
  Future<Uint8List> decryptFile(Uint8List encryptedBytes) async {
    try {
      if (_encrypter == null || _iv == null) {
        throw Exception('EncryptionService not initialized');
      }

      final encrypted = encrypt.Encrypted(encryptedBytes);
      final decrypted = _encrypter!.decryptBytes(encrypted, iv: _iv!);
      return Uint8List.fromList(decrypted);
    } catch (e) {
      debugPrint('❌ File decryption failed: $e');
      rethrow;
    }
  }

  /// Encrypt string data
  String encryptString(String data) {
    try {
      if (_encrypter == null || _iv == null) {
        throw Exception('EncryptionService not initialized');
      }

      final encrypted = _encrypter!.encrypt(data, iv: _iv!);
      return encrypted.base64;
    } catch (e) {
      debugPrint('❌ String encryption failed: $e');
      rethrow;
    }
  }

  /// Decrypt string data
  String decryptString(String encryptedData) {
    try {
      if (_encrypter == null || _iv == null) {
        throw Exception('EncryptionService not initialized');
      }

      final encrypted = encrypt.Encrypted.fromBase64(encryptedData);
      final decrypted = _encrypter!.decrypt(encrypted, iv: _iv!);
      return decrypted;
    } catch (e) {
      debugPrint('❌ String decryption failed: $e');
      rethrow;
    }
  }

  /// Create encrypted temporary file
  Future<File> createEncryptedTempFile(File originalFile) async {
    try {
      final encryptedBytes = await encryptFile(originalFile);
      final tempFile = File('${originalFile.path}.encrypted');
      await tempFile.writeAsBytes(encryptedBytes);
      return tempFile;
    } catch (e) {
      debugPrint('❌ Encrypted temp file creation failed: $e');
      rethrow;
    }
  }

  /// Decrypt file to original location
  Future<File> decryptToFile(
    Uint8List encryptedBytes,
    String outputPath,
  ) async {
    try {
      final decryptedBytes = await decryptFile(encryptedBytes);
      final file = File(outputPath);
      await file.writeAsBytes(decryptedBytes);
      return file;
    } catch (e) {
      debugPrint('❌ File decryption to file failed: $e');
      rethrow;
    }
  }
}
