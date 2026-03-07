import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  const NoteCard({
    super.key,
    required this.title,
    required this.description,
    required this.date,
    required this.isShared,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: ListTile(
        tileColor: const Color.fromARGB(255, 252, 229, 148),
        minTileHeight: 120,
        leading: const Icon(Icons.note),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  "Updated: $date",
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.brown,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Spacer(),
                if (isShared) ...[
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
              ],
            ),
          ],
        ),
        horizontalTitleGap: 30,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        onTap: () {},
      ),
    );
  }
}

class _MyNotesPageState extends State<MyNotesPage> {
  final CollectionReference _notesRef = FirebaseFirestore.instance.collection(
    'notes',
  );

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 14, 17, 22),
        body: StreamBuilder<QuerySnapshot>(
          stream: _notesRef.orderBy('updatedAt', descending: true).snapshots(),
          builder: (context, snapshot) {
            // Loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color.fromARGB(255, 177, 206, 255),
                ),
              );
            }

            // Error state
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Something went wrong:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            }

            // Empty state
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

            // Notes list
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final title = data['title'] as String? ?? 'Untitled';
                final bodyJson = data['body'] as String? ?? '[]';
                final isShared = data['isShared'] as bool? ?? false;
                final updatedAt = data['updatedAt'] as Timestamp?;

                return NoteCard(
                  title: title,
                  description: extractPreview(bodyJson),
                  date: formatTimestamp(updatedAt),
                  isShared: isShared,
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
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
