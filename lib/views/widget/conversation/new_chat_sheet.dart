part of '../../screens/conversation_screen.dart';

class _NewChatSheet extends StatelessWidget {
  final TextEditingController nameController;
  final VoidCallback onStart;
  const _NewChatSheet({required this.nameController, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      // Use AnimatedPadding so it smoothly follows the keyboard
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom > 0 ? bottom + 16 : 24),
      decoration: const BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      // SingleChildScrollView prevents the 0.1px overflow when keyboard opens
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.12),
                      shape: BoxShape.circle),
                  child: const Icon(LucideIcons.userPlus,
                      color: AppTheme.accent, size: 18),
                ),
                const SizedBox(width: 12),
                const Text(
                  'New Conversation',
                  style: TextStyle(
                      color: AppTheme.textPrim,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.only(left: 48),
              child: Text(
                'Enter the chat code of the person you want to message',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border, width: 0.8),
              ),
              child: TextField(
                controller: nameController,
                autofocus: true,
                style: const TextStyle(color: AppTheme.textPrim, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Enter chat code…',
                  hintStyle: TextStyle(color: AppTheme.textMuted),
                  prefixIcon: Icon(LucideIcons.hash,
                      size: 18, color: AppTheme.textMuted),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onSubmitted: (_) => onStart(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Start Chat',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
