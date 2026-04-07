part of '../../screens/chat_screen.dart';

class _SendButton extends StatelessWidget {
  final bool hasText;
  final bool isRecording;
  final VoidCallback onSend;
  final VoidCallback onMic;

  const _SendButton(
      {required this.hasText,
      required this.isRecording,
      required this.onSend,
      required this.onMic});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: hasText ? onSend : onMic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: isRecording
                ? [AppTheme.error, const Color(0xFFB91C1C)]
                : [AppTheme.accent, const Color(0xFF1D4ED8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: (isRecording ? AppTheme.error : AppTheme.accent)
                  .withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          hasText
              ? LucideIcons.send
              : isRecording
                  ? LucideIcons.square
                  : LucideIcons.mic,
          color: Colors.white,
          size: 18,
        ),
      ),
    ).animate(key: ValueKey('$hasText-$isRecording')).scale(
        begin: const Offset(0.7, 0.7),
        duration: 250.ms,
        curve: Curves.elasticOut);
  }
}
