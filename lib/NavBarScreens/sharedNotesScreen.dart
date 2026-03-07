import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SharedNotesPage extends StatefulWidget {
  const SharedNotesPage({super.key});

  @override
  State<SharedNotesPage> createState() => _SharedNotesPageState();
}

String _extractPreview(String deltaJson, {int maxChars = 80}) {
  try {
    final List ops = jsonDecode(deltaJson);
    final buffer = StringBuffer();
    for (final op in ops) {
      if (op is Map && op['insert'] is String) {
        buffer.write(op['insert']);
        if (buffer.length >= maxChars) break;
      }
    }
    final text = buffer.toString().replaceAll('\n', ' ').trim();
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars)}...';
  } catch (_) {
    return '';
  }
}

String _formatTimestamp(Timestamp? timestamp) {
  if (timestamp == null) return '';
  return DateFormat('MMM d, yyyy').format(timestamp.toDate());
}

class SharedNoteCard extends StatelessWidget {
  final String title;
  final String description;
  final String date;
  final String ownerEmail;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const SharedNoteCard({
    super.key,
    required this.title,
    required this.description,
    required this.date,
    required this.ownerEmail,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color.fromARGB(255, 255, 180, 180)
                  : const Color.fromARGB(255, 194, 224, 255),
              borderRadius: BorderRadius.circular(15),
              border: isSelected
                  ? Border.all(color: Colors.red, width: 2)
                  : null,
            ),
            child: ListTile(
              minTileHeight: 120,
              leading: isSelected
                  ? const Icon(Icons.delete_outline, color: Colors.red)
                  : const Icon(Icons.note, color: Colors.blueGrey),
              title: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.red.shade800 : Colors.black,
                  decoration: isSelected ? TextDecoration.lineThrough : null,
                  decorationColor: Colors.red,
                  decorationThickness: 2,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? Colors.red.shade700 : Colors.black87,
                      decoration: isSelected
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        "Updated: $date",
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? Colors.red.shade400
                              : Colors.blueGrey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const Spacer(),
                      if (isSelected) ...[
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          "Will be removed",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else ...[
                        const Icon(
                          Icons.person,
                          size: 14,
                          color: Colors.blueGrey,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            "From: $ownerEmail",
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.blueGrey,
                              fontStyle: FontStyle.italic,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              horizontalTitleGap: 30,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              onTap: onTap,
              onLongPress: onLongPress,
            ),
          ),
          if (isSelected)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
        ],
      ),
    );
  }
}

class _SharedNotesPageState extends State<SharedNotesPage> {
  final String? _currentUserEmail = FirebaseAuth.instance.currentUser?.email;

  bool _isSelectionMode = false;
  final Set<String> _selectedNoteIds = {};

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedNoteIds.clear();
    });
  }

  void _toggleSelect(String noteId) {
    setState(() {
      if (_selectedNoteIds.contains(noteId)) {
        _selectedNoteIds.remove(noteId);
        if (_selectedNoteIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedNoteIds.add(noteId);
      }
    });
  }

  // Removes current user from sharedWith instead of deleting the note
  Future<void> _removeSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 38, 47, 66),
        title: const Text(
          'Remove Notes',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Remove ${_selectedNoteIds.length} shared note(s) from your list?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && _currentUserEmail != null) {
      final batch = FirebaseFirestore.instance.batch();
      for (final id in _selectedNoteIds) {
        batch.update(FirebaseFirestore.instance.collection('notes').doc(id), {
          'sharedWith': FieldValue.arrayRemove([_currentUserEmail]),
        });
      }
      await batch.commit();
      setState(() {
        _isSelectionMode = false;
        _selectedNoteIds.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserEmail == null) {
      return const Scaffold(
        backgroundColor: Color.fromARGB(255, 14, 17, 22),
        body: Center(
          child: Text('Not logged in.', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (_isSelectionMode) {
          setState(() {
            _isSelectionMode = false;
            _selectedNoteIds.clear();
          });
        }
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 14, 17, 22),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notes')
              .where('sharedWith', arrayContains: _currentUserEmail)
              .orderBy('updatedAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color.fromARGB(255, 177, 206, 255),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Something went wrong:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  'No shared notes yet.\nAsk someone to share a note with you!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color.fromARGB(255, 177, 206, 255),
                    fontSize: 16,
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final title = data['title'] as String? ?? 'Untitled';
                final bodyJson = data['body'] as String? ?? '[]';
                final ownerEmail = data['ownerEmail'] as String? ?? 'Unknown';
                final updatedAt = data['updatedAt'] as Timestamp?;
                final isSelected = _selectedNoteIds.contains(doc.id);

                return SharedNoteCard(
                  title: title,
                  description: _extractPreview(bodyJson),
                  date: _formatTimestamp(updatedAt),
                  ownerEmail: ownerEmail,
                  isSelected: isSelected,
                  onLongPress: () {
                    if (!_isSelectionMode) {
                      setState(() => _isSelectionMode = true);
                    }
                    _toggleSelect(doc.id);
                  },
                  onTap: () {
                    if (_isSelectionMode) {
                      _toggleSelect(doc.id);
                    } else {
                      Navigator.pushNamed(
                        context,
                        '/editViewNotesScreen',
                        arguments: {
                          'noteId': doc.id,
                          'title': title,
                          'body': bodyJson,
                          'isShared': true,
                        },
                      );
                    }
                  },
                );
              },
            );
          },
        ),
        floatingActionButton: _isSelectionMode
            ? Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FloatingActionButton.extended(
                    heroTag: 'shared_cancel',
                    onPressed: _toggleSelectionMode,
                    backgroundColor: const Color.fromARGB(255, 60, 70, 90),
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton.extended(
                    heroTag: 'shared_remove',
                    onPressed: _selectedNoteIds.isEmpty
                        ? null
                        : _removeSelected,
                    backgroundColor: _selectedNoteIds.isEmpty
                        ? Colors.grey
                        : Colors.redAccent,
                    icon: const Icon(Icons.person_remove, color: Colors.white),
                    label: Text(
                      'Remove (${_selectedNoteIds.length})',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
