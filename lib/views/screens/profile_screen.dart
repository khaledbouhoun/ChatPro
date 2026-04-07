import 'dart:ui';

import 'package:chat_pro/core/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../services/auth_service.dart';
import '../../services/hive_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AuthService _auth;
  late final HiveService _hive;

  final RxBool _notificationsEnabled = true.obs;
  final RxBool _readReceipts = true.obs;
  final RxBool _onlineStatus = true.obs;

  @override
  void initState() {
    super.initState();
    _auth = Get.find<AuthService>();
    _hive = Get.find<HiveService>();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = _hive.getUser();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.bg,
        body: Stack(
          children: [
            // Aurora orbs
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                      colors: [Color(0x1A0EA5E9), Colors.transparent]),
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              left: -80,
              child: Container(
                width: 220,
                height: 220,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                      colors: [Color(0x126366F1), Colors.transparent]),
                ),
              ),
            ),

            // Main content
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Sliver AppBar ──────────────────────────────────────────
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  leading: IconButton(
                    icon: const Icon(LucideIcons.chevronLeft,
                        color: AppTheme.textPrim),
                    onPressed: () => Get.back(),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    background: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          color: AppTheme.bg.withValues(alpha: 0.5),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Avatar
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppTheme.aurora1,
                                      AppTheme.aurora2
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.accent
                                          .withValues(alpha: 0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const Icon(LucideIcons.user,
                                    size: 36, color: Colors.white),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                user?.name ?? 'User',
                                style: const TextStyle(
                                  color: AppTheme.textPrim,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(user?.email ?? '',
                                  style: const TextStyle(
                                      color: AppTheme.textSec, fontSize: 13)),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Chat Code ─────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _buildChatCodeCard(user?.chatCode ?? ''),
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                ),

                // ── Account Section ───────────────────────────────────────
                SliverToBoxAdapter(child: _SectionHeader(title: 'Account')),
                SliverToBoxAdapter(
                  child: _SettingsGroup(
                    children: [
                      _SettingsTile(
                        icon: LucideIcons.user,
                        title: 'Edit Profile',
                        subtitle: 'Change name and photo',
                        onTap: () => _showEditProfile(),
                      ),
                      _SettingsTile(
                        icon: LucideIcons.lock,
                        title: 'Change Password',
                        subtitle: 'Update your password',
                        onTap: () => _showChangePassword(),
                      ),
                      _SettingsTile(
                        icon: LucideIcons.mail,
                        title: 'Email',
                        subtitle: user?.email ?? '',
                        onTap: () {},
                        showChevron: false,
                      ),
                    ],
                  ).animate().fadeIn(delay: 150.ms),
                ),

                // ── Privacy Section ───────────────────────────────────────
                SliverToBoxAdapter(child: _SectionHeader(title: 'Privacy')),
                SliverToBoxAdapter(
                  child: _SettingsGroup(
                    children: [
                      Obx(
                        () => _ToggleTile(
                          icon: LucideIcons.eye,
                          title: 'Show Online Status',
                          value: _onlineStatus.value,
                          onChanged: (v) => _onlineStatus.value = v,
                        ),
                      ),
                      Obx(
                        () => _ToggleTile(
                          icon: LucideIcons.checkCheck,
                          title: 'Read Receipts',
                          value: _readReceipts.value,
                          onChanged: (v) => _readReceipts.value = v,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms),
                ),

                // ── Notifications Section ─────────────────────────────────
                SliverToBoxAdapter(
                    child: _SectionHeader(title: 'Notifications')),
                SliverToBoxAdapter(
                  child: _SettingsGroup(
                    children: [
                      Obx(
                        () => _ToggleTile(
                          icon: LucideIcons.bell,
                          title: 'Push Notifications',
                          value: _notificationsEnabled.value,
                          onChanged: (v) => _notificationsEnabled.value = v,
                        ),
                      ),
                      _SettingsTile(
                        icon: LucideIcons.checkCheck,
                        title: 'Mark All Messages as Read',
                        subtitle: 'Clear all unread badges',
                        onTap: () => _markAllConversationsRead(),
                      ),
                    ],
                  ).animate().fadeIn(delay: 250.ms),
                ),

                // ── Storage Section ───────────────────────────────────────
                SliverToBoxAdapter(child: _SectionHeader(title: 'Storage')),
                SliverToBoxAdapter(
                  child: _SettingsGroup(
                    children: [
                      _SettingsTile(
                        icon: LucideIcons.hardDrive,
                        title: 'Clear Local Cache',
                        subtitle: 'Remove cached messages',
                        onTap: () => _confirmClearCache(),
                      ),
                      _SettingsTile(
                        icon: LucideIcons.download,
                        title: 'Auto-download Media',
                        subtitle: 'Wi-Fi only',
                        onTap: () {},
                      ),
                    ],
                  ).animate().fadeIn(delay: 300.ms),
                ),

                // ── Danger Zone ───────────────────────────────────────────
                SliverToBoxAdapter(
                    child: _SectionHeader(title: 'Account Actions')),
                SliverToBoxAdapter(
                  child: _SettingsGroup(
                    children: [
                      _SettingsTile(
                        icon: LucideIcons.logOut,
                        title: 'Sign Out',
                        color: AppTheme.error,
                        onTap: () => _confirmSignOut(),
                      ),
                      _SettingsTile(
                        icon: LucideIcons.userX,
                        title: 'Delete Account',
                        subtitle: 'Permanently delete your account',
                        color: AppTheme.error,
                        onTap: () => _confirmDeleteAccount(),
                      ),
                    ],
                  ).animate().fadeIn(delay: 350.ms),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Chat Code Card ────────────────────────────────────────────────────────

  Widget _buildChatCodeCard(String code) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: code));
        HapticFeedback.lightImpact();
        Get.snackbar(
          'Copied!',
          'Your chat code has been copied',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.card,
          colorText: AppTheme.textPrim,
          borderColor: AppTheme.border,
          borderRadius: 16,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          duration: const Duration(seconds: 2),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.accent.withValues(alpha: 0.08),
              AppTheme.aurora2.withValues(alpha: 0.06)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle),
              child: const Icon(LucideIcons.hash,
                  color: AppTheme.accent, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Chat Code',
                    style: TextStyle(
                        color: AppTheme.textSec,
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    code,
                    style: const TextStyle(
                      color: AppTheme.textPrim,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.copy, color: AppTheme.accent, size: 16),
          ],
        ),
      ),
    );
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  void _showEditProfile() {
    final nameCtrl = TextEditingController(text: _hive.getUser()?.name ?? '');
    Get.bottomSheet(
      _SimpleInputSheet(
        title: 'Edit Profile',
        icon: LucideIcons.user,
        label: 'Display Name',
        controller: nameCtrl,
        onSave: (value) async {
          if (value.isEmpty) return;
          try {
            await FirebaseAuth.instance.currentUser?.updateDisplayName(value);
            final user = _hive.getUser();
            if (user != null) {
              await _hive.saveUser(
                user,
              );
              // Update Firestore
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.id)
                  .update({'name': value});
            }
            Get.snackbar(
              'Success',
              'Profile updated',
              backgroundColor: AppTheme.card,
              colorText: AppTheme.textPrim,
              snackPosition: SnackPosition.BOTTOM,
            );
          } catch (e) {
            Get.snackbar('Error', 'Failed to update profile',
                backgroundColor: AppTheme.card, colorText: AppTheme.textPrim);
          }
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showChangePassword() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    Get.bottomSheet(
      _ChangePasswordSheet(
        currentController: currentCtrl,
        newController: newCtrl,
        confirmController: confirmCtrl,
        onSave: () async {
          if (newCtrl.text != confirmCtrl.text) {
            Get.snackbar('Error', 'Passwords do not match',
                backgroundColor: AppTheme.card, colorText: AppTheme.textPrim);
            return;
          }
          if (newCtrl.text.length < 6) {
            Get.snackbar(
              'Error',
              'Password must be at least 6 characters',
              backgroundColor: AppTheme.card,
              colorText: AppTheme.textPrim,
            );
            return;
          }
          try {
            final user = FirebaseAuth.instance.currentUser;
            if (user == null) return;
            // Re-authenticate
            final cred = EmailAuthProvider.credential(
                email: user.email!, password: currentCtrl.text);
            await user.reauthenticateWithCredential(cred);
            await user.updatePassword(newCtrl.text);
            Get.back();
            Get.snackbar(
              'Success',
              'Password changed successfully',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppTheme.card,
              colorText: AppTheme.textPrim,
            );
          } on FirebaseAuthException catch (e) {
            Get.snackbar(
              'Error',
              e.message ?? 'Failed to change password',
              backgroundColor: AppTheme.card,
              colorText: AppTheme.textPrim,
            );
          }
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> _markAllConversationsRead() async {
    HapticFeedback.lightImpact();
    try {
      final userId = _hive.getCurrentUserId();
      if (userId == null) return;
      final convs = await FirebaseFirestore.instance
          .collection('conversations')
          .where('participants_ids', arrayContains: userId)
          .get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in convs.docs) {
        batch.update(doc.reference, {'participants.$userId.unread_count': 0});
      }
      await batch.commit();
      Get.snackbar(
        'Done',
        'All conversations marked as read',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.card,
        colorText: AppTheme.textPrim,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed: $e',
          backgroundColor: AppTheme.card, colorText: AppTheme.textPrim);
    }
  }

  void _confirmClearCache() {
    Get.bottomSheet(
      _ConfirmSheet(
        icon: LucideIcons.hardDrive,
        title: 'Clear Cache?',
        message:
            'This will remove locally cached messages. They will reload from the server.',
        confirmLabel: 'Clear',
        confirmColor: AppTheme.error,
        onConfirm: () async {
          await _hive.clearAll();
          Get.snackbar(
            'Done',
            'Cache cleared',
            backgroundColor: AppTheme.card,
            colorText: AppTheme.textPrim,
            snackPosition: SnackPosition.BOTTOM,
          );
        },
      ),
      backgroundColor: Colors.transparent,
    );
  }

  void _confirmSignOut() {
    Get.bottomSheet(
      _ConfirmSheet(
        icon: LucideIcons.logOut,
        title: 'Sign Out?',
        message: 'You will be signed out of your account.',
        confirmLabel: 'Sign Out',
        confirmColor: AppTheme.error,
        onConfirm: () => _auth.logout(),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  void _confirmDeleteAccount() {
    Get.bottomSheet(
      _ConfirmSheet(
        icon: LucideIcons.userX,
        title: 'Delete Account?',
        message:
            'This will permanently delete your account and all data. This action cannot be undone.',
        confirmLabel: 'Delete',
        confirmColor: AppTheme.error,
        onConfirm: () async {
          try {
            final user = FirebaseAuth.instance.currentUser;
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user?.uid)
                .delete();
            await user?.delete();
            await _hive.clearAll();
            Get.offAllNamed('/login');
          } catch (e) {
            Get.snackbar(
              'Error',
              'Failed to delete account. Please re-authenticate and try again.',
              backgroundColor: AppTheme.card,
              colorText: AppTheme.textPrim,
            );
          }
        },
      ),
      backgroundColor: Colors.transparent,
    );
  }
}

// ─── Section Header ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8),
      ),
    );
  }
}

// ─── Settings Group ────────────────────────────────────────────────────────

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(
        children: children
            .asMap()
            .entries
            .map(
              (e) => Column(
                children: [
                  e.value,
                  if (e.key < children.length - 1)
                    Divider(
                        height: 0,
                        thickness: 0.5,
                        color: AppTheme.border,
                        indent: 54),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

// ─── Settings Tile ─────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? color;
  final bool showChevron;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.color,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.textPrim;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: c, size: 17),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                          color: c, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!,
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              if (showChevron)
                const Icon(LucideIcons.chevronRight,
                    color: AppTheme.textMuted, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Toggle Tile ────────────────────────────────────────────────────────────

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile(
      {required this.icon,
      required this.title,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: AppTheme.textSec.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppTheme.textSec, size: 17),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                  color: AppTheme.textPrim,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Switch.adaptive(
              value: value, onChanged: onChanged, activeColor: AppTheme.accent),
        ],
      ),
    );
  }
}

// ─── Bottom Sheets ─────────────────────────────────────────────────────────

class _SimpleInputSheet extends StatelessWidget {
  final String title;
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final Future<void> Function(String) onSave;

  const _SimpleInputSheet({
    required this.title,
    required this.icon,
    required this.label,
    required this.controller,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    color: AppTheme.accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle),
                child: Icon(icon, color: AppTheme.accent, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                    color: AppTheme.textPrim,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border, width: 0.8),
            ),
            child: TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: AppTheme.textPrim, fontSize: 14),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(color: AppTheme.textMuted),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Get.back();
                onSave(controller.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Save',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  final TextEditingController currentController;
  final TextEditingController newController;
  final TextEditingController confirmController;
  final VoidCallback onSave;

  const _ChangePasswordSheet({
    required this.currentController,
    required this.newController,
    required this.confirmController,
    required this.onSave,
  });

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  bool _obscure1 = true, _obscure2 = true, _obscure3 = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    color: AppTheme.accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle),
                child: const Icon(LucideIcons.lock,
                    color: AppTheme.accent, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Change Password',
                style: TextStyle(
                    color: AppTheme.textPrim,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _PasswordField(
            label: 'Current Password',
            controller: widget.currentController,
            obscure: _obscure1,
            onToggle: () => setState(() => _obscure1 = !_obscure1),
          ),
          const SizedBox(height: 12),
          _PasswordField(
            label: 'New Password',
            controller: widget.newController,
            obscure: _obscure2,
            onToggle: () => setState(() => _obscure2 = !_obscure2),
          ),
          const SizedBox(height: 12),
          _PasswordField(
            label: 'Confirm New Password',
            controller: widget.confirmController,
            obscure: _obscure3,
            onToggle: () => setState(() => _obscure3 = !_obscure3),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Get.back();
                widget.onSave();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Update Password',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  const _PasswordField(
      {required this.label,
      required this.controller,
      required this.obscure,
      required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border, width: 0.8),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              style: const TextStyle(color: AppTheme.textPrim, fontSize: 14),
              decoration: InputDecoration(
                labelText: label,
                labelStyle:
                    const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(obscure ? LucideIcons.eye : LucideIcons.eyeOff,
                  size: 18, color: AppTheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmSheet extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;
  final VoidCallback onConfirm;

  const _ConfirmSheet({
    required this.icon,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
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
          const SizedBox(height: 24),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                color: confirmColor.withValues(alpha: 0.12),
                shape: BoxShape.circle),
            child: Icon(icon, color: confirmColor, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
                color: AppTheme.textPrim,
                fontSize: 18,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppTheme.textMuted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSec,
                    side: const BorderSide(color: AppTheme.border),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Get.back();
                    onConfirm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(confirmLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
