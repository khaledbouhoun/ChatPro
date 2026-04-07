part of '../../screens/chat_screen.dart';

class _AttachmentPreview extends StatelessWidget {
  final Message message;
  const _AttachmentPreview({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isImage && message.fileUrl != null) {
      return GestureDetector(
        onTap: () => _openFullscreenImage(context, message.fileUrl!),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              Image.network(
                message.fileUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    width: double.infinity,
                    height: 200,
                    color: AppTheme.surface,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null,
                        color: AppTheme.accent,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  // Log detailed error info for debugging
                  debugPrint('❌ Image load error:');
                  debugPrint('   URL: ${message.fileUrl}');
                  debugPrint('   Error: $error');
                  
                  // Check if it's a statusCode: 0 (MIME type) issue
                  if (error.toString().contains('statusCode: 0')) {
                    debugPrint('⚠️  This indicates wrong MIME type (application/octet-stream)');
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
              ),
              // Tap overlay hint
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.maximize2, color: Colors.white, size: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (message.isAudio && message.fileUrl != null) {
      return _AudioPlayerWidget(url: message.fileUrl!);
    }

    if (message.isDocument && message.fileUrl != null) {
      return GestureDetector(
        onTap: () => _openUrl(message.fileUrl!),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.file, color: AppTheme.warning, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.content,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.textPrim, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const Text('Tap to open', style: TextStyle(color: AppTheme.textSec, fontSize: 10)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(LucideIcons.externalLink, color: AppTheme.textSec, size: 14),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _openFullscreenImage(BuildContext context, String url) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _FullScreenImageView(url: url)));
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
