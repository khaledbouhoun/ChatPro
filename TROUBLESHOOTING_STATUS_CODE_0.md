# Troubleshooting HTTP Status Code 0 Error

## What Causes This Error

**HTTP StatusCode: 0** happens when:
1. ❌ Image stored with `application/octet-stream` (browser can't recognize as image)
2. ❌ Firebase Storage returns wrong Content-Type header
3. ❌ Flutter Web can't parse response as image data
4. ❌ Browser security/CORS issue

## Solution

### Quick Fix: Three Options

#### Option 1: Migrate Existing Images (Recommended)
```dart
// Run this in main.dart or app startup
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(...);
  
  // Check and fix old images
  print('🔄 Checking if images need fixing...');
  
  final needsMigration = await ImageMigrationService.isMigrationNeeded();
  if (needsMigration) {
    print('🔄 Found images with wrong MIME type, fixing...');
    await ImageMigrationService.migrateAllImages(
      onProgress: (done, total) {
        print('✅ Fixed: $done/$total images');
      },
      onError: (msg) {
        print('⚠️ Error: $msg');
      },
    );
    print('✅ Migration complete! Old images now display correctly');
  } else {
    print('✅ All images have correct MIME types');
  }
  
  runApp(const MyApp());
}
```

#### Option 2: Re-upload the Problem Image
```dart
// Delete and re-upload the image
// New uploads automatically get correct MIME type from our fix
// Image will display correctly after re-upload
```

#### Option 3: Run Migration Manually
```dart
// In an admin panel or debug menu:
await ImageMigrationService.migrateAllImages(
  onProgress: (done, total) => print('$done/$total'),
  onError: (msg) => print(msg),
);
```

---

## Root Cause Explanation

### The Problem
```
Image uploaded BEFORE fix:
  putData(bytes)  ← No metadata!
  Firebase defaults to: application/octet-stream
  
Browser receives:
  Content-Type: application/octet-stream
  ↓
  "This is binary data, not an image!"
  ↓
  Image.network() can't parse it
  ↓
  HTTP statusCode: 0 (error)
```

### The Solution
```
Image uploaded AFTER fix:
  putData(bytes, SettableMetadata(contentType: 'image/jpeg'))
  Firebase stores: Content-Type: image/jpeg
  
Browser receives:
  Content-Type: image/jpeg
  ↓
  "This is an image!"
  ↓
  Image.network() displays it
  ↓
  HTTP statusCode: 200 (success) ✅
```

---

## Verification Steps

### Step 1: Check if this is the issue
```
1. Go to Firebase Console → Storage
2. Find your image file: images/1775569492350.jpg
3. Click file → Details
4. Look at "Content-Type" metadata field
5. If it shows "application/octet-stream" → This is the issue!
```

### Step 2: Fix All Images at Once
```dart
// In main.dart, add this before runApp():
await ImageMigrationService.migrateAllImages(
  onProgress: (done, total) {
    debugPrint('🔄 Fixed: $done/$total images');
  },
  onError: (msg) {
    debugPrint('Error: $msg');
  },
);
```

### Step 3: Verify Fix Worked
```
1. After migration, go to Firebase Console
2. Check the SAME image file: images/1775569492350.jpg
3. Look at "Content-Type" again
4. Should now show: "image/jpeg" ✅
5. Refresh your app → Image displays correctly ✅
```

---

## Improved Error Handler (Optional)

For better error messages on web, update [attachment_preview.dart](attachment_preview.dart):

```dart
errorBuilder: (context, error, stackTrace) {
  // Log detailed error info
  final url = message.fileUrl ?? 'unknown';
  debugPrint('❌ Image load error:');
  debugPrint('   URL: $url');
  debugPrint('   Error: $error');
  debugPrint('   Stack: $stackTrace');
  
  // Check if it's a network/MIME type issue
  if (error.toString().contains('statusCode: 0')) {
    debugPrint('⚠️  This usually means the image has wrong MIME type');
    debugPrint('   Solution: Run ImageMigrationService.migrateAllImages()');
  }
  
  return Container(
    height: 200,
    width: double.infinity,
    color: AppTheme.surface,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          LucideIcons.imageOff,
          color: AppTheme.textMuted,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          'Image failed to load',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
        ),
      ],
    ),
  );
},
```

---

## Quick Diagnostic Command

Create this file to diagnose the issue:

```dart
// lib/helpers/firebase_diagnostics.dart

import 'package:firebase_storage/firebase_storage.dart';

Future<void> checkImageMetadata(String imageFileName) async {
  try {
    final ref = FirebaseStorage.instance.ref('images/$imageFileName');
    final metadata = await ref.getMetadata();
    
    print('═══════════════════════════════════════');
    print('📊 Image Metadata Diagnostic');
    print('═══════════════════════════════════════');
    print('File: $imageFileName');
    print('Size: ${metadata.size} bytes');
    print('Created: ${metadata.timeCreated}');
    print('Content-Type: ${metadata.contentType}');
    print('═══════════════════════════════════════');
    
    if (metadata.contentType == 'application/octet-stream') {
      print('⚠️  WARNING: Wrong MIME type detected!');
      print('   This causes HTTP statusCode: 0 error');
      print('   Solution: Run migration to fix all images');
    } else if (metadata.contentType?.startsWith('image/') == true) {
      print('✅ Correct MIME type: ${metadata.contentType}');
      print('   Image should display correctly');
    } else {
      print('❌ Unexpected MIME type: ${metadata.contentType}');
    }
  } catch (e) {
    print('❌ Error checking metadata: $e');
  }
}

// Usage:
// checkImageMetadata('1775569492350.jpg');
```

---

## Summary

| Issue | Cause | Fix |
|-------|-------|-----|
| **statusCode: 0** | Wrong MIME type | Run migration |
| **Image won't display** | `application/octet-stream` | `ImageMigrationService.migrateAllImages()` |
| **On Flutter Web** | Server headers wrong | Upload with `SettableMetadata` (already fixed) |
| **Multiple images fail** | All old ones have issue | Migration fixes all at once |

---

## Implementation Order

1. **✅ First**: Deploy new code (MIME detection automatically active)
2. **✅ Second**: Run migration for old images
3. **✅ Third**: Verify in Firebase Console
4. **✅ Fourth**: Refresh app and test

---

## Commands Reference

```dart
// Check if migration needed
await ImageMigrationService.isMigrationNeeded()
// Returns: true if any images have wrong MIME type

// Migrate one conversation
await ImageMigrationService.migrateConversationImages(
  conversationId,
  onProgress: (done, total) => print('$done/$total'),
)

// Migrate all images
await ImageMigrationService.migrateAllImages(
  onProgress: (done, total) => print('$done/$total'),
  onError: (msg) => print('Error: $msg'),
)
```

---

**If after migration images still show statusCode: 0:**
1. Check browser console for additional errors
2. Try hard refresh: `Ctrl+Shift+R`
3. Clear browser cache completely
4. Try different browser
5. Check Firebase Storage bucket permissions
