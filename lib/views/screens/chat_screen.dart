import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:chat_pro/services/permission_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
import 'package:chat_pro/utils/file_bytes.dart';
import 'package:chat_pro/utils/mime_type_helper.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/chat_controller.dart';
import '../../models/message.dart';
import '../../core/theme.dart';
part '../widget/messages/aurora_background.dart';
part '../widget/messages/app_bar.dart';
part '../widget/messages/app_bar_action.dart';
part '../widget/messages/chat_options_sheet.dart';
part '../widget/messages/option_tile.dart';
part '../widget/messages/recording_bar.dart';
part '../widget/messages/pulsing_dot.dart';
part '../widget/messages/waveform_visualizer.dart';
part '../widget/messages/swipeable_message.dart';
part '../widget/messages/chat_bubble.dart';
part '../widget/messages/in_bubble_reply.dart';
part '../widget/messages/attachment_preview.dart';
part '../widget/messages/full_screen_image_view.dart';
part '../widget/messages/audio_player_widget.dart';
part '../widget/messages/bubble_action.dart';
part '../widget/messages/status_icon.dart';
part '../widget/messages/mini_avatar.dart';
part '../widget/messages/date_chip.dart';
part '../widget/messages/typing_indicator.dart';
part '../widget/messages/dot.dart';
part '../widget/messages/reply_preview_bar.dart';
part '../widget/messages/reaction_overlay.dart';
part '../widget/messages/emoji_keyboard.dart';
part '../widget/messages/input_bar.dart';
part '../widget/messages/send_button.dart';
part '../widget/messages/attach_menu.dart';
part '../widget/messages/attach_item.dart';
part '../widget/messages/circle_button.dart';
part '../widget/messages/icon_btn.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  late final ChatController _ctrl;

  late final AnimationController _typingCtrl;
  late final AnimationController _waveformCtrl;
  final _focusNode = FocusNode();
  final RxBool _inputFocused = false.obs;
  final RxBool _showAttachMenu = false.obs;
  final RxBool _isRecording = false.obs;
  final RxBool _showEmojiPicker = false.obs;

  // Search
  final RxBool _searchActive = false.obs;
  final RxString _searchQuery = ''.obs;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  // Reaction target: messageId → show picker
  final Rx<String?> _reactionTargetId = Rx(null);

  // Reply
  final Rx<Message?> _replyTo = Rx(null);

  // Voice recorder
  final AudioRecorder _recorder = AudioRecorder();
  String? _recordingPath;

  // Recording timer
  Timer? _recordingTimer;
  final RxInt _recordingSeconds = 0.obs;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(ChatController());
    _typingCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _waveformCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat();
    _focusNode.addListener(() => _inputFocused.value = _focusNode.hasFocus);
    _searchCtrl.addListener(() => _searchQuery.value = _searchCtrl.text);
    _searchQuery.listen((q) => _ctrl.searchQuery.value = q);
  }

  @override
  void dispose() {
    _typingCtrl.dispose();
    _waveformCtrl.dispose();
    _focusNode.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _recordingTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.bg,
        extendBodyBehindAppBar: true,
        appBar: _AppBar(
          ctrl: _ctrl,
          searchActive: _searchActive,
          searchCtrl: _searchCtrl,
          searchFocus: _searchFocus,
          onSearchActivated: () {
            _searchActive.value = true;
            WidgetsBinding.instance.addPostFrameCallback((_) => _searchFocus.requestFocus());
          },
          onSearchDismissed: () {
            _searchActive.value = false;
            _searchCtrl.clear();
            _ctrl.searchQuery.value = '';
            _searchFocus.unfocus();
          },
        ),
        body: Stack(
          children: [
            _AuroraBackground(),
            Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
                Expanded(child: _buildMessageList()),
                // Typing indicator
                Obx(
                  () => _ctrl.isOtherTyping.value
                      ? _TypingIndicator(animCtrl: _typingCtrl).animate().fadeIn().slideY(begin: 0.5)
                      : const SizedBox.shrink(),
                ),
                _buildReplyPreview(),
                // Emoji picker
                Obx(
                  () => _showEmojiPicker.value
                      ? _EmojiKeyboard(
                          onEmoji: (e) {
                            _ctrl.messageController.text += e;
                            _ctrl.messageController.selection = TextSelection.fromPosition(
                              TextPosition(offset: _ctrl.messageController.text.length),
                            );
                          },
                          onClose: () => _showEmojiPicker.value = false,
                        ).animate().slideY(begin: 1, end: 0, duration: 250.ms, curve: Curves.easeOutCubic)
                      : const SizedBox.shrink(),
                ),
                // Recording bar OR normal input
                Obx(
                  () => _isRecording.value
                      ? _RecordingBar(
                          seconds: _recordingSeconds.value,
                          waveCtrl: _waveformCtrl,
                          onStop: _toggleRecording,
                          onCancel: _cancelRecording,
                        ).animate().slideY(begin: 1, end: 0, duration: 200.ms)
                      : _InputBar(
                          ctrl: _ctrl,
                          focusNode: _focusNode,
                          inputFocused: _inputFocused,
                          showAttachMenu: _showAttachMenu,
                          showEmojiPicker: _showEmojiPicker,
                          isRecording: _isRecording,
                          replyTo: _replyTo,
                          onPickImage: _pickImage,
                          onPickFile: _pickFile,
                          onToggleRecording: _toggleRecording,
                          hasText: _ctrl.hasTextToSend,
                          onChange: (p0) => _ctrl.hasTextToSend.value = p0.isNotEmpty,
                          onSend: () => _ctrl.sendCurrentMessage(replyTo: _replyTo.value).then((_) {
                            _replyTo.value = null;
                            _ctrl.hasTextToSend.value = false;
                          }),
                        ),
                ),
              ],
            ),
            // Reaction picker overlay
            Obx(
              () => _reactionTargetId.value != null
                  ? _ReactionOverlay(
                      onSelect: (emoji) {
                        final id = _reactionTargetId.value!;
                        _reactionTargetId.value = null;
                        _ctrl.saveReaction(id, emoji);
                      },
                      onDismiss: () => _reactionTargetId.value = null,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Message list ──────────────────────────────────────────────────────────

  Widget _buildMessageList() {
    return Obx(() {
      final msgs = _ctrl.filteredMessages;
      final isSearching = _searchQuery.value.isNotEmpty;

      if (_ctrl.isLoading.value && msgs.isEmpty) {
        return const Center(child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2));
      }

      if (msgs.isEmpty && isSearching) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off_rounded, color: AppTheme.textMuted, size: 48),
              const SizedBox(height: 12),
              Text(
                'No messages match "${_searchQuery.value}"',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        controller: _ctrl.scrollController,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        itemCount: msgs.length + (_ctrl.isLoadingMore.value ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (_ctrl.isLoadingMore.value && i == 0) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
                ),
              ),
            );
          }
          final idx = _ctrl.isLoadingMore.value ? i - 1 : i;
          final msg = msgs[idx];
          final prev = idx > 0 ? msgs[idx - 1] : null;
          final next = idx < msgs.length - 1 ? msgs[idx + 1] : null;

          final isSender = msg.senderId == _ctrl.currentUserId;
          final showAvatar = !isSender && (next == null || next.senderId != msg.senderId);
          final isGrouped = prev != null && prev.senderId == msg.senderId && msg.createdAt.difference(prev.createdAt).inMinutes < 3;
          final showDate = prev == null || !_sameDay(prev.createdAt, msg.createdAt);

          return Column(
            children: [
              if (showDate) _DateChip(date: msg.createdAt),
              _SwipeableMessage(
                key: ValueKey(msg.localId ?? msg.id),
                message: msg,
                isSender: isSender,
                showAvatar: showAvatar,
                isGrouped: isGrouped,
                onLongPress: () {
                  final id = msg.id ?? msg.localId;
                  if (id != null) _reactionTargetId.value = id;
                },
                onSwipe: () => _replyTo.value = msg,
                onRetry: msg.status == 'failed' ? () => _ctrl.retryMessage(msg) : null,
                onDiscard: msg.status == 'failed' ? () => _ctrl.discardFailedMessage(msg) : null,
                index: idx,
                currentUserId: _ctrl.currentUserId,
              ),
            ],
          );
        },
      );
    });
  }

  Widget _buildReplyPreview() {
    return Obx(() {
      final reply = _replyTo.value;
      if (reply == null) return const SizedBox.shrink();
      return _ReplyPreviewBar(
        message: reply,
        onCancel: () => _replyTo.value = null,
      ).animate().slideY(begin: 1, end: 0, duration: 200.ms, curve: Curves.easeOut);
    });
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  // ─── Attachment handlers ───────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    _showAttachMenu.value = false;
    final granted = source == ImageSource.camera ? await PermissionService.requestCamera() : await PermissionService.requestPhotos();
    if (!granted) return;
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: source, imageQuality: 80);
      if (file == null) return;
      _showUploadProgress();
      Uint8List bytes;
      String? filename;
      if (kIsWeb) {
        bytes = await file.readAsBytes();
        filename = file.name;
      } else if (file.path.isNotEmpty) {
        bytes = await getFileBytes(file.path);
        filename = p.basename(file.path);
      } else {
        return;
      }

      final url = await _uploadFileFromBytes(bytes, 'images', filename: filename);
      if (url != null) await _ctrl.sendFileMessage('📷 Photo', url, 'image');
    } catch (e) {
      Get.snackbar('Error', 'Could not pick image: $e', backgroundColor: AppTheme.card, colorText: AppTheme.textPrim);
    } finally {
      Get.back();
    }
  }

  Future<void> _pickFile() async {
    _showAttachMenu.value = false;
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.isEmpty) return;
      final picked = result.files.first;
      _showUploadProgress();
      String? url;
      if (picked.bytes != null) {
        url = await _uploadFileFromBytes(picked.bytes!, 'files', filename: picked.name);
      } else if (picked.path != null) {
        final bytes = await getFileBytes(picked.path!);
        url = await _uploadFileFromBytes(bytes, 'files', filename: picked.name);
      }
      if (url != null) await _ctrl.sendFileMessage('📎 ${picked.name}', url, 'document');
    } catch (e) {
      Get.snackbar('Error', 'Could not pick file: $e', backgroundColor: AppTheme.card, colorText: AppTheme.textPrim);
    } finally {
      Get.back();
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording.value) {
      // ── Stop recording ──
      _recordingTimer?.cancel();
      _recordingSeconds.value = 0;
      _isRecording.value = false;
      final path = await _recorder.stop();
      if (path == null) {
        // On some web implementations stop() may not return a filesystem path.
        Get.snackbar('Recording', 'Recording finished but could not access file on this platform.',
            backgroundColor: AppTheme.card, colorText: AppTheme.textPrim);
        return;
      }
      _showUploadProgress();
      try {
        final bytes = await getFileBytes(path);
        final url = await _uploadFileFromBytes(bytes, 'audio', filename: p.basename(path));
        if (url != null) await _ctrl.sendFileMessage('🎤 Voice message', url, 'audio');
      } finally {
        Get.back();
      }
    } else {
      // ── Start recording – check permission first ──
      final granted = await PermissionService.requestMicrophone();
      if (!granted) {
        Get.snackbar(
          'Permission Required',
          'Microphone access is needed to record voice messages.',
          backgroundColor: AppTheme.card,
          colorText: AppTheme.textPrim,
        );
        return;
      }
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) return;

      if (kIsWeb) {
        final path = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        _recordingPath = path;
        await _recorder.start(const RecordConfig(), path: path);
      } else {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        _recordingPath = path;
        await _recorder.start(const RecordConfig(), path: path);
      }
      _isRecording.value = true;
      _recordingSeconds.value = 0;
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) => _recordingSeconds.value++);
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _cancelRecording() async {
    _recordingTimer?.cancel();
    _recordingSeconds.value = 0;
    _isRecording.value = false;
    await _recorder.stop(); // discard file
  }

  Future<String?> _uploadFile(File file, String folder) async {
    // removed: keep legacy signature removed in favor of byte-based upload
    throw UnimplementedError('Use _uploadFileFromBytes instead');
  }

  Future<String?> _uploadFileFromBytes(Uint8List bytes, String folder, {String? filename}) async {
    try {
      final ext = filename != null ? p.extension(filename) : '.bin';

      // Detect MIME type from bytes (magic bytes) first, then fall back to extension
      final mimeType = MimeTypeHelper.getMimeType(bytes, filename: filename);

      // Create metadata with proper Content-Type to prevent application/octet-stream
      final metadata = SettableMetadata(
        contentType: mimeType,
        // Optional: Add custom metadata for tracking
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'originalFilename': filename ?? 'unknown',
        },
      );

      final ref = FirebaseStorage.instance.ref().child('$folder/${DateTime.now().millisecondsSinceEpoch}$ext');

      // putData with metadata ensures correct Content-Type is set
      await ref.putData(bytes, metadata);

      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('[Chat] Upload error: $e');
      return null;
    }
  }

  void _showUploadProgress() {
    Get.dialog(
      PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(16)),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.accent),
                SizedBox(height: 16),
                Text('Uploading…', style: TextStyle(color: AppTheme.textPrim, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}
