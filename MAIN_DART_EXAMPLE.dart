/// Example main.dart with automatic image migration
///
/// This shows how to:
/// 1. Check if migration is needed
/// 2. Run diagnostics
/// 3. Migrate old images automatically
/// 4. Handle errors gracefully
library;

import 'package:chat_pro/main.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:chat_pro/firebase_options.dart';
import 'package:chat_pro/services/image_migration_service.dart';
import 'package:chat_pro/helpers/firebase_diagnostics.dart';
import 'package:flutter/material.dart';

/// Production main() - with optional auto-migration
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Fix the 3 images with wrong MIME type
  debugPrint('🔄 Checking images for wrong MIME types...');
  final needsMigration = await ImageMigrationService.isMigrationNeeded();

  if (needsMigration) {
    debugPrint('🔄 Found images with application/octet-stream, fixing...');
    await ImageMigrationService.migrateAllImages(
      onProgress: (completed, total) {
        debugPrint('✅ Fixed: $completed/$total images');
      },
      onError: (msg) {
        debugPrint('⚠️  Error: $msg');
      },
    );
    debugPrint('✅ Migration complete!');
  } else {
    debugPrint('✅ All images already have correct MIME types');
  }

  runApp(const MyApp());
}

/// Check for images with wrong MIME types and fix them
/// This runs silently in the background and doesn't block app startup
Future<void> _initializeImageMigration() async {
  try {
    debugPrint('🔍 Checking images...');

    // Get diagnostics summary
    final summary = await FirebaseDiagnostics.getSummary();

    if (summary == null) {
      debugPrint('⚠️  Could not run diagnostics');
      return;
    }

    // If migration needed, run it
    if (summary.needsMigration) {
      debugPrint('🔄 Found ${summary.incorrectMimeType} images with wrong MIME type');
      debugPrint('🔄 Starting migration...');

      await ImageMigrationService.migrateAllImages(
        onProgress: (completed, total) {
          final percent = (completed / total * 100).toStringAsFixed(1);
          debugPrint('  Migration progress: $completed/$total ($percent%)');
        },
        onError: (message) {
          debugPrint('⚠️  Migration warning: $message');
        },
      );

      debugPrint('✅ Migration complete!');
      debugPrint('  All images now have correct MIME types');
    } else {
      debugPrint('✅ All images have correct MIME types - no migration needed');
    }
  } catch (e) {
    debugPrint('❌ Migration initialization error: $e');
    // Don't crash the app, just log the error
  }
}

/// Alternative: Manual migration trigger
///
/// Add this to your app's settings/admin panel if you want
/// users to manually trigger migration
Future<void> manuallyTriggerMigration(Function(String) showMessage) async {
  try {
    showMessage('🔄 Starting migration...');

    int totalFixed = 0;

    await ImageMigrationService.migrateAllImages(
      onProgress: (completed, total) {
        showMessage('Migration: $completed/$total images fixed');
        totalFixed = completed;
      },
      onError: (msg) {
        showMessage('⚠️  Warning: $msg');
      },
    );

    showMessage('✅ Migration complete! Fixed $totalFixed images.');
  } catch (e) {
    showMessage('❌ Migration failed: $e');
  }
}

/// Alternative: Migration for single conversation
///
/// Add this to perform migration only for a specific conversation
Future<void> migrateConversationImages(
  String conversationId,
  Function(String) showMessage,
) async {
  try {
    showMessage('🔄 Migrating conversation images...');

    int totalFixed = 0;

    await ImageMigrationService.migrateConversationImages(
      conversationId,
      onProgress: (completed, total) {
        showMessage('Fixed: $completed/$total');
        totalFixed = completed;
      },
    );

    showMessage('✅ Conversation migration complete! Fixed $totalFixed images.');
  } catch (e) {
    showMessage('❌ Error: $e');
  }
}

/// Debug helper: Check specific image
///
/// Add this to debug a specific image URL
Future<void> debugCheckImage(String imageUrl) async {
  try {
    // Extract filename from URL
    const pattern = 'o/'; // Firebase URL pattern
    final oIndex = imageUrl.indexOf(pattern);
    if (oIndex == -1) {
      debugPrint('Could not parse image URL');
      return;
    }

    final start = oIndex + pattern.length;
    final end = imageUrl.indexOf('?', start);
    if (end == -1) {
      debugPrint('Could not parse image URL (no query params)');
      return;
    }

    String path = imageUrl.substring(start, end);
    path = Uri.decodeFull(path);
    final filename = path.split('/').last;

    debugPrint('Checking image: $filename');
    await FirebaseDiagnostics.checkImageMetadata(filename);
  } catch (e) {
    debugPrint('Error: $e');
  }
}

// ════════════════════════════════════════════════════════════════
// CONFIGURATION OPTIONS
// ════════════════════════════════════════════════════════════════

/// Feature flags for image migration behavior
class ImageMigrationConfig {
  /// Run migration automatically on app startup?
  static const bool autoMigrateOnStartup = true;

  /// Show diagnostics in debug mode?
  static const bool showDiagnosticsInDebug = true;

  /// Log migration progress?
  static const bool logMigrationProgress = true;

  /// Maximum migration time (ms) before timeout
  static const int migrationTimeout = 300000; // 5 minutes
}

// ════════════════════════════════════════════════════════════════
// USAGE IN YOUR APP
// ════════════════════════════════════════════════════════════════

/*

1. AUTOMATIC ON STARTUP (Recommended)
   ===================================
   Just ensure _initializeImageMigration() is called in main()
   - Runs silently in background
   - Doesn't block app startup
   - Reports progress to debug console
   - Handles errors gracefully

2. MANUAL TRIGGER IN SETTINGS
   ==========================
   Add to your settings screen:
   
   ElevatedButton(
     onPressed: () => manuallyTriggerMigration(
       (msg) => showBottomSheet(context, msg),
     ),
     child: const Text('Fix Images'),
   )

3. DEBUG SPECIFIC IMAGE
   ====================
   Use this in developer console or debug menu:
   
   debugCheckImage(imageUrl)
   
   Or check conversation:
   await FirebaseDiagnostics.checkConversationImages(conversationId)

4. MONITORING
   ===========
   Add to your analytics:
   
   final summary = await FirebaseDiagnostics.getSummary();
   if (summary != null) {
     analytics.logEvent(
       name: 'image_diagnostics',
       parameters: {
         'total_images': summary.totalImages,
         'correct_mime': summary.correctMimeType,
         'incorrect_mime': summary.incorrectMimeType,
         'needs_migration': summary.needsMigration,
       },
     );
   }

*/

// Import these at the top of main.dart:
// import 'package:flutter/material.dart';
// import 'package:chat_pro/firebase_options.dart';
// import 'package:chat_pro/services/image_migration_service.dart';
// import 'package:chat_pro/helpers/firebase_diagnostics.dart';
