part of '../../screens/chat_screen.dart';

class _EmojiKeyboard extends StatelessWidget {
  final ValueChanged<String> onEmoji;
  final VoidCallback onClose;

  const _EmojiKeyboard({required this.onEmoji, required this.onClose});

  // Common emojis grouped into rows
  static const _emojis = [
    '😀',
    '😂',
    '🥹',
    '😍',
    '🥰',
    '😘',
    '😎',
    '🤩',
    '😢',
    '😭',
    '😡',
    '🤬',
    '🤯',
    '😱',
    '🥳',
    '😴',
    '👍',
    '👎',
    '❤️',
    '🔥',
    '⭐',
    '✅',
    '🎉',
    '💯',
    '👋',
    '🙏',
    '💪',
    '🤝',
    '👏',
    '🫶',
    '💔',
    '💙',
    '🐶',
    '🐱',
    '🌸',
    '🌈',
    '☀️',
    '🍕',
    '🎮',
    '💎',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: AppTheme.card,
        border:
            const Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: Column(
        children: [
          // Handle + close
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 4),
            child: Row(
              children: [
                const Text(
                  'Emoji',
                  style: TextStyle(
                      color: AppTheme.textSec,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onClose,
                  child: const Icon(LucideIcons.x,
                      color: AppTheme.textMuted, size: 16),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 8,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: _emojis
                  .map(
                    (e) => GestureDetector(
                      onTap: () => onEmoji(e),
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(e, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
