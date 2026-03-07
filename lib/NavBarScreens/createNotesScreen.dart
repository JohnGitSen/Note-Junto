import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  CollectionReference ref = FirebaseFirestore.instance.collection('notes');

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final json = jsonEncode(_descriptionController.document.toDelta().toJson());

    ref.add({
      'title': _titleController.text,
      'body': json,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isShared': true,
    });

    buildSnackBar(
      context,
      "Note Successfully Created!",
      backgroundColor: const Color.fromARGB(255, 99, 167, 255),
      duration: Durations.extralong4,
    );

    Navigator.pop(context);
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
            onPressed: () {},
            icon: const Icon(
              Icons.share,
              color: Color.fromARGB(255, 172, 202, 255),
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
