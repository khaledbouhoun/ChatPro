part of '../../screens/chat_screen.dart';

class _SwipeableMessage extends StatefulWidget {
  final Message message;
  final bool isSender;
  final bool showAvatar;
  final bool isGrouped;
  final VoidCallback? onLongPress;
  final VoidCallback? onSwipe;
  final VoidCallback? onRetry;
  final VoidCallback? onDiscard;
  final int index;
  final String currentUserId;

  const _SwipeableMessage({
    super.key,
    required this.message,
    required this.isSender,
    required this.showAvatar,
    required this.isGrouped,
    this.onLongPress,
    this.onSwipe,
    this.onRetry,
    this.onDiscard,
    required this.index,
    required this.currentUserId,
  });

  @override
  State<_SwipeableMessage> createState() => _SwipeableMessageState();
}

class _SwipeableMessageState extends State<_SwipeableMessage> with SingleTickerProviderStateMixin {
  double _dragX = 0;
  bool _triggered = false;
  late final AnimationController _snapCtrl;
  late Animation<double> _snapAnim;

  @override
  void initState() {
    super.initState();
    _snapCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _snapCtrl.dispose();
    super.dispose();
  }

  void _onHorizontalUpdate(DragUpdateDetails d) {
    final delta = widget.isSender ? d.delta.dx.clamp(-60.0, 0.0) : d.delta.dx.clamp(0.0, 60.0);
    setState(() => _dragX = (_dragX + delta).clamp(widget.isSender ? -60.0 : 0.0, widget.isSender ? 0.0 : 60.0));
    if (!_triggered && _dragX.abs() > 40) {
      _triggered = true;
      HapticFeedback.lightImpact();
      widget.onSwipe?.call();
    }
  }

  void _onHorizontalEnd(DragEndDetails _) {
    _triggered = false;
    _snapAnim = Tween<double>(begin: _dragX, end: 0).animate(
      CurvedAnimation(parent: _snapCtrl, curve: Curves.elasticOut),
    )..addListener(() => setState(() => _dragX = _snapAnim.value));
    _snapCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final topPad = widget.isGrouped ? 2.0 : 8.0;
    final hasReactions = widget.message.reactions.isNotEmpty;
    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalUpdate,
      onHorizontalDragEnd: _onHorizontalEnd,
      onLongPress: () {
        HapticFeedback.mediumImpact();
        widget.onLongPress?.call();
      },
      child: Transform.translate(
        offset: Offset(_dragX, 0),
        child: Padding(
          padding: EdgeInsets.only(top: topPad, bottom: hasReactions ? 20.0 : 0.0),
          child: Row(
            mainAxisAlignment: widget.isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!widget.isSender) ...[
                widget.showAvatar ? _MiniAvatar() : const SizedBox(width: 32),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: _ChatBubble(
                  message: widget.message,
                  isSender: widget.isSender,
                  isGrouped: widget.isGrouped,
                  onRetry: widget.onRetry,
                  onDiscard: widget.onDiscard,
                  currentUserId: widget.currentUserId,
                ),
              ),
              if (widget.isSender) const SizedBox(width: 4),
            ],
          ),
        ),
      )
          .animate(delay: Duration(milliseconds: widget.index.clamp(0, 12) * 30))
          .fadeIn(duration: 350.ms)
          .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
    );
  }
}
