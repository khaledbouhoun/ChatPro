part of '../../screens/chat_screen.dart';

class _MiniAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppTheme.aurora1, AppTheme.aurora2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(LucideIcons.user, size: 14, color: Colors.white),
    );
  }
}
