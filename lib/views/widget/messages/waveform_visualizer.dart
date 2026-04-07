part of '../../screens/chat_screen.dart';

class _WaveformVisualizer extends StatelessWidget {
  final AnimationController controller;
  const _WaveformVisualizer({required this.controller});

  static final _rng = Random(42);
  static final _heights =
      List.generate(22, (i) => 0.3 + _rng.nextDouble() * 0.7);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(_heights.length, (i) {
            final phase = (controller.value + i / _heights.length) % 1.0;
            final scale =
                0.3 + 0.7 * (sin(phase * pi * 2) * 0.5 + 0.5) * _heights[i];
            return Container(
              width: 2.5,
              height: 28 * scale,
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.6 + 0.4 * scale),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
