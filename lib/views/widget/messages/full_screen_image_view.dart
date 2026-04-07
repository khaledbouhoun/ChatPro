part of '../../screens/chat_screen.dart';

class _FullScreenImageView extends StatelessWidget {
  final String url;
  const _FullScreenImageView({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.download,
                color: Colors.white70, size: 20),
            onPressed: () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5.0,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return const Center(
                  child: CircularProgressIndicator(color: AppTheme.accent));
            },
            errorBuilder: (_, __, ___) => const Center(
                child: Icon(LucideIcons.imageOff,
                    color: AppTheme.textMuted, size: 48)),
          ),
        ),
      ),
    );
  }
}
