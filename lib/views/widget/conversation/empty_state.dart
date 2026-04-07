part of '../../screens/conversation_screen.dart';

class _EmptyState extends SliverFillRemaining {
  _EmptyState({required bool isSearch})
      : super(
          child: Center(  
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Icon(
                    isSearch
                        ? LucideIcons.searchX
                        : LucideIcons.messageSquareDashed,
                    size: 32,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isSearch ? 'No results found' : 'No conversations yet',
                  style: const TextStyle(
                      color: AppTheme.textSec,
                      fontSize: 17,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  isSearch
                      ? 'Try a different search term'
                      : 'Tap the button below to start chatting',
                  style:
                      const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ],
            )
                .animate()
                .fadeIn(delay: 200.ms)
                .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOut),
          ),
        );
}
