part of '../../screens/chat_screen.dart';

class _ChatOptionsSheet extends StatelessWidget {
  final ChatController ctrl;
  final VoidCallback onSearchActivated;
  const _ChatOptionsSheet(
      {required this.ctrl, required this.onSearchActivated});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: const BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          _OptionTile(
            icon: LucideIcons.checkCheck,
            label: 'Mark all as read',
            onTap: () => Get.back(),
          ),
          _OptionTile(
            icon: LucideIcons.search,
            label: 'Search in conversation',
            onTap: () {
              Get.back();
              onSearchActivated();
            },
          ),
          _OptionTile(
              icon: LucideIcons.bellOff,
              label: 'Mute notifications',
              onTap: () => Get.back()),
          _OptionTile(
              icon: LucideIcons.trash2,
              label: 'Clear chat history',
              color: AppTheme.error,
              onTap: () => Get.back()),
        ],
      ),
    );
  }
}
