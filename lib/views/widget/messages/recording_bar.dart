part of '../../screens/chat_screen.dart';

class _RecordingBar extends StatelessWidget {
  final int seconds;
  final AnimationController waveCtrl;
  final VoidCallback onStop;
  final VoidCallback onCancel;

  const _RecordingBar({
    required this.seconds,
    required this.waveCtrl,
    required this.onStop,
    required this.onCancel,
  });

  String _fmtTime(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: AppTheme.bg.withValues(alpha: 0.95),
        border:
            const Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: Row(
        children: [
          // Cancel
          GestureDetector(
            onTap: onCancel,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.error.withValues(alpha: 0.12),
                border:
                    Border.all(color: AppTheme.error.withValues(alpha: 0.4)),
              ),
              child: const Icon(LucideIcons.trash2,
                  color: AppTheme.error, size: 18),
            ),
          ),
          const SizedBox(width: 12),

          // Waveform + timer
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                    color: AppTheme.error.withValues(alpha: 0.4), width: 0.8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Pulsing red dot
                  _PulsingDot(),
                  const SizedBox(width: 10),
                  // Timer
                  Text(
                    _fmtTime(seconds),
                    style: const TextStyle(
                      color: AppTheme.error,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Waveform
                  Expanded(child: _WaveformVisualizer(controller: waveCtrl)),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Stop / Send
          GestureDetector(
            onTap: onStop,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppTheme.accent, Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 4))
                ],
              ),
              child:
                  const Icon(LucideIcons.send, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
