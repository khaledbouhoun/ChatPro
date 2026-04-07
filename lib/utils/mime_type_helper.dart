import 'dart:typed_data';
import 'package:path/path.dart' as p;

/// Helper class for detecting and handling MIME types for uploaded files
class MimeTypeHelper {
  static const Map<String, String> _extensionToMime = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
    'webp': 'image/webp',
    'bmp': 'image/bmp',
    'svg': 'image/svg+xml',
    'ico': 'image/x-icon',
    'mp3': 'audio/mpeg',
    'wav': 'audio/wav',
    'm4a': 'audio/mp4',
    'mp4': 'video/mp4',
    'webm': 'video/webm',
    'mkv': 'video/x-matroska',
    'pdf': 'application/pdf',
    'doc': 'application/msword',
    'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'txt': 'text/plain',
    'json': 'application/json',
    'zip': 'application/zip',
  };

  /// Get MIME type from file extension
  /// Returns 'application/octet-stream' if extension is unknown
  static String getMimeTypeFromExtension(String? filename) {
    if (filename == null || filename.isEmpty) {
      return 'application/octet-stream';
    }

    final ext = p.extension(filename).replaceFirst('.', '').toLowerCase();
    return _extensionToMime[ext] ?? 'application/octet-stream';
  }

  /// Detect MIME type from file magic bytes (header)
  /// This provides accurate detection regardless of file extension
  static String getMimeTypeFromBytes(Uint8List bytes) {
    return _detectFromMagicBytes(bytes);
  }

  /// Magic bytes detection for common image formats
  /// Returns the MIME type based on file signature
  static String _detectFromMagicBytes(Uint8List bytes) {
    if (bytes.isEmpty) return 'application/octet-stream';

    // JPEG: FF D8 FF
    if (bytes.length > 2 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'image/jpeg';
    }

    // PNG: 89 50 4E 47
    if (bytes.length > 3 && bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return 'image/png';
    }

    // GIF: 47 49 46
    if (bytes.length > 2 && bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
      return 'image/gif';
    }

    // WebP: RIFF ... WEBP
    if (bytes.length > 11 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }

    // BMP: 42 4D
    if (bytes.length > 1 && bytes[0] == 0x42 && bytes[1] == 0x4D) {
      return 'image/bmp';
    }

    // MP3: FF FB or FF FA (MPEG Layer 3)
    if (bytes.length > 1 && bytes[0] == 0xFF && (bytes[1] == 0xFB || bytes[1] == 0xFA)) {
      return 'audio/mpeg';
    }

    // MP4: ftyp (bytes 4-7 are "ftyp")
    if (bytes.length > 7 && bytes[4] == 0x66 && bytes[5] == 0x74 && bytes[6] == 0x79 && bytes[7] == 0x70) {
      return 'video/mp4';
    }

    // Fallback to extension-based detection
    return 'application/octet-stream';
  }

  /// Get MIME type with both extension and magic byte verification
  /// This is the most reliable method
  static String getMimeType(Uint8List bytes, {String? filename}) {
    // First try magic bytes (most reliable)
    final magicMime = getMimeTypeFromBytes(bytes);
    if (magicMime != 'application/octet-stream') {
      return magicMime;
    }

    // Fallback to extension
    final extMime = getMimeTypeFromExtension(filename);
    return extMime;
  }

  /// Check if a MIME type is an image
  static bool isImage(String mimeType) {
    return mimeType.startsWith('image/');
  }

  /// Check if a MIME type is audio
  static bool isAudio(String mimeType) {
    return mimeType.startsWith('audio/');
  }

  /// Check if a MIME type is video
  static bool isVideo(String mimeType) {
    return mimeType.startsWith('video/');
  }
}
