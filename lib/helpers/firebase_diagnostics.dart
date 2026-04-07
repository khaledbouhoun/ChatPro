/// Firebase Image Diagnostics Helper
/// 
/// Use this to diagnose MIME type issues with uploaded images
/// 
/// Example usage:
/// ```dart
/// // Check a specific image
/// await FirebaseDiagnostics.checkImageMetadata('1775569492350.jpg');
/// 
/// // Check all images in a conversation
/// await FirebaseDiagnostics.checkConversationImages(conversationId);
/// 
/// // Get summary of all images
/// final summary = await FirebaseDiagnostics.getSummary();
/// ```
library;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseDiagnostics {
  static final _storage = FirebaseStorage.instance;
  static final _firestore = FirebaseFirestore.instance;

  /// Check metadata of a specific image by filename
  static Future<void> checkImageMetadata(String filename) async {
    try {
      debugPrint('🔍 Checking: images/$filename');

      final ref = _storage.ref('images/$filename');
      final metadata = await ref.getMetadata();

      debugPrint('═══════════════════════════════════════════');
      debugPrint('📊 Image Metadata');
      debugPrint('═══════════════════════════════════════════');
      debugPrint('File: $filename');
      debugPrint('Size: ${metadata.size} bytes');
      debugPrint('Created: ${metadata.timeCreated}');
      debugPrint('Content-Type: ${metadata.contentType}');
      if (metadata.customMetadata != null) {
        debugPrint('Custom metadata:');
        metadata.customMetadata!.forEach((key, value) {
          debugPrint('  $key: $value');
        });
      }
      debugPrint('═══════════════════════════════════════════');

      _analyzeContentType(metadata.contentType);
    } catch (e) {
      debugPrint('❌ Error checking metadata: $e');
    }
  }

  /// Check all images in a conversation
  static Future<void> checkConversationImages(String conversationId) async {
    try {
      debugPrint('🔍 Checking conversation: $conversationId');

      final snapshot = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('type', isEqualTo: 'image')
          .get();

      debugPrint('Found ${snapshot.docs.length} images in conversation');

      int correct = 0;
      int incorrect = 0;

      for (final doc in snapshot.docs) {
        final url = doc['fileUrl'] as String?;
        if (url == null) continue;

        final filename = _extractFilenameFromUrl(url);
        if (filename == null) continue;

        try {
          final ref = _storage.ref('images/$filename');
          final metadata = await ref.getMetadata();

          if (metadata.contentType == 'application/octet-stream') {
            incorrect++;
            debugPrint('❌ $filename: ${metadata.contentType}');
          } else {
            correct++;
            debugPrint('✅ $filename: ${metadata.contentType}');
          }
        } catch (e) {
          debugPrint('⚠️  $filename: Error - $e');
        }
      }

      debugPrint('═══════════════════════════════════════════');
      debugPrint('Summary: $correct correct, $incorrect incorrect');
      debugPrint('═══════════════════════════════════════════');

      if (incorrect > 0) {
        debugPrint('⚠️  Run: ImageMigrationService.migrateConversationImages()');
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
    }
  }

  /// Get summary of all images in app
  static Future<DiagnosticsSummary?> getSummary() async {
    try {
      debugPrint('📊 Generating diagnostics summary...');

      final snapshot = await _firestore.collection('messages').where('type', isEqualTo: 'image').get();

      int correct = 0;
      int incorrect = 0;
      int checkedButFailed = 0;

      for (final doc in snapshot.docs) {
        final url = doc['fileUrl'] as String?;
        if (url == null) continue;

        final filename = _extractFilenameFromUrl(url);
        if (filename == null) continue;

        try {
          final ref = _storage.ref('images/$filename');
          final metadata = await ref.getMetadata();

          if (metadata.contentType == 'application/octet-stream') {
            incorrect++;
          } else if (metadata.contentType?.startsWith('image/') == true) {
            correct++;
          }
        } catch (e) {
          checkedButFailed++;
        }
      }

      final summary = DiagnosticsSummary(
        totalImages: snapshot.docs.length,
        correctMimeType: correct,
        incorrectMimeType: incorrect,
        checkFailed: checkedButFailed,
      );

      debugPrint('═══════════════════════════════════════════');
      debugPrint('📊 Diagnostics Summary');
      debugPrint('═══════════════════════════════════════════');
      debugPrint('Total images: ${summary.totalImages}');
      debugPrint('✅ Correct MIME type: ${summary.correctMimeType}');
      debugPrint('❌ Wrong MIME type: ${summary.incorrectMimeType}');
      debugPrint('⚠️  Check failed: ${summary.checkFailed}');
      debugPrint('═══════════════════════════════════════════');

      if (summary.incorrectMimeType > 0) {
        final percent = (summary.incorrectMimeType / summary.totalImages * 100).toStringAsFixed(1);
        debugPrint('⚠️  $percent% of images have wrong MIME type');
        debugPrint('   Run migration: ImageMigrationService.migrateAllImages()');
      } else if (summary.correctMimeType == summary.totalImages) {
        debugPrint('✅ All images have correct MIME types!');
      }

      return summary;
    } catch (e) {
      debugPrint('❌ Error generating summary: $e');
      return null;
    }
  }

  /// Analyze and recommend action for a content type
  static void _analyzeContentType(String? contentType) {
    if (contentType == null) {
      debugPrint('⚠️  No Content-Type metadata found');
      return;
    }

    if (contentType == 'application/octet-stream') {
      debugPrint('❌ PROBLEM DETECTED: application/octet-stream');
      debugPrint('   This causes: HTTP statusCode: 0 error on Flutter Web');
      debugPrint('   Images will not display');
      debugPrint('   ');
      debugPrint('   Solution: Run ImageMigrationService.migrateAllImages()');
      debugPrint('   This will fix ALL images with this issue');
    } else if (contentType.startsWith('image/')) {
      debugPrint('✅ CORRECT MIME type: $contentType');
      debugPrint('   Image should display correctly');
    } else {
      debugPrint('⚠️  Unexpected MIME type: $contentType');
      debugPrint('   Image may not display as expected');
    }
  }

  /// Extract filename from Firebase Storage download URL
  static String? _extractFilenameFromUrl(String url) {
    try {
      /**
       * URL format:
       * https://firebasestorage.googleapis.com/v0/b/bucket/o/folder%2Ffilename?alt=media&token=...
       */
      final oIndex = url.indexOf('/o/');
      if (oIndex == -1) return null;

      final end = url.indexOf('?', oIndex);
      if (end == -1) return null;

      String path = url.substring(oIndex + 3, end);
      // URL decode: %2F → /, %20 → space
      path = Uri.decodeFull(path);

      // Extract just the filename (after last /)
      return path.split('/').last;
    } catch (e) {
      return null;
    }
  }
}

/// Result of diagnostics check
class DiagnosticsSummary {
  final int totalImages;
  final int correctMimeType;
  final int incorrectMimeType;
  final int checkFailed;

  DiagnosticsSummary({
    required this.totalImages,
    required this.correctMimeType,
    required this.incorrectMimeType,
    required this.checkFailed,
  });

  bool get needsMigration => incorrectMimeType > 0;

  double get percentageCorrect => (correctMimeType / totalImages * 100);

  @override
  String toString() {
    return '''
DiagnosticsSummary:
  Total: $totalImages
  Correct: $correctMimeType (${percentageCorrect.toStringAsFixed(1)}%)
  Incorrect: $incorrectMimeType
  Failed: $checkFailed
  Needs migration: $needsMigration
''';
  }
}

/// Example usage in main.dart:
///
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await Firebase.initializeApp(...);
///   
///   // Check images on startup
///   if (kDebugMode) {
///     debugPrint('🔍 Running diagnostics...');
///     final summary = await FirebaseDiagnostics.getSummary();
///     
///     if (summary?.needsMigration == true) {
///       debugPrint('🔄 Running migration...');
///       await ImageMigrationService.migrateAllImages(
///         onProgress: (done, total) {
///           debugPrint('Progress: $done/$total');
///         },
///         onError: (msg) => debugPrint('Error: $msg'),
///       );
///     }
///   }
///   
///   runApp(const MyApp());
/// }
/// ```
