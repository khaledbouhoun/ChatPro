part of '../../screens/chat_screen.dart';

class _ReactionOverlay extends StatelessWidget {
  final ValueChanged<String> onSelect;
  final VoidCallback onDismiss;

  const _ReactionOverlay({required this.onSelect, required this.onDismiss});

  static const _emojis = ['❤️', '😂', '😮', '😢', '😡', '👍', '🔥', '👏'];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Colors.black.withValues(alpha: 0.4),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 120),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: AppTheme.border),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: _emojis
                    .asMap()
                    .entries
                    .map(
                      (e) => GestureDetector(
                        onTap: () => onSelect(e.value),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(e.value,
                              style: const TextStyle(fontSize: 28)),
                        )
                            .animate(delay: Duration(milliseconds: e.key * 40))
                            .scale(
                                begin: const Offset(0.3, 0.3),
                                curve: Curves.elasticOut,
                                duration: 400.ms)
                            .fadeIn(),
                      ),
                    )
                    .toList(),
              ),
            )
                .animate()
                .scale(
                    begin: const Offset(0.8, 0.8),
                    duration: 250.ms,
                    curve: Curves.easeOut)
                .fadeIn(),
          ],
        ),
      ),
    );
  }
}
