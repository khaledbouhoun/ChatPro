part of '../../screens/chat_screen.dart';

class _Dot extends StatelessWidget {
  final AnimationController animCtrl;
  final double delay;
  const _Dot({required this.animCtrl, required this.delay});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animCtrl,
      builder: (_, __) {
        final t = (animCtrl.value - delay).clamp(0.0, 1.0);
        final scale = 0.6 + 0.4 * (1 - (2 * t - 1).abs());
        return Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
              color: AppTheme.textSec.withValues(alpha: 0.5 + 0.5 * scale),
              shape: BoxShape.circle),
          transform: Matrix4.identity()..scale(scale, scale),
          transformAlignment: Alignment.center,
        );
      },
    );
  }
}
