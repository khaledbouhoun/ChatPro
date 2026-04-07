part of '../../screens/chat_screen.dart';

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  final ChatController ctrl;
  final RxBool searchActive;
  final TextEditingController searchCtrl;
  final FocusNode searchFocus;
  final VoidCallback onSearchActivated;
  final VoidCallback onSearchDismissed;

  const _AppBar({
    required this.ctrl,
    required this.searchActive,
    required this.searchCtrl,
    required this.searchFocus,
    required this.onSearchActivated,
    required this.onSearchDismissed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.bg.withValues(alpha: 0.7),
            border: const Border(
                bottom: BorderSide(color: AppTheme.border, width: 0.5)),
          ),
          child: SafeArea(
            bottom: false,
            child: Obx(() {
              if (searchActive.value) {
                return _buildSearchBar(context);
              }
              return _buildNormalBar(context);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNormalBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevronLeft,
                color: AppTheme.textPrim, size: 22),
            onPressed: () => Get.back(),
            splashRadius: 20,
          ),
          Obx(
            () => Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppTheme.aurora1, AppTheme.aurora2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: AppTheme.accent.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Icon(LucideIcons.user,
                      size: 18, color: Colors.white),
                ),
                if (ctrl.isOtherOnline.value)
                  Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: AppTheme.online,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.bg, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Obx(
                  () => Text(
                    ctrl.otherUserName.value.isNotEmpty
                        ? ctrl.otherUserName.value
                        : 'Loading…',
                    style: const TextStyle(
                      color: AppTheme.textPrim,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                Obx(() {
                  if (ctrl.isOtherTyping.value) {
                    return const Text(
                      'typing…',
                      style: TextStyle(
                          color: AppTheme.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                    );
                  }
                  if (ctrl.isOtherOnline.value) {
                    return Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                              color: AppTheme.online, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Active now',
                          style: TextStyle(
                              color: AppTheme.online,
                              fontSize: 11,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    );
                  }
                  return const Text('Offline',
                      style: TextStyle(color: AppTheme.textSec, fontSize: 11));
                }),
              ],
            ),
          ),
          _AppBarAction(icon: LucideIcons.phone, onTap: () {}),
          _AppBarAction(icon: LucideIcons.video, onTap: () {}),
          _AppBarAction(
            icon: LucideIcons.moreVertical,
            onTap: () => _showChatOptions(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: onSearchDismissed,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(LucideIcons.x, color: AppTheme.textSec, size: 20),
              ),
            ),
          ),
          Expanded(
            flex: 7,
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: Icon(LucideIcons.search,
                          size: 15, color: AppTheme.textMuted),
                    ),
                  ),
                  Expanded(
                    flex: 8,
                    child: TextField(
                      controller: searchCtrl,
                      focusNode: searchFocus,
                      style: const TextStyle(
                          color: AppTheme.textPrim, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Search in chat…',
                        hintStyle:
                            TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChatOptions(BuildContext context) {
    Get.bottomSheet(
      _ChatOptionsSheet(ctrl: ctrl, onSearchActivated: onSearchActivated),
      backgroundColor: Colors.transparent,
    );
  }
}
