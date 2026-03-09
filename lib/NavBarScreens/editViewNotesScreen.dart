import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class EditViewNotesScreen extends StatefulWidget {
  final String noteId;
  final String title;
  final String body;
  final bool isShared;

  const EditViewNotesScreen({
    super.key,
    required this.noteId,
    required this.title,
    required this.body,
    required this.isShared,
  });

  @override
  State<EditViewNotesScreen> createState() => _EditViewNotesScreenState();
}

class _EditViewNotesScreenState extends State<EditViewNotesScreen> {
  late QuillController _controller;
  late TextEditingController _titleController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);

    try {
      final doc = Document.fromJson(jsonDecode(widget.body));
      _controller = QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (_) {
      _controller = QuillController.basic();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    setState(() => _isSaving = true);
    try {
      final bodyJson = jsonEncode(_controller.document.toDelta().toJson());
      await FirebaseFirestore.instance
          .collection('notes')
          .doc(widget.noteId)
          .update({
        'title': _titleController.text.trim(),
        'body': bodyJson,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Note saved!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color.fromARGB(255, 214, 215, 216),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 38, 47, 66),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
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
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color.fromARGB(255, 172, 202, 255),
                    ),
                  ),
                )
              : IconButton(
                  onPressed: _saveNote,
                  icon: const Icon(
                    Icons.save_rounded,
                    color: Color.fromARGB(255, 172, 202, 255),
                    size: 30,
                  ),
                ),
          if (widget.isShared)
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
          const Padding(padding: EdgeInsets.only(top: 2)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: QuillEditor.basic(
                controller: _controller,
                config: const QuillEditorConfig(
                  padding: EdgeInsetsGeometry.all(10),
                ),
              ),
            ),
          ),
          const Divider(color: Color.fromARGB(121, 0, 14, 43), thickness: 5),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: QuillSimpleToolbar(
              controller: _controller,
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