part of '../../screens/chat_screen.dart';

class _DateChip extends StatelessWidget {
  final DateTime date;
  const _DateChip({required this.date});

  String _label() {
    final now = DateTime.now();
    if (_sameDay(date, now)) return 'Today';
    if (_sameDay(date, now.subtract(const Duration(days: 1))))
      return 'Yesterday';
    return DateFormat('MMMM d, y').format(date);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppTheme.border, thickness: 0.5)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border, width: 0.5),
            ),
            child: Text(
              _label(),
              style: const TextStyle(
                  color: AppTheme.textSec,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: AppTheme.border, thickness: 0.5)),
        ],
      ),
    );
  }
}
