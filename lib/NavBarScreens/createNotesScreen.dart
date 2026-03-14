import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notesharingapp/utils/SnackBarUtils.dart';
import 'package:notesharingapp/widgets/base64_image_embed.dart';
import 'package:notesharingapp/widgets/note_color_picker.dart';
import 'package:notesharingapp/widgets/share_dialog.dart';

class CreateNotesPage extends StatefulWidget {
  const CreateNotesPage({super.key});

  @override
  State<CreateNotesPage> createState() => _CreateNotesPageState();
}

class _CreateNotesPageState extends State<CreateNotesPage> {
  final TextEditingController _titleController = TextEditingController();
  final QuillController _descriptionController = QuillController.basic();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingImage = false;

  // Note color state — default yellow
  Color _noteColor = kNoteColors[0];

  final List<String> _sharedWith = [];

  CollectionReference ref = FirebaseFirestore.instance.collection('notes');

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final bodyJson = jsonEncode(
      _descriptionController.document.toDelta().toJson(),
    );

    final sizeInKB = utf8.encode(bodyJson).length / 1024;
    if (sizeInKB > 900) {
      if (mounted) {
        buildSnackBar(
          context,
          'Note is too large to save! Try removing some images.',
          backgroundColor: Colors.redAccent,
        );
      }
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;

    ref.add({
      'title': _titleController.text,
      'body': bodyJson,
      'ownerUid': currentUser?.uid ?? '',
      'ownerEmail': currentUser?.email ?? '',
      'sharedWith': _sharedWith,
      'activeViewers': {},
      'lastEditedBy': '',
      'lastEditedByEmail': '',
      'noteColor': colorToHex(_noteColor),
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isUploadingImage = true);

      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 50,
        maxWidth: 800,
      );

      if (picked == null) {
        setState(() => _isUploadingImage = false);
        return;
      }

      final bytes = await File(picked.path).readAsBytes();
      final base64Str = base64Encode(bytes);

      final index = _descriptionController.selection.baseOffset;
      final safeIndex = index < 0 ? 0 : index;

      _descriptionController.document.insert(
        safeIndex,
        BlockEmbed.custom(CustomBlockEmbed('base64image', base64Str)),
      );
    } catch (e) {
      if (mounted) {
        buildSnackBar(
          context,
          'Failed to insert image: $e',
          backgroundColor: Colors.redAccent,
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromARGB(255, 38, 47, 66),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Insert Image',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text(
                'Gallery',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text(
                'Camera',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _noteColor,
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
          _isUploadingImage
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
                  onPressed: _showImageSourceDialog,
                  icon: const Icon(
                    Icons.image_rounded,
                    color: Color.fromARGB(255, 172, 202, 255),
                    size: 28,
                  ),
                ),
          IconButton(
            onPressed: _saveNote,
            icon: const Icon(
              Icons.save_rounded,
              color: Color.fromARGB(255, 172, 202, 255),
              size: 30,
            ),
          ),
          IconButton(
            onPressed: () =>
                openShareDialog(context, _sharedWith, () => setState(() {})),
            icon: Icon(
              Icons.people,
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
          // Color picker row
          NoteColorPicker(
            selectedColor: _noteColor,
            onColorSelected: (color) => setState(() => _noteColor = color),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: QuillEditor(
                controller: _descriptionController,
                scrollController: ScrollController(),
                focusNode: FocusNode(),
                config: QuillEditorConfig(
                  padding: const EdgeInsets.all(10),
                  embedBuilders: [Base64ImageEmbedBuilder()],
                ),
              ),
            ),
          ),
          const Divider(color: Color.fromARGB(121, 0, 14, 43), thickness: 5),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
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