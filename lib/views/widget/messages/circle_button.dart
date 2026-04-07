part of '../../screens/chat_screen.dart';

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  const _CircleButton(
      {required this.icon, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? AppTheme.accent.withValues(alpha: 0.15)
              : AppTheme.surface,
          border: Border.all(
              color: active
                  ? AppTheme.accent.withValues(alpha: 0.5)
                  : AppTheme.border,
              width: 0.5),
        ),
        child: Icon(icon,
            color: active ? AppTheme.accent : AppTheme.textSec, size: 20),
      ),
    );
  }
}
