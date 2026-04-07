part of '../../screens/chat_screen.dart';

class _InputBar extends StatelessWidget {
  final ChatController ctrl;
  final FocusNode focusNode;
  final RxBool inputFocused;
  final RxBool showAttachMenu;
  final RxBool showEmojiPicker; // ← NEW
  final RxBool isRecording;
  final Rx<Message?> replyTo;
  final VoidCallback onPickFile;
  final VoidCallback onToggleRecording;
  final VoidCallback onSend;
  final Function(String)? onChange;
  final Future<void> Function(ImageSource) onPickImage;
  RxBool hasText;

  _InputBar({
    required this.ctrl,
    required this.focusNode,
    required this.inputFocused,
    required this.showAttachMenu,
    required this.showEmojiPicker, // ← NEW
    required this.isRecording,
    required this.replyTo,
    required this.onPickImage,
    required this.onPickFile,
    required this.onToggleRecording,
    required this.onSend,
    required this.onChange,
    required this.hasText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Obx(
          () => showAttachMenu.value
              ? _AttachMenu(
                  onClose: () => showAttachMenu.value = false,
                  onGallery: () => onPickImage(ImageSource.gallery),
                  onCamera: () => onPickImage(ImageSource.camera),
                  onFile: onPickFile,
                )
                  .animate()
                  .slideY(
                      begin: 1,
                      end: 0,
                      duration: 250.ms,
                      curve: Curves.easeOutCubic)
                  .fadeIn()
              : const SizedBox.shrink(),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(
              12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
          decoration: BoxDecoration(
            color: AppTheme.bg.withValues(alpha: 0.85),
            border: const Border(
                top: BorderSide(color: AppTheme.border, width: 0.5)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Obx(
                () => _CircleButton(
                  icon: showAttachMenu.value ? LucideIcons.x : LucideIcons.plus,
                  onTap: () {
                    showAttachMenu.value = !showAttachMenu.value;
                    if (showAttachMenu.value) focusNode.unfocus();
                  },
                  active: showAttachMenu.value,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  constraints:
                      const BoxConstraints(minHeight: 44, maxHeight: 120),
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.border, width: 0.5),
                  ),
                  child: TextField(
                    controller: ctrl.messageController,
                    focusNode: focusNode,
                    onChanged: onChange,
                    maxLines: 5,
                    minLines: 1,
                    style: const TextStyle(
                        color: AppTheme.textPrim, fontSize: 14.5, height: 1.4),
                    decoration: const InputDecoration(
                      hintText: 'Message…',
                      hintStyle:
                          TextStyle(color: AppTheme.textMuted, fontSize: 14.5),
                      contentPadding: EdgeInsets.fromLTRB(16, 11, 8, 11),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Obx(() {
                return _SendButton(
                  hasText: hasText.value,
                  isRecording: isRecording.value,
                  onSend: onSend,
                  onMic: onToggleRecording,
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
