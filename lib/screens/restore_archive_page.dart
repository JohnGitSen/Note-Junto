import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RestoreArchivePage extends StatefulWidget {
  const RestoreArchivePage({super.key});

  @override
  State<RestoreArchivePage> createState() => _RestoreArchivePageState();
}

class _RestoreArchivePageState extends State<RestoreArchivePage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool _loading = true;
  bool _isRestoring = false;
  List<Map<String, dynamic>> _archivedNotes = [];
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadArchive();
  }

  Future<void> _loadArchive() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await _firestore
        .collection('notes-archive-backup')
        .where('ownerUid', isEqualTo: uid)
        .orderBy('archivedAt', descending: true)
        .get();

    if (mounted) {
      setState(() {
        _archivedNotes = snapshot.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          data['_docId'] = doc.id;
          return data;
        }).toList();
        _loading = false;
      });
    }
  }

  void _toggleSelect(String docId) {
    setState(() {
      if (_selectedIds.contains(docId)) {
        _selectedIds.remove(docId);
      } else {
        _selectedIds.add(docId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedIds.addAll(_archivedNotes.map((n) => n['_docId'] as String));
    });
  }

  void _clearSelection() {
    setState(() => _selectedIds.clear());
  }

  Future<void> _restore(List<Map<String, dynamic>> notesToRestore) async {
    if (notesToRestore.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 28, 35, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(
          Icons.restore_rounded,
          color: Color.fromARGB(255, 177, 206, 255),
          size: 40,
        ),
        title: const Text(
          'Restore Notes',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFEAEFF8),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Restore ${notesToRestore.length} note(s) back to your notes?\n\nThey will be added as new notes without removing any existing ones.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF8A96B0),
            fontSize: 13,
            height: 1.6,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 177, 206, 255),
                      foregroundColor: const Color.fromARGB(255, 14, 17, 22),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Restore',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF8A96B0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _isRestoring = true);

    try {
      final batch = _firestore.batch();

      for (final note in notesToRestore) {
        // Copy all original fields back into the notes collection
        // Strip out the archive-specific metadata fields before restoring
        final restored = Map<String, dynamic>.from(note)
          ..remove('_docId')
          ..remove('originalNoteId')
          ..remove('archivedAt')
          ..remove('archivedByUid');

        // Stamp a fresh updatedAt and createdAt so it appears as new
        restored['updatedAt'] = FieldValue.serverTimestamp();
        restored['createdAt'] = FieldValue.serverTimestamp();

        final newDocRef = _firestore.collection('notes').doc();
        batch.set(newDocRef, restored);
      }

      await batch.commit();

      if (mounted) {
        setState(() => _isRestoring = false);
        _showSnack('${notesToRestore.length} note(s) restored successfully!');
        _selectedIds.clear();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRestoring = false);
        _showSnack('Restore failed: $e', isError: true);
      }
    }
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';
    if (timestamp is Timestamp) {
      final dt = timestamp.toDate();
      return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return 'Unknown date';
  }

  @override
  Widget build(BuildContext context) {
    final bool allSelected =
        _archivedNotes.isNotEmpty &&
        _selectedIds.length == _archivedNotes.length;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 14, 17, 22),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 38, 47, 66),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color.fromARGB(255, 177, 206, 255),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Archived Notes',
          style: TextStyle(
            color: Color.fromARGB(255, 177, 206, 255),
            fontSize: 20,
          ),
        ),
        actions: [
          if (_archivedNotes.isNotEmpty)
            TextButton(
              onPressed: allSelected ? _clearSelection : _selectAll,
              child: Text(
                allSelected ? 'Deselect All' : 'Select All',
                style: const TextStyle(
                  color: Color.fromARGB(255, 177, 206, 255),
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 177, 206, 255),
              ),
            )
          : _archivedNotes.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.archive_outlined,
                    color: Color.fromARGB(255, 100, 130, 170),
                    size: 56,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No archived notes yet.',
                    style: TextStyle(
                      color: Color.fromARGB(255, 130, 150, 180),
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Use the archive button in My Notes\nto create a backup.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color.fromARGB(255, 80, 100, 130),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _archivedNotes.length,
                    itemBuilder: (context, index) {
                      final note = _archivedNotes[index];
                      final docId = note['_docId'] as String;
                      final title = note['title'] as String? ?? 'Untitled';
                      final archivedAt = note['archivedAt'];
                      final isSelected = _selectedIds.contains(docId);

                      return GestureDetector(
                        onTap: () => _toggleSelect(docId),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color.fromARGB(255, 40, 55, 80)
                                : const Color.fromARGB(255, 28, 35, 50),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? const Color.fromARGB(255, 177, 206, 255)
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: ListTile(
                            leading: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check_circle_rounded,
                                      key: ValueKey('checked'),
                                      color: Color.fromARGB(255, 177, 206, 255),
                                      size: 26,
                                    )
                                  : const Icon(
                                      Icons.circle_outlined,
                                      key: ValueKey('unchecked'),
                                      color: Color.fromARGB(255, 80, 100, 130),
                                      size: 26,
                                    ),
                            ),
                            title: Text(
                              title,
                              style: TextStyle(
                                color: isSelected
                                    ? const Color.fromARGB(255, 177, 206, 255)
                                    : Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              'Archived: ${_formatTimestamp(archivedAt)}',
                              style: const TextStyle(
                                color: Color.fromARGB(255, 80, 100, 130),
                                fontSize: 11,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.archive_outlined,
                              color: Color.fromARGB(255, 80, 100, 130),
                              size: 18,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

      // ── Bottom restore buttons ───────────────────────────────────────────────
      bottomNavigationBar: _archivedNotes.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _isRestoring
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color.fromARGB(255, 177, 206, 255),
                        ),
                      )
                    : Row(
                        children: [
                          // Restore Selected
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _selectedIds.isEmpty
                                  ? null
                                  : () {
                                      final selected = _archivedNotes
                                          .where(
                                            (n) => _selectedIds.contains(
                                              n['_docId'],
                                            ),
                                          )
                                          .toList();
                                      _restore(selected);
                                    },
                              icon: const Icon(
                                Icons.check_circle_outline,
                                size: 18,
                              ),
                              label: Text(
                                _selectedIds.isEmpty
                                    ? 'Restore Selected'
                                    : 'Restore (${_selectedIds.length})',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedIds.isEmpty
                                    ? const Color.fromARGB(255, 40, 50, 70)
                                    : const Color.fromARGB(255, 177, 206, 255),
                                foregroundColor: _selectedIds.isEmpty
                                    ? const Color.fromARGB(255, 80, 100, 130)
                                    : const Color.fromARGB(255, 14, 17, 22),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Restore All
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _restore(_archivedNotes),
                              icon: const Icon(Icons.restore_rounded, size: 18),
                              label: const Text('Restore All'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  38,
                                  50,
                                  75,
                                ),
                                foregroundColor: const Color.fromARGB(
                                  255,
                                  177,
                                  206,
                                  255,
                                ),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
    );
  }
}
