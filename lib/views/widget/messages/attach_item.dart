part of '../../screens/chat_screen.dart';

class _AttachItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int index;
  final VoidCallback onTap;
  const _AttachItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: (MediaQuery.of(context).size.width - 32 - 5 * 16) / 6,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSec,
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: index * 35))
          .fadeIn()
          .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),
    );
  }
}
