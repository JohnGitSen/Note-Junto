import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyNotesPage extends StatefulWidget {
  const MyNotesPage({super.key});

  @override
  State<MyNotesPage> createState() => _MyNotesPageState();
}

// Extracts plain text from Quill Delta JSON string, limited to [maxChars]
String extractPreview(String deltaJson, {int maxChars = 80}) {
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

String formatTimestamp(Timestamp? timestamp) {
  if (timestamp == null) return '';
  return DateFormat('MMM d, yyyy').format(timestamp.toDate());
}

class NoteCard extends StatelessWidget {
  final String title;
  final String description;
  final String date;
  final bool isShared;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const NoteCard({
    super.key,
    required this.title,
    required this.description,
    required this.date,
    required this.isShared,
    required this.isSelectionMode,
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
                  : const Color.fromARGB(255, 252, 229, 148),
              borderRadius: BorderRadius.circular(15),
              border: isSelected
                  ? Border.all(color: Colors.red, width: 2)
                  : null,
            ),
            child: ListTile(
              minTileHeight: 120,
              leading: isSelected
                  ? const Icon(Icons.delete_outline, color: Colors.red)
                  : const Icon(Icons.note),
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
                              : Colors.brown,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const Spacer(),
                      if (isShared && !isSelected) ...[
                        const Icon(Icons.people, size: 14, color: Colors.brown),
                        const SizedBox(width: 4),
                        const Text(
                          "Shared",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.brown,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      if (isSelected) ...[
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          "Will be deleted",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.bold,
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

class _MyNotesPageState extends State<MyNotesPage> {
  final CollectionReference _notesRef = FirebaseFirestore.instance.collection(
    'notes',
  );

  // Only fetch notes belonging to the current user
  final String? _currentUserUid = FirebaseAuth.instance.currentUser?.uid;

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

  Future<void> _deleteSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 38, 47, 66),
        title: const Text(
          'Delete Notes',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete ${_selectedNoteIds.length} note(s)? This cannot be undone.',
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
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final batch = FirebaseFirestore.instance.batch();
      for (final id in _selectedNoteIds) {
        batch.delete(_notesRef.doc(id));
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
    if (_currentUserUid == null) {
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
          stream: _notesRef
              .where('ownerUid', isEqualTo: _currentUserUid)
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
                  'No notes yet.\nTap + to create one!',
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
                final isShared = data['isShared'] as bool? ?? false;
                final updatedAt = data['updatedAt'] as Timestamp?;
                final isSelected = _selectedNoteIds.contains(doc.id);

                return NoteCard(
                  title: title,
                  description: extractPreview(bodyJson),
                  date: formatTimestamp(updatedAt),
                  isShared: isShared,
                  isSelectionMode: _isSelectionMode,
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
                          'isShared': isShared,
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
                    heroTag: 'cancel',
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
                    heroTag: 'delete',
                    onPressed: _selectedNoteIds.isEmpty
                        ? null
                        : _deleteSelected,
                    backgroundColor: _selectedNoteIds.isEmpty
                        ? Colors.grey
                        : Colors.redAccent,
                    icon: const Icon(Icons.delete, color: Colors.white),
                    label: Text(
                      'Delete (${_selectedNoteIds.length})',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              )
            : FloatingActionButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/landingPage/mainAppPage/CreateNotesPage',
                  );
                },
                backgroundColor: const Color.fromARGB(255, 177, 206, 255),
                child: const Icon(Icons.note_add),
              ),
      ),
    );
  }
}
