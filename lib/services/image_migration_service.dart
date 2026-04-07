import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Migration utility to fix Content-Type for existing images
/// Run this once on app startup (optional, zero-breaking)
class ImageMigrationService {
  static final _firestore = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;

  /// Check if migration is needed (checks a sample of files)
  static Future<bool> isMigrationNeeded() async {
    try {
      // Check a few messages to see if they have wrong MIME type
      final sample = await _firestore
          .collection('messages')
          .where('type', isEqualTo: 'image')
          .limit(5)
          .get();

      for (final doc in sample.docs) {
        final url = doc['fileUrl'] as String?;
        if (url == null) continue;

        // Parse storage path from URL
        final path = _extractPathFromUrl(url);
        if (path == null) continue;

        try {
          final ref = _storage.ref(path);
          final metadata = await ref.getMetadata();

          // If we find even one with wrong type, migration is needed
          if (metadata.contentType == 'application/octet-stream') {
            debugPrint('🔄 Migration needed: Found application/octet-stream');
            return true;
          }
        } catch (e) {
          debugPrint('Migration check error: $e');
        }
      }

      debugPrint('✅ No migration needed: All files have correct MIME types');
      return false;
    } catch (e) {
      debugPrint('Migration check failed: $e');
      return false;
    }
  }

  /// Migrates all images with wrong MIME type
  /// Runs in background, reports progress via callback
  static Future<void> migrateAllImages({
    required Function(int completed, int total) onProgress,
    required Function(String message) onError,
  }) async {
    try {
      // Get all messages with images
      final snapshot = await _firestore
          .collection('messages')
          .where('type', isEqualTo: 'image')
          .get();

      debugPrint('🔄 Migration started: ${snapshot.docs.length} messages to check');

      int completed = 0;
      int migrated = 0;

      for (final doc in snapshot.docs) {
        try {
          completed++;
          final url = doc['fileUrl'] as String?;
          if (url == null) {
            onProgress(completed, snapshot.docs.length);
            continue;
          }

          // Parse storage path from URL
          final path = _extractPathFromUrl(url);
          if (path == null) {
            onProgress(completed, snapshot.docs.length);
            continue;
          }

          final ref = _storage.ref(path);
          final metadata = await ref.getMetadata();

          // Only migrate if it has wrong MIME type
          if (metadata.contentType != 'application/octet-stream') {
            onProgress(completed, snapshot.docs.length);
            continue;
          }

          debugPrint('🔄 Migrating: $path');

          // Download file
          final data = await ref.getData();
          if (data == null) {
            onError('Failed to download: $path');
            onProgress(completed, snapshot.docs.length);
            continue;
          }

          // This is where magic byte detection would happen
          // For now, we'll use extension-based detection
          String mimeType = _guessMimeFromExtension(path);

          // Re-upload with correct metadata
          final newMetadata = SettableMetadata(
            contentType: mimeType,
            customMetadata: {
              'migratedAt': DateTime.now().toIso8601String(),
              'wasMimeType': metadata.contentType ?? 'unknown',
            },
          );

          await ref.putData(data, newMetadata);
          migrated++;

          debugPrint('✅ Migrated: $path → $mimeType');
          onProgress(completed, snapshot.docs.length);
        } catch (e) {
          onError('Error processing ${doc.id}: $e');
          onProgress(completed, snapshot.docs.length);
        }
      }

      debugPrint('✅ Migration complete: $migrated/$completed files migrated');
    } catch (e) {
      onError('Migration failed: $e');
    }
  }

  /// Migrates images in a specific conversation
  static Future<void> migrateConversationImages(
    String conversationId, {
    required Function(int completed, int total) onProgress,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('type', isEqualTo: 'image')
          .get();

      debugPrint('🔄 Migrating conversation: ${snapshot.docs.length} images');

      int completed = 0;
      int migrated = 0;

      for (final doc in snapshot.docs) {
        completed++;
        try {
          final url = doc['fileUrl'] as String?;
          if (url == null) {
            onProgress(completed, snapshot.docs.length);
            continue;
          }

          final path = _extractPathFromUrl(url);
          if (path == null) {
            onProgress(completed, snapshot.docs.length);
            continue;
          }

          final ref = _storage.ref(path);
          final metadata = await ref.getMetadata();

          if (metadata.contentType != 'application/octet-stream') {
            onProgress(completed, snapshot.docs.length);
            continue;
          }

          final data = await ref.getData();
          if (data == null) {
            onProgress(completed, snapshot.docs.length);
            continue;
          }

          final mimeType = _guessMimeFromExtension(path);
          final newMetadata = SettableMetadata(
            contentType: mimeType,
            customMetadata: {
              'migratedAt': DateTime.now().toIso8601String(),
            },
          );

          await ref.putData(data, newMetadata);
          migrated++;

          onProgress(completed, snapshot.docs.length);
        } catch (e) {
          debugPrint('Error: $e');
          onProgress(completed, snapshot.docs.length);
        }
      }

      debugPrint('✅ Conversation migration complete: $migrated/$completed');
    } catch (e) {
      debugPrint('Conversation migration failed: $e');
    }
  }

  /// Extract storage path from downloadURL
  /// Example: https://firebasestorage.googleapis.com/v0/b/bucket/o/images%2F123456.jpg?alt=media&token=abc
  /// Returns: images/123456.jpg
  static String? _extractPathFromUrl(String url) {
    try {
      // Find /o/ which indicates start of path
      final oIndex = url.indexOf('/o/');
      if (oIndex == -1) return null;

      // Extract from /o/ to ?
      final start = oIndex + 3;
      final end = url.indexOf('?', start);
      if (end == -1) return null;

      String path = url.substring(start, end);

      // URL decode: %2F → /, %20 → space, etc.
      path = Uri.decodeFull(path);

      return path;
    } catch (e) {
      debugPrint('Path extract error: $e');
      return null;
    }
  }

  /// Guess MIME type from file extension
  /// This is less reliable than magic bytes, use for migration only
  static String _guessMimeFromExtension(String path) {
    final ext = path.split('.').last.toLowerCase();

    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'bmp' => 'image/bmp',
      'mp3' => 'audio/mpeg',
      'wav' => 'audio/wav',
      'm4a' => 'audio/mp4',
      'mp4' => 'video/mp4',
      'webm' => 'video/webm',
      'pdf' => 'application/pdf',
      _ => 'application/octet-stream',
    };
  }
}
