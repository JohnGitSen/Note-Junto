import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:notesharingapp/screens/restore_archive_page.dart';

enum NotesSortOrder { updatedDesc, updatedAsc, titleAsc, titleDesc }

extension NotesSortOrderLabel on NotesSortOrder {
  String get label {
    switch (this) {
      case NotesSortOrder.updatedDesc:
        return 'Newest first';
      case NotesSortOrder.updatedAsc:
        return 'Oldest first';
      case NotesSortOrder.titleAsc:
        return 'Title A → Z';
      case NotesSortOrder.titleDesc:
        return 'Title Z → A';
    }
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String _username = '';
  NotesSortOrder _sortOrder = NotesSortOrder.updatedDesc;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await _firestore.collection('users').doc(uid).get();

    if (userDoc.exists && mounted) {
      final data = userDoc.data() as Map<String, dynamic>;
      final sortStr = data['sortOrder'] as String?;

      setState(() {
        _username = data['username'] as String? ?? '';
        _sortOrder = NotesSortOrder.values.firstWhere(
          (e) => e.name == sortStr,
          orElse: () => NotesSortOrder.updatedDesc,
        );
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveToFirestore(Map<String, dynamic> data) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).update(data);
  }

  void _showEditUsername() {
    final controller = TextEditingController(text: _username);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 38, 47, 66),
        title: const Text(
          'Edit Username',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          cursorColor: const Color.fromARGB(255, 177, 206, 255),
          decoration: InputDecoration(
            hintText: 'Enter new username',
            hintStyle: const TextStyle(
              color: Color.fromARGB(255, 100, 120, 150),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color.fromARGB(255, 60, 75, 100),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color.fromARGB(255, 177, 206, 255),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;
              Navigator.pop(ctx);
              await _saveToFirestore({'username': newName});
              if (mounted) setState(() => _username = newName);
              _showSnack('Username updated!');
            },
            child: const Text(
              'Save',
              style: TextStyle(color: Color.fromARGB(255, 177, 206, 255)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSortOrder() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromARGB(255, 38, 47, 66),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 20, 0, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Sort Notes By',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...NotesSortOrder.values.map((order) {
              final isSelected = _sortOrder == order;
              return ListTile(
                tileColor: isSelected
                    ? const Color.fromARGB(60, 177, 206, 255)
                    : null,
                leading: Icon(
                  _sortIcon(order),
                  color: isSelected
                      ? const Color.fromARGB(255, 177, 206, 255)
                      : const Color.fromARGB(255, 130, 150, 180),
                ),
                title: Text(
                  order.label,
                  style: TextStyle(
                    color: isSelected
                        ? const Color.fromARGB(255, 177, 206, 255)
                        : Colors.white,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Color.fromARGB(255, 177, 206, 255),
                        size: 20,
                      )
                    : null,
                onTap: () async {
                  Navigator.pop(ctx);
                  await _saveToFirestore({'sortOrder': order.name});
                  if (mounted) setState(() => _sortOrder = order);
                  _showSnack('Sort order updated!');
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  IconData _sortIcon(NotesSortOrder order) {
    switch (order) {
      case NotesSortOrder.updatedDesc:
        return Icons.arrow_downward_rounded;
      case NotesSortOrder.updatedAsc:
        return Icons.arrow_upward_rounded;
      case NotesSortOrder.titleAsc:
        return Icons.sort_by_alpha_rounded;
      case NotesSortOrder.titleDesc:
        return Icons.sort_rounded;
    }
  }

  void _showDeleteAccount() {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 38, 47, 66),
        title: const Text(
          'Delete Account',
          style: TextStyle(color: Colors.redAccent),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will permanently delete your account and all your notes. This cannot be undone.',
              style: TextStyle(
                color: Color.fromARGB(255, 200, 200, 200),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Enter your password to confirm:',
              style: TextStyle(
                color: Color.fromARGB(255, 177, 206, 255),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              obscureText: true,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.redAccent,
              decoration: InputDecoration(
                hintText: 'Password',
                hintStyle: const TextStyle(
                  color: Color.fromARGB(255, 100, 120, 150),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.redAccent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Colors.redAccent,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              final password = passwordController.text;
              if (password.isEmpty) return;
              Navigator.pop(ctx);
              await _deleteAccount(password);
            },
            child: const Text(
              'Delete Forever',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      final notesBatch = _firestore.batch();
      final notes = await _firestore
          .collection('notes')
          .where('ownerUid', isEqualTo: user.uid)
          .get();
      for (final doc in notes.docs) {
        notesBatch.delete(doc.reference);
      }
      await notesBatch.commit();

      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } on FirebaseAuthException catch (e) {
      _showSnack(
        e.code == 'wrong-password'
            ? 'Incorrect password.'
            : 'Failed: ${e.message}',
        isError: true,
      );
    } catch (e) {
      _showSnack('Something went wrong: $e', isError: true);
    }
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 38, 47, 66),
        title: const Text(
          'About',
          style: TextStyle(color: Color.fromARGB(255, 177, 206, 255)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _aboutRow(Icons.notes_rounded, 'App', 'Note Sharing App'),
            const SizedBox(height: 10),
            _aboutRow(Icons.tag_rounded, 'Version', 'ver. 0.6.7'),
            const SizedBox(height: 10),
            _aboutRow(
              Icons.person_outline_rounded,
              'Signed in as',
              _auth.currentUser?.email ?? '—',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Close',
              style: TextStyle(color: Color.fromARGB(255, 177, 206, 255)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aboutRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color.fromARGB(255, 130, 150, 180)),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color.fromARGB(255, 130, 150, 180),
                fontSize: 11,
              ),
            ),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Colors.redAccent
            : const Color.fromARGB(255, 99, 167, 255),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color.fromARGB(255, 14, 17, 22),
        body: Center(
          child: CircularProgressIndicator(
            color: Color.fromARGB(255, 177, 206, 255),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 14, 17, 22),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          _sectionLabel('Account'),
          _settingsTile(
            icon: Icons.person_outline_rounded,
            title: 'Username',
            subtitle: _username.isNotEmpty ? _username : 'Not set',
            onTap: _showEditUsername,
          ),
          const SizedBox(height: 24),
          _sectionLabel('Preferences'),
          _settingsTile(
            icon: Icons.sort_rounded,
            title: 'Sort Notes By',
            subtitle: _sortOrder.label,
            onTap: _showSortOrder,
          ),
          const SizedBox(height: 24),
          _sectionLabel('Backup & Restore'),
          _settingsTile(
            icon: Icons.restore_rounded,
            title: 'Restore Archived Notes',
            subtitle: 'View and recover notes from your archive',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const RestoreArchivePage(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          _sectionLabel('Danger Zone'),
          _settingsTile(
            icon: Icons.delete_forever_rounded,
            title: 'Delete Account',
            subtitle: 'Permanently remove your account and notes',
            iconColor: Colors.redAccent,
            titleColor: Colors.redAccent,
            onTap: _showDeleteAccount,
          ),
          const SizedBox(height: 24),
          _sectionLabel('About'),
          _settingsTile(
            icon: Icons.info_outline_rounded,
            title: 'About this app',
            subtitle: 'ver. 0.6.7',
            onTap: _showAbout,
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Color.fromARGB(255, 100, 130, 170),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    Color? iconColor,
    Color? titleColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 28, 35, 50),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        onTap: onTap,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(
          icon,
          color: iconColor ?? const Color.fromARGB(255, 177, 206, 255),
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: titleColor ?? Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Color.fromARGB(255, 110, 130, 160),
            fontSize: 12,
          ),
        ),
        trailing: trailing ??
            const Icon(
              Icons.chevron_right_rounded,
              color: Color.fromARGB(255, 80, 100, 130),
              size: 20,
            ),
      ),
    );
  }
}