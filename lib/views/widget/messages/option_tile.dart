part of '../../screens/chat_screen.dart';

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _OptionTile(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.textPrim;
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
            color: c.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, color: c, size: 17),
      ),
      title: Text(label,
          style:
              TextStyle(color: c, fontSize: 14, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
