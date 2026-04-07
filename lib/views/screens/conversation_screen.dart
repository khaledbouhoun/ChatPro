import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

import '../../controllers/conversation_controller.dart';
import '../../models/conversation.dart';
import '../../services/auth_service.dart';
import '../../core/theme.dart';
part '../widget/conversation/aurora_background.dart';
part '../widget/conversation/segmented_tabs.dart';
part '../widget/conversation/swipeable_conversation_tile.dart';
part '../widget/conversation/dismiss_background.dart';
part '../widget/conversation/conversation_tile.dart';
part '../widget/conversation/skeleton_list.dart';
part '../widget/conversation/empty_state.dart';
part '../widget/conversation/new_chat_sheet.dart';
part '../widget/conversation/delete_sheet.dart';


class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen>
    with SingleTickerProviderStateMixin {
  late final ConversationListController _ctrl;
  late final AuthService _auth;
  late final TabController _tabCtrl;

  final RxBool _searchActive = false.obs;
  final RxString _searchQuery = ''.obs;
  final _searchFocusNode = FocusNode();
  final _searchTextCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(ConversationListController());
    _auth = Get.find<AuthService>();
    _tabCtrl = TabController(length: 3, vsync: this);

    _searchTextCtrl.addListener(
        () => _searchQuery.value = _searchTextCtrl.text.toLowerCase());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchFocusNode.dispose();
    _searchTextCtrl.dispose();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.bg,
        body: Stack(
          children: [
            _AuroraBackground(),
            RefreshIndicator(
              color: AppTheme.accent,
              backgroundColor: AppTheme.card,
              displacement: 80,
              onRefresh: () async {
                _ctrl.loadLocalConversations();
                _ctrl.setupFirestoreStream();
              },
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  _buildSliverAppBar(context),
                  _buildSearchBar(),
                  _buildTabBar(),
                  _buildBody()
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: _buildFAB(),
      ),
    );
  }

  // ─── Sliver AppBar ────────────────────────────────────────────────────────

  Widget _buildSliverAppBar(BuildContext context) {
    final chatCode = _auth.user?.chatCode ?? '';

    return SliverAppBar(
      expandedHeight: 110,
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.bg.withOpacity(0.6),
                border: const Border(
                    bottom: BorderSide(color: AppTheme.border, width: 0.5)),
              ),
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 20,
                  right: 16,
                  bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Title block
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                  color: AppTheme.accent,
                                  shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Messages',
                              style: TextStyle(
                                color: AppTheme.textPrim,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Obx(
                          () => Text(
                            '${_ctrl.conversations.length} conversations',
                            style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w400),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Chat code chip
                  if (chatCode.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: chatCode));
                        HapticFeedback.lightImpact();
                        _showCopiedSnackbar(chatCode);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppTheme.accent.withOpacity(0.3),
                              width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.hash,
                                size: 12, color: AppTheme.accent),
                            const SizedBox(width: 4),
                            Text(
                              chatCode,
                              style: const TextStyle(
                                color: AppTheme.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(LucideIcons.copy,
                                size: 11, color: AppTheme.accent),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Search Bar ───────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Obx(
              () => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: AppTheme.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: _searchActive.value
                          ? AppTheme.accent.withOpacity(0.5)
                          : AppTheme.border,
                      width: 0.8),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 14),
                      child: Icon(LucideIcons.search,
                          size: 16, color: AppTheme.textMuted),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchTextCtrl,
                        focusNode: _searchFocusNode,
                        onTap: () => _searchActive.value = true,
                        onEditingComplete: () => _searchFocusNode.unfocus(),
                        style: const TextStyle(
                            color: AppTheme.textPrim, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Search conversations…',
                          hintStyle: TextStyle(
                              color: AppTheme.textMuted, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 13),
                        ),
                      ),
                    ),
                    Obx(
                      () => _searchQuery.value.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchTextCtrl.clear();
                                _searchFocusNode.unfocus();
                                _searchActive.value = false;
                              },
                              child: const Padding(
                                padding: EdgeInsets.only(right: 12),
                                child: Icon(LucideIcons.x,
                                    size: 16, color: AppTheme.textMuted),
                              ),
                            )
                          : const SizedBox(width: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.1),
    );
  }

  // ─── Tab Bar ──────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: _SegmentedTabs(controller: _tabCtrl),
      ).animate().fadeIn(delay: 150.ms),
    );
  }

  // ─── Body ─────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    return Obx(() {
      final query = _searchQuery.value;
      final all = _ctrl.conversations;

      if (_ctrl.isLoading.value && all.isEmpty) {
        return _SkeletonList();
      }

      // Filter by tab + search
      List<Conversation> filtered = all.where((c) {
        if (query.isNotEmpty) {
          final name = (c.otherUserName ?? '').toLowerCase();
          final msg = (c.lastMessage ?? '').toLowerCase();
          return name.contains(query) || msg.contains(query);
        }
        return true;
      }).toList();

      // Tab filtering (mock — wire to real flags)
      if (_tabCtrl.index == 1) {
        filtered = filtered.where((c) => (c.unreadCount) > 0).toList();
      } else if (_tabCtrl.index == 2) {
        // Groups tab — show empty for now
        filtered = [];
      }

      if (filtered.isEmpty) {
        return _EmptyState(isSearch: query.isNotEmpty);
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => _SwipeableConversationTile(
            key: ValueKey(filtered[i].id),
            conversation: filtered[i],
            isOnline: i % 3 == 0,
            index: i,
            onDelete: () => _confirmDelete(filtered[i]),
          ),
          childCount: filtered.length,
        ),
      );
    });
  }

  // ─── FAB ──────────────────────────────────────────────────────────────────

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppTheme.aurora1, AppTheme.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
              color: AppTheme.accent.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 6))
        ],
      ),
      child: FloatingActionButton(
        onPressed: _showNewChatDialog,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Icon(LucideIcons.pencil, color: Colors.white, size: 22),
      ),
    )
        .animate(delay: 500.ms)
        .scale(
            begin: const Offset(0, 0),
            curve: Curves.elasticOut,
            duration: 600.ms)
        .fadeIn();
  }

  // ─── Dialogs / Sheets ─────────────────────────────────────────────────────

  void _showNewChatDialog() {
    HapticFeedback.lightImpact();
    final nameCtrl = TextEditingController();
    Get.bottomSheet(
      _NewChatSheet(
        nameController: nameCtrl,
        onStart: () {
          if (nameCtrl.text.isNotEmpty) {
            _ctrl.createConversationByCode(nameCtrl.text.trim());
            Get.back();
          }
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _confirmDelete(Conversation c) {
    HapticFeedback.mediumImpact();
    Get.bottomSheet(
      _DeleteSheet(
        name: c.otherUserName ?? 'this chat',
        onDelete: () {
          _ctrl.deleteConversation(c.id);
          Get.back();
        },
      ),
      backgroundColor: Colors.transparent,
    );
  }

  void _showCopiedSnackbar(String code) {
    Get.snackbar(
      'Code Copied',
      'Share #$code to receive messages',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.card,
      colorText: AppTheme.textPrim,
      borderColor: AppTheme.border,
      borderWidth: 0.5,
      borderRadius: 16,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      duration: const Duration(seconds: 2),
      animationDuration: const Duration(milliseconds: 350),
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInCubic,
      icon: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
            color: AppTheme.accent.withOpacity(0.15), shape: BoxShape.circle),
        child: const Icon(LucideIcons.checkCircle,
            color: AppTheme.accent, size: 18),
      ),
      shouldIconPulse: false,
    );
  }
}

// ─── Aurora Background ─────────────────────────────────────────────────────


// ─── Segmented Tabs ───────────────────────────────────────────────────────



// ─── AppBar Menu ──────────────────────────────────────────────────────────


// ─── Swipeable Conversation Tile ──────────────────────────────────────────



// ─── Conversation Tile ────────────────────────────────────────────────────


// ─── Skeleton List ────────────────────────────────────────────────────────


// ─── Empty State ──────────────────────────────────────────────────────────


// ─── Bottom Sheets ────────────────────────────────────────────────────────

// ─── PATCH 1: _NewChatSheet — fix overflow when keyboard opens ───────────────
// Replace the existing _NewChatSheet class with this version.
// Key changes:
//   • Wrap Column in SingleChildScrollView so keyboard never causes overflow
//   • Use SafeArea for bottom padding instead of manual viewInsets calculation


