part of '../../screens/chat_screen.dart';

class _TypingIndicator extends StatelessWidget {
  final AnimationController animCtrl;
  const _TypingIndicator({required this.animCtrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          _MiniAvatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.recvBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.border, width: 0.5),
            ),
            child: Row(
              children: List.generate(
                  3, (i) => _Dot(animCtrl: animCtrl, delay: i * 0.15)),
            ),
          ),
        ],
      ),
    );
  }
}
