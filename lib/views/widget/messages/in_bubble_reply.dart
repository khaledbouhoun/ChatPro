part of '../../screens/chat_screen.dart';

class _InBubbleReply extends StatelessWidget {
  final String content;
  final bool isOwnReply;
  final bool isSender;

  const _InBubbleReply(
      {required this.content,
      required this.isOwnReply,
      required this.isSender});

  @override
  Widget build(BuildContext context) {
    final barColor =
        isSender ? Colors.white.withValues(alpha: 0.5) : AppTheme.replyBar;
    final bgColor = isSender
        ? Colors.black.withValues(alpha: 0.15)
        : AppTheme.surface.withValues(alpha: 0.8);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: barColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isOwnReply ? 'You' : 'Them',
            style: TextStyle(
                color: barColor, fontSize: 10, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: isSender
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppTheme.textSec,
                fontSize: 12),
          ),
        ],
      ),
    );
  }
}
