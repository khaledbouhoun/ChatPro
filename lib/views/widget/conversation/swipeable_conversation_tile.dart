part of '../../screens/conversation_screen.dart';

class _SwipeableConversationTile extends StatelessWidget {
  final Conversation conversation;
  final bool isOnline;
  final int index;
  final VoidCallback onDelete;

  const _SwipeableConversationTile({
    super.key,
    required this.conversation,
    required this.isOnline,
    required this.index,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(conversation.id),
      direction: DismissDirection.endToStart,
      background: _DismissBackground(),
      confirmDismiss: (_) async {
        onDelete();
        return false; // We handle deletion ourselves
      },
      child: _ConversationTile(
          conversation: conversation, isOnline: isOnline, index: index),
    );
  }
}
