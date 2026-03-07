import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:notesharingapp/utils/SnackBarUtils.dart';

class CreateNotesPage extends StatefulWidget {
  const CreateNotesPage({super.key});

  @override
  State<CreateNotesPage> createState() => _CreateNotesPageState();
}

class _CreateNotesPageState extends State<CreateNotesPage> {
  final TextEditingController _titleController = TextEditingController();
  final QuillController _descriptionController = QuillController.basic();

  final List<String> _sharedWith = [];

  CollectionReference ref = FirebaseFirestore.instance.collection('notes');

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final json = jsonEncode(_descriptionController.document.toDelta().toJson());
    final currentUser = FirebaseAuth.instance.currentUser;

    ref.add({
      'title': _titleController.text,
      'body': json,
      'ownerUid': currentUser?.uid ?? '',
      'ownerEmail': currentUser?.email ?? '',
      'sharedWith': _sharedWith,
      'activeViewers': {},
      'lastEditedBy': '',
      'lastEditedByEmail': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isShared': _sharedWith.isNotEmpty,
    });

    buildSnackBar(
      context,
      "Note Successfully Created!",
      backgroundColor: const Color.fromARGB(255, 99, 167, 255),
      duration: Durations.extralong4,
    );

    Navigator.pop(context);
  }

  // Checks Firestore 'users' collection if email exists
  Future<bool> _doesUserExist(String email) async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  void _openShareDialog() {
    final TextEditingController _emailController = TextEditingController();
    bool _isChecking = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            Future<void> _addEmail() async {
              final email = _emailController.text.trim();
              final currentUserEmail =
                  FirebaseAuth.instance.currentUser?.email ?? '';

              if (email.isEmpty || !email.contains('@')) {
                buildSnackBar(ctx, 'Enter a valid email!');
                return;
              }
              if (email == currentUserEmail) {
                buildSnackBar(ctx, "You can't share a note with yourself!");
                return;
              }
              if (_sharedWith.contains(email)) {
                buildSnackBar(ctx, 'Already added this email!');
                return;
              }

              setDialogState(() => _isChecking = true);

              final exists = await _doesUserExist(email);

              setDialogState(() => _isChecking = false);

              if (!exists) {
                buildSnackBar(
                  ctx,
                  'User not found! Make sure they have an account.',
                  backgroundColor: Colors.redAccent,
                );
                return;
              }

              setDialogState(() {
                _sharedWith.add(email);
              });
              setState(() {});
              _emailController.clear();
            }

            return AlertDialog(
              backgroundColor: const Color.fromARGB(255, 38, 47, 66),
              title: const Text(
                'Share Note',
                style: TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Email input row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white),
                            onSubmitted: (_) => _addEmail(),
                            decoration: InputDecoration(
                              hintText: 'Enter email address',
                              hintStyle: const TextStyle(color: Colors.white38),
                              filled: true,
                              fillColor: const Color.fromARGB(255, 55, 65, 85),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _isChecking
                            ? const SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Color.fromARGB(255, 172, 202, 255),
                                ),
                              )
                            : IconButton(
                                onPressed: _addEmail,
                                icon: const Icon(
                                  Icons.add_circle,
                                  color: Color.fromARGB(255, 172, 202, 255),
                                  size: 32,
                                ),
                              ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // List of added emails
                    if (_sharedWith.isNotEmpty) ...[
                      const Text(
                        'Shared with:',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      ..._sharedWith.map(
                        (email) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 55, 65, 85),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.person,
                                  color: Colors.white54,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    email,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setDialogState(() {
                                      _sharedWith.remove(email);
                                    });
                                    setState(() {});
                                  },
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.redAccent,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ] else
                      const Text(
                        'No one added yet.',
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Done',
                    style: TextStyle(color: Color.fromARGB(255, 172, 202, 255)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 214, 215, 216),
      appBar: AppBar(
        title: TextField(
          controller: _titleController,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            overflow: TextOverflow.ellipsis,
          ),
          decoration: const InputDecoration(
            hintText: 'Title Note',
            hintStyle: TextStyle(color: Colors.white38, fontSize: 25),
            border: InputBorder.none,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 38, 47, 66),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: _saveNote,
            icon: const Icon(
              Icons.save_rounded,
              color: Color.fromARGB(255, 172, 202, 255),
              size: 30,
            ),
          ),
          IconButton(
            onPressed: _openShareDialog,
            icon: Icon(
              Icons.share,
              color: _sharedWith.isNotEmpty
                  ? Colors.greenAccent
                  : const Color.fromARGB(255, 172, 202, 255),
              size: 30,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(padding: EdgeInsets.only(top: 2)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: QuillEditor.basic(
                controller: _descriptionController,
                config: const QuillEditorConfig(
                  padding: EdgeInsetsGeometry.all(10),
                ),
              ),
            ),
          ),
          const Divider(color: Color.fromARGB(121, 0, 14, 43), thickness: 5),
          Padding(
            padding: EdgeInsetsGeometry.only(bottom: 10),
            child: QuillSimpleToolbar(
              controller: _descriptionController,
              config: const QuillSimpleToolbarConfig(
                showSubscript: false,
                showSuperscript: false,
                showClearFormat: false,
                showHeaderStyle: false,
                showListCheck: true,
                showInlineCode: false,
                showCodeBlock: false,
                showQuote: false,
                showIndent: false,
                showLink: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
