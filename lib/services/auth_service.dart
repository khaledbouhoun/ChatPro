import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'hive_service.dart';
import '../models/user_model.dart';

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HiveService _hiveService = Get.find<HiveService>();

  final Rxn<User> firebaseUser = Rxn<User>();
  final RxBool isLoggedIn = false.obs;

  UserModel? get user => _hiveService.getUser();

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.authStateChanges());
    ever(firebaseUser, (user) {
      isLoggedIn.value = user != null;
    });
  }

  Future<AuthService> init() async {
    // Sign out Firebase session so user must re-enter credentials every launch.
    // BUT: clear Hive AFTER sign-out so the ConversationListController
    // can still read the userId during the current session transition.
    // Hive is only cleared here — it will be repopulated on next login.
    try {
      await _auth.signOut();
    } catch (_) {}

    // Clear the local session so getCurrentUserId() returns null
    // until the user logs in again this session.
    await _hiveService.clearAuthData();

    isLoggedIn.value = false;
    return this;
  }

  String generateChatCode(String name) {
    String prefix = name.replaceAll(' ', '').toUpperCase();
    if (prefix.length > 4) prefix = prefix.substring(0, 4);
    if (prefix.isEmpty) prefix = 'USER';
    final numbers = (Random().nextInt(9000) + 1000).toString();
    return '$prefix#$numbers';
  }

  // ─── Login ─────────────────────────────────────────────────────────────────

  Future<bool> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) return false;
      final uid = credential.user!.uid;

      // Try Firestore with short timeout
      UserModel? userModel;
      try {
        final userDoc = await _firestore.collection('users').doc(uid).get().timeout(const Duration(seconds: 5));

        if (userDoc.exists && userDoc.data() != null) {
          userModel = UserModel.fromFirestore(userDoc.data()!, userDoc.id);
        }
      } catch (e) {
        debugPrint('[Auth] Firestore unavailable, using Auth data: $e');
      }

      // Fallback: build from Firebase Auth if Firestore unreachable
      userModel ??= UserModel(
        id: uid,
        email: credential.user!.email ?? '',
        name: credential.user!.displayName ?? email.split('@')[0],
        photoUrl: credential.user!.photoURL,
        chatCode: generateChatCode(credential.user!.displayName ?? email.split('@')[0]),
      );

      // Save to Hive FIRST — this is what ConversationListController reads
      await _hiveService.saveUser(userModel);

      // Sync to Firestore in background
      _syncUserToFirestoreBackground(userModel);

      isLoggedIn.value = true;
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Login error: ${e.code} — ${e.message}');
    } catch (e) {
      debugPrint('Login error: $e');
    }
    return false;
  }

  // ─── Register ──────────────────────────────────────────────────────────────

  Future<bool> register(String email, String password, String name) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user == null) return false;

      await credential.user!.updateDisplayName(name);

      final userModel = UserModel(
        id: credential.user!.uid,
        email: credential.user!.email ?? '',
        name: name,
        chatCode: generateChatCode(name),
      );

      await _hiveService.saveUser(userModel);
      _syncUserToFirestoreBackground(userModel);
      isLoggedIn.value = true;
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Register error: ${e.code} — ${e.message}');
    } catch (e) {
      debugPrint('Register error: $e');
    }
    return false;
  }

  // ─── Background Firestore sync ─────────────────────────────────────────────

  void _syncUserToFirestoreBackground(UserModel user) {
    Future.microtask(() async {
      for (int attempt = 1; attempt <= 5; attempt++) {
        try {
          await _firestore.collection('users').doc(user.id).set({
            ...user.toFirestore(),
            'last_seen': FieldValue.serverTimestamp(),
            'is_online': true,
          }, SetOptions(merge: true));
          debugPrint('[Auth] User synced to Firestore ✓');
          return;
        } catch (e) {
          await Future.delayed(Duration(milliseconds: 1000 * attempt));
        }
      }
    });
  }

  // ─── Online status ─────────────────────────────────────────────────────────

  Future<void> setOnlineStatus(bool isOnline) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _firestore.collection('users').doc(uid).set({
        'is_online': isOnline,
        'last_seen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  // ─── Logout ────────────────────────────────────────────────────────────────

  void logout() async {
    await setOnlineStatus(false);
    await _auth.signOut();
    await _hiveService.clearAuthData();
    isLoggedIn.value = false;
    Get.offAllNamed('/login');
  }
}
