import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

/// Centralised runtime permission management.
///
/// Usage:
///   final granted = await PermissionService.requestCamera();
///   if (!granted) return;
class PermissionService {
  PermissionService._();

  // ─── Camera ───────────────────────────────────────────────────────────────

  static Future<bool> requestCamera() async {
    return _request(Permission.camera, 'Camera', 'Camera access is needed to take photos for your messages.');
  }

  // ─── Photo Library ────────────────────────────────────────────────────────

  static Future<bool> requestPhotos() async {
    // On web the permission_handler web implementation doesn't support photos
    // — treat as granted (file pickers work without runtime permission).
    if (kIsWeb) return true;
    // On Android 13+ READ_MEDIA_IMAGES; on older READ_EXTERNAL_STORAGE
    return _request(Permission.photos, 'Photo Library', 'Photo library access is needed to send images.');
  }

  // ─── Microphone ───────────────────────────────────────────────────────────

  static Future<bool> requestMicrophone() async {
    return _request(Permission.microphone, 'Microphone', 'Microphone access is needed to record voice messages.');
  }

  // ─── Storage (Android ≤12 fallback) ──────────────────────────────────────

  static Future<bool> requestStorage() async {
    if (kIsWeb) return true;
    return _request(Permission.storage, 'Storage', 'Storage access is needed to send files and documents.');
  }

  // ─── Notifications ────────────────────────────────────────────────────────

  static Future<bool> requestNotifications() async {
    // Notifications on web use the browser API; permission_handler may not
    // implement `Permission.notification` on web in all setups. Treat as
    // granted on web and rely on browser prompt elsewhere if needed.
    if (kIsWeb) return true;
    return _request(Permission.notification, 'Notifications', 'Enable notifications to receive new messages.');
  }

  // ─── Batch: request all at once on first app open ─────────────────────────

  static Future<void> requestAllOnStartup() async {
    final perms = <Permission>[Permission.camera, Permission.microphone];
    if (!kIsWeb) {
      perms.add(Permission.photos);
      perms.add(Permission.notification);
    }
    final statuses = await perms.request();

    // Log denials for debugging — you can remove this in production
    statuses.forEach((permission, status) {
      if (!status.isGranted) {
        debugPrint('[Permissions] ${permission.toString()} → ${status.toString()}');
      }
    });
  }

  // ─── Internal helper ──────────────────────────────────────────────────────

  static Future<bool> _request(Permission permission, String name, String rationale) async {
    var status = await permission.status;

    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      // Show dialog explaining why and offer to open Settings
      final shouldOpen = await _showSettingsDialog(name, rationale);
      if (shouldOpen) await openAppSettings();
      return false;
    }

    // First time — ask
    status = await permission.request();
    if (status.isGranted) return true;

    if (status.isDenied) {
      _showDeniedSnackbar(name);
    }

    return false;
  }

  static Future<bool> _showSettingsDialog(String name, String rationale) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: const Color(0xFF151E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '$name Permission Required',
          style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '$rationale\n\nPlease enable it in Settings.',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Open Settings', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static void _showDeniedSnackbar(String name) {
    Get.snackbar(
      '$name Permission Denied',
      'Some features may not work without this permission.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF151E2E),
      colorText: const Color(0xFFF1F5F9),
      borderColor: const Color(0xFF1E2D42),
      borderWidth: 0.5,
      borderRadius: 16,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      duration: const Duration(seconds: 3),
    );
  }
}
