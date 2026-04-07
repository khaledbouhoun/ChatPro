/// Example: How to use ImageMigrationService in your app
///
/// Add this to main.dart or a startup service
///
library;

import 'package:chat_pro/services/image_migration_service.dart';

Future<void> initializeImageMigration() async {
  try {
    // Check if migration is needed (fast - samples 5 files)
    final needsMigration = await ImageMigrationService.isMigrationNeeded();

    if (!needsMigration) {
      print('✅ Images are correctly formatted');
      return;
    }

    print('🔄 Starting image migration...');

    // Option 1: Migrate all images with progress tracking
    await ImageMigrationService.migrateAllImages(
      onProgress: (completed, total) {
        final percent = (completed / total * 100).toStringAsFixed(1);
        print('Progress: $completed/$total ($percent%)');
        // You could also update UI with this progress
      },
      onError: (message) {
        print('⚠️ Error: $message');
      },
    );

    print('✅ Migration complete!');
  } catch (e) {
    print('❌ Migration failed: $e');
  }
}

/// Example 2: Migrate only a specific conversation
Future<void> migrateConversation(String conversationId) async {
  try {
    print('🔄 Migrating conversation: $conversationId');

    await ImageMigrationService.migrateConversationImages(
      conversationId,
      onProgress: (completed, total) {
        final percent = (completed / total * 100).toStringAsFixed(1);
        print('Conversation progress: $completed/$total ($percent%)');
      },
    );

    print('✅ Conversation migration complete!');
  } catch (e) {
    print('❌ Error: $e');
  }
}

/// Example 3: Alternative - Use in main.dart
///
/// import 'package:chat_pro/services/image_migration_service.dart';
///
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
///
///   // Optional: Run migration in background
///   (() async {
///     await initializeImageMigration();
///   }).call();
///
///   runApp(const MyApp());
/// }
///

/// Example 4: Auto-migration on first launch
///
/// class AppStartupService {
///   static Future<void> initialize() async {
///     // Run migration only on first launch
///     final prefs = await SharedPreferences.getInstance();
///     final migrationDone = prefs.getBool('image_migration_v1_done') ?? false;
///
///     if (!migrationDone) {
///       print('🔄 Running image migration on first launch...');
///
///       final needsMigration = await ImageMigrationService.isMigrationNeeded();
///       if (needsMigration) {
///         await ImageMigrationService.migrateAllImages(
///           onProgress: (_, __) {},
///           onError: (msg) => print('Migration error: $msg'),
///         );
///       }
///
///       // Mark as done so it doesn't run again
///       await prefs.setBool('image_migration_v1_done', true);
///       print('✅ Migration complete, will not run again');
///     }
///   }
/// }
///

/// What the migration does:
///
/// 1. Checks all messages with type='image'
/// 2. For each image URL:
///    - Downloads the file from storage
///    - Detects MIME type from extension
///    - Re-uploads with correct SettableMetadata
///    - Image.network() now displays inline instead of downloading
///
/// Before migration:
///   ❌ Content-Type: application/octet-stream
///   ❌ Image.network(url) downloads file instead of displaying
///   ❌ Browser shows download dialog
///
/// After migration:
///   ✅ Content-Type: image/jpeg or image/png
///   ✅ Image.network(url) displays inline
///   ✅ Browser renders image directly
///
