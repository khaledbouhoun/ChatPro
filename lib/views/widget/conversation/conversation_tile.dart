part of '../../screens/conversation_screen.dart';

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final bool isOnline;
  final int index;

  const _ConversationTile(
      {required this.conversation,
      required this.isOnline,
      required this.index});

  String _timeLabel(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    if (now.difference(dt).inDays == 0) return DateFormat.jm().format(dt);
    if (now.difference(dt).inDays == 1) return 'Yesterday';
    if (now.difference(dt).inDays < 7) return DateFormat('EEE').format(dt);
    return DateFormat('d/M/yy').format(dt);
  }

  // Deterministic gradient per conversation
  List<Color> _avatarColors(String id) {
    final palettes = [
      [const Color(0xFF0EA5E9), const Color(0xFF6366F1)],
      [const Color(0xFF10B981), const Color(0xFF0EA5E9)],
      [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
      [const Color(0xFF8B5CF6), const Color(0xFFEC4899)],
      [const Color(0xFF3B82F6), const Color(0xFF06B6D4)],
    ];
    return palettes[id.hashCode.abs() % palettes.length];
  }

  @override
  Widget build(BuildContext context) {
    final name = conversation.otherUserName ?? '?';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final timeStr = _timeLabel(conversation.lastMessageTime);
    final colors = _avatarColors(conversation.id);
    final hasUnread = conversation.unreadCount > 0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Get.find<ConversationListController>().markAsRead(conversation.id);
        Get.toNamed('/chat', arguments: conversation.id);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
            color: Colors.transparent, borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                Get.find<ConversationListController>()
                    .markAsRead(conversation.id);
                Get.toNamed('/chat', arguments: conversation.id);
              },
              splashColor: AppTheme.accent.withOpacity(0.05),
              highlightColor: AppTheme.surface.withOpacity(0.5),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    // Avatar
                    Stack(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: colors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colors[0].withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initial,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (isOnline)
                          Positioned(
                            right: 1,
                            bottom: 1,
                            child: Container(
                              width: 13,
                              height: 13,
                              decoration: BoxDecoration(
                                color: AppTheme.online,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: AppTheme.bg, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(width: 12),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    color: AppTheme.textPrim,
                                    fontSize: 15,
                                    fontWeight: hasUnread
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    letterSpacing: 0.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                timeStr,
                                style: TextStyle(
                                  color: hasUnread
                                      ? AppTheme.accent
                                      : AppTheme.textMuted,
                                  fontSize: 11,
                                  fontWeight: hasUnread
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  conversation.lastMessage ??
                                      'Start a conversation',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: hasUnread
                                        ? AppTheme.textSec
                                        : AppTheme.textMuted,
                                    fontSize: 13,
                                    fontWeight: hasUnread
                                        ? FontWeight.w500
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                              if (hasUnread)
                                Container(
                                  constraints:
                                      const BoxConstraints(minWidth: 20),
                                  height: 20,
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.badge,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.badge.withOpacity(0.4),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    conversation.unreadCount > 99
                                        ? '99+'
                                        : conversation.unreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index.clamp(0, 15) * 40))
        .fadeIn(duration: 350.ms)
        .slideX(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
  }
}
