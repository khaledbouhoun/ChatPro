part of '../../screens/chat_screen.dart';

class _StatusIcon extends StatelessWidget {
  final String status;
  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'pending':
        return const Icon(LucideIcons.clock3, size: 11, color: Colors.white38);
      case 'sent':
        return const Icon(LucideIcons.check, size: 11, color: Colors.white54);
      case 'delivered':
        return const Icon(LucideIcons.checkCheck,
            size: 11, color: Colors.white70);
      case 'read':
        return const Icon(LucideIcons.checkCheck,
            size: 11, color: AppTheme.aurora1);
      case 'failed':
        return const Icon(LucideIcons.alertCircle,
            size: 11, color: AppTheme.error);
      default:
        return const SizedBox.shrink();
    }
  }
}
