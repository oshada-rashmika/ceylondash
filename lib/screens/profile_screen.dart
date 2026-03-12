import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../models/user_model.dart';
import '../widgets/top_snackbar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();
  final StorageService _storage = StorageService();
  final ImagePicker _picker = ImagePicker();

  StreamSubscription<UserModel?>? _userSub;
  UserModel? _user;
  bool _loading = true;
  bool _uploading = false;

  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _slide = Tween(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _bindUser();
  }

  void _bindUser() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    _userSub = _db.streamUser(uid).listen((user) {
      if (!mounted) return;
      setState(() {
        _user = user;
        _loading = false;
      });
      if (!_animCtrl.isCompleted) _animCtrl.forward();
    });
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  // ───── helpers ─────

  String get _initials {
    final name = _user?.name ?? '';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  String? get _photoUrl => _user?.photoUrl;

  // ───── image actions ─────

  Future<void> _pickAndUpload() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (xFile == null) return;

    final file = File(xFile.path);
    if (!StorageService.isFileSizeValid(file)) {
      if (mounted) {
        TopSnackbar.show(
          context,
          message: 'Image must be less than 5 MB.',
          type: SnackbarType.error,
        );
      }
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _uploading = true);
    try {
      final url = await _storage.uploadProfilePicture(uid, file);
      await _db.updateUserFields(uid, {'photoUrl': url});
      if (mounted) {
        TopSnackbar.show(
          context,
          message: 'Profile photo updated!',
          type: SnackbarType.success,
        );
      }
    } catch (_) {
      if (mounted) {
        TopSnackbar.show(
          context,
          message: 'Upload failed. Please try again.',
          type: SnackbarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _removePhoto() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _uploading = true);
    try {
      await _storage.deleteProfilePicture(uid);
      await _db.updateUserFields(uid, {'photoUrl': FieldValue.delete()});
      if (mounted) {
        TopSnackbar.show(
          context,
          message: 'Photo removed.',
          type: SnackbarType.success,
        );
      }
    } catch (_) {
      if (mounted) {
        TopSnackbar.show(
          context,
          message: 'Could not remove photo.',
          type: SnackbarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showAvatarActions() {
    final hasPhoto = _photoUrl != null && _photoUrl!.isNotEmpty;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AvatarActionSheet(
        hasPhoto: hasPhoto,
        onView: () {
          Navigator.pop(context);
          _openFullScreenPhoto();
        },
        onUpload: () {
          Navigator.pop(context);
          _pickAndUpload();
        },
        onRemove: () {
          Navigator.pop(context);
          _removePhoto();
        },
      ),
    );
  }

  void _openFullScreenPhoto() {
    if (_photoUrl == null || _photoUrl!.isEmpty) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, anim, secondAnim) => FadeTransition(
          opacity: anim,
          child: _FullScreenPhoto(
            photoUrl: _photoUrl!,
            heroTag: 'profile-avatar',
          ),
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  // ───── build ─────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.cyan)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(child: _buildNameSection()),
              SliverToBoxAdapter(child: _buildInfoSection()),
              SliverToBoxAdapter(child: _buildSettingsSection()),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  // ───── sliver app bar ─────

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      surfaceTintColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Profile',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Color(0xFFF7F9FB)],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 48),
                _buildAvatar(),
                if (_uploading) ...[
                  const SizedBox(height: 12),
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.cyan,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───── avatar ─────

  Widget _buildAvatar() {
    final hasPhoto = _photoUrl != null && _photoUrl!.isNotEmpty;
    return GestureDetector(
      onTap: _showAvatarActions,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Hero(
            tag: 'profile-avatar',
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.cyan, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyan.withAlpha(50),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: ClipOval(
                child: hasPhoto
                    ? Image.network(
                        _photoUrl!,
                        fit: BoxFit.cover,
                        width: 110,
                        height: 110,
                        errorBuilder: (ctx, err, stack) => _initialsWidget(),
                      )
                    : _initialsWidget(),
              ),
            ),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.cyan,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _initialsWidget() {
    return Container(
      color: Colors.cyan,
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 40,
        ),
      ),
    );
  }

  // ───── name section ─────

  Widget _buildNameSection() {
    final name = _user?.name ?? 'Customer';
    final email =
        _user?.email ?? FirebaseAuth.instance.currentUser?.email ?? '—';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: const TextStyle(fontSize: 14, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  // ───── info tiles ─────

  Widget _buildInfoSection() {
    final phone = _user?.phone ?? '—';
    final email =
        _user?.email ?? FirebaseAuth.instance.currentUser?.email ?? '—';
    final address = _user?.address ?? '—';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              'Personal Info',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black38,
              ),
            ),
          ),
          _InfoTile(icon: Icons.phone_rounded, label: 'Phone', value: phone),
          _InfoTile(icon: Icons.email_rounded, label: 'Email', value: email),
          _InfoTile(
            icon: Icons.location_on_rounded,
            label: 'Address',
            value: address,
            iconColor: Colors.cyan,
          ),
        ],
      ),
    );
  }

  // ───── settings section ─────

  Widget _buildSettingsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              'Settings',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black38,
              ),
            ),
          ),
          _SettingsTile(
            icon: Icons.lock_rounded,
            label: 'Account Security',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.notifications_rounded,
            label: 'Notifications',
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.logout_rounded,
            label: 'Sign Out',
            isDestructive: true,
            onTap: _signOut,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Supporting widgets
// ═══════════════════════════════════════════════════════════════════════════════

class _AvatarActionSheet extends StatelessWidget {
  final bool hasPhoto;
  final VoidCallback onView;
  final VoidCallback onUpload;
  final VoidCallback onRemove;

  const _AvatarActionSheet({
    required this.hasPhoto,
    required this.onView,
    required this.onUpload,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            if (hasPhoto)
              _SheetOption(
                icon: Icons.visibility_rounded,
                label: 'View Photo',
                onTap: onView,
              ),
            _SheetOption(
              icon: Icons.photo_library_rounded,
              label: hasPhoto ? 'Update Photo' : 'Upload Profile Picture',
              onTap: onUpload,
            ),
            if (hasPhoto)
              _SheetOption(
                icon: Icons.delete_outline_rounded,
                label: 'Remove Photo',
                isDestructive: true,
                onTap: onRemove,
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red : Colors.black87;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullScreenPhoto extends StatelessWidget {
  final String photoUrl;
  final String heroTag;

  const _FullScreenPhoto({required this.photoUrl, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Hero(
            tag: heroTag,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                photoUrl,
                fit: BoxFit.contain,
                errorBuilder: (ctx, err, stack) => const Icon(
                  Icons.broken_image_rounded,
                  size: 64,
                  color: Colors.white54,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F7FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor ?? Colors.cyan, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.black38,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDestructive ? Colors.red : Colors.black87;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.cyan.withAlpha(30),
          highlightColor: Colors.cyan.withAlpha(15),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? Colors.red.withAlpha(18)
                        : const Color(0xFFE0F7FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive ? Colors.red : Colors.cyan,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: fg.withAlpha(100)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
