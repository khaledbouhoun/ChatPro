part of '../../screens/chat_screen.dart';

class _ChatBubble extends StatelessWidget {
  final Message message;
  final bool isSender;
  final bool isGrouped;
  final VoidCallback? onRetry;
  final VoidCallback? onDiscard;
  final String currentUserId;

  const _ChatBubble({
    required this.message,
    required this.isSender,
    required this.isGrouped,
    this.onRetry,
    this.onDiscard,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final r = Radius.circular(isGrouped ? 6 : 18);
    final tip = const Radius.circular(4);
    final full = const Radius.circular(18);

    final borderRadius = isSender
        ? BorderRadius.only(topLeft: full, topRight: isGrouped ? r : full, bottomLeft: full, bottomRight: tip)
        : BorderRadius.only(topLeft: isGrouped ? r : full, topRight: full, bottomLeft: tip, bottomRight: full);

    final isFailed = message.status == 'failed';

    // Build reaction summary: emoji → count
    final Map<String, int> emojiCount = {};
    message.reactions.forEach((_, emoji) {
      emojiCount[emoji] = (emojiCount[emoji] ?? 0) + 1;
    });

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: isSender
                ? LinearGradient(
                    colors: isFailed ? [const Color(0xFF7F1D1D), const Color(0xFF991B1B)] : [AppTheme.senderBg, const Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSender ? null : AppTheme.recvBg,
            border: Border.all(
              color: isFailed
                  ? AppTheme.error.withValues(alpha: 0.4)
                  : isSender
                      ? Colors.transparent
                      : AppTheme.border,
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isSender ? AppTheme.accent.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Reply preview ───────────────────────────────────
              if (message.hasReply) ...[
                _InBubbleReply(
                  content: message.replyToContent ?? '',
                  isOwnReply: message.replyToSenderId == currentUserId,
                  isSender: isSender,
                ),
                const SizedBox(height: 6),
              ],

              // ── File / media attachment ──────────────────────────
              if (message.hasFile) ...[
                _AttachmentPreview(message: message),
                const SizedBox(height: 6),
              ],

              // ── Text content (only if meaningful) ──────────────
              if (message.content.isNotEmpty &&
                  !message.content.startsWith('📷') &&
                  !message.content.startsWith('📎') &&
                  !message.content.startsWith('🎤'))
                Text(message.content, style: const TextStyle(color: AppTheme.textPrim, fontSize: 14.5, height: 1.4)),

              const SizedBox(height: 4),

              // ── Timestamp + status ──────────────────────────────
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    DateFormat.jm().format(message.createdAt),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10),
                  ),
                  if (isSender) ...[const SizedBox(width: 4), _StatusIcon(status: message.status)],
                ],
              ),

              // ── Failed actions ──────────────────────────────────
              if (isFailed)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _BubbleAction(icon: LucideIcons.refreshCw, label: 'Retry', color: AppTheme.warning, onTap: onRetry),
                      const SizedBox(width: 8),
                      _BubbleAction(icon: LucideIcons.trash2, label: 'Discard', color: AppTheme.error, onTap: onDiscard),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // ── Reaction badges ─────────────────────────────────────
        if (emojiCount.isNotEmpty)
          Positioned(
            bottom: -14,
            right: isSender ? null : 6,
            left: isSender ? 6 : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: emojiCount.entries
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Text(e.value > 1 ? '${e.key} ${e.value}' : e.key, style: const TextStyle(fontSize: 12)),
                      ),
                    )
                    .toList(),
              ),
            ).animate().scale(begin: const Offset(0.5, 0.5), duration: 300.ms, curve: Curves.elasticOut),
          ),
      ],
    );
  }
}
