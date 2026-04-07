part of '../../screens/conversation_screen.dart';

class _DismissBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.15),
        border: Border(
            left: BorderSide(color: AppTheme.error.withOpacity(0.3), width: 1)),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(LucideIcons.trash2, color: AppTheme.error, size: 20),
          SizedBox(height: 4),
          Text(
            'Delete',
            style: TextStyle(
                color: AppTheme.error,
                fontSize: 11,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
