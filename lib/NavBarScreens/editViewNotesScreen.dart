import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notesharingapp/widgets/base64_image_embed.dart';
import 'package:notesharingapp/widgets/note_color_picker.dart';
import 'package:notesharingapp/widgets/note_comments_panel.dart';
import 'package:notesharingapp/widgets/note_pdf_exporter.dart';
import 'package:notesharingapp/widgets/presence_avatar.dart';
import 'package:notesharingapp/widgets/share_dialog.dart';

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
  bool _isUploadingImage = false;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _imagePicker = ImagePicker();

  String? _currentUid;
  String _currentUsername = '';
  bool _isTyping = false;
  Timer? _typingTimer;
  Timer? _autoSaveTimer;

  List<String> _sharedWith = [];
  Map<String, Map<String, dynamic>> _presenceMap = {};
  StreamSubscription? _presenceSub;
  StreamSubscription? _noteSub;

  bool _isSavingLocal = false;
  String _lastSavedBody = '';
  String _lastSavedTitle = '';

  Color _noteColor = kNoteColors[0];

  // Stable controller references — never recreated inline in build()
  final ScrollController _editorScrollController = ScrollController();
  final FocusNode _editorFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _lastSavedTitle = widget.title;

    try {
      final doc = Document.fromJson(jsonDecode(widget.body));
      _controller = QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (_) {
      _controller = QuillController.basic();
    }

    _lastSavedBody = widget.body;
    _controller.document.changes.listen((_) => _onTyping());

    _initPresence();
    _listenToNoteChanges();
    _loadSharedWith();
    _loadNoteColor();
  }

  Future<void> _loadNoteColor() async {
    final doc = await _firestore.collection('notes').doc(widget.noteId).get();
    if (doc.exists) {
      final hex = doc.data()?['noteColor'] as String?;
      if (hex != null && mounted) {
        setState(() => _noteColor = hexToColor(hex));
      }
    }
  }

  Future<void> _loadSharedWith() async {
    final doc = await _firestore.collection('notes').doc(widget.noteId).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _sharedWith = List<String>.from(data['sharedWith'] ?? []);
      });
    }
  }

  Future<void> _saveSharedWith() async {
    await _firestore.collection('notes').doc(widget.noteId).update({
      'sharedWith': _sharedWith,
      'isShared': _sharedWith.isNotEmpty,
    });
  }

  void _listenToNoteChanges() {
    _noteSub = _firestore
        .collection('notes')
        .doc(widget.noteId)
        .snapshots()
        .listen((snapshot) {
          if (!snapshot.exists || !mounted) return;

          final data = snapshot.data()!;

          final hex = data['noteColor'] as String?;
          if (hex != null) {
            final incoming = hexToColor(hex);
            if (incoming.value != _noteColor.value && !_isSavingLocal) {
              setState(() => _noteColor = incoming);
            }
          }

          if (_isSavingLocal) return;

          final newTitle = data['title'] as String? ?? '';
          final newBodyJson = data['body'] as String? ?? '[]';

          final titleChanged = newTitle != _lastSavedTitle;
          final bodyChanged = newBodyJson != _lastSavedBody;

          if (titleChanged && _titleController.text != newTitle) {
            _titleController.text = newTitle;
            _lastSavedTitle = newTitle;
          }

          if (bodyChanged) {
            try {
              final newDoc = Document.fromJson(jsonDecode(newBodyJson));
              final docLength = newDoc.length;

              // Clamp selection so it never exceeds the new document length.
              // This prevents the Flutter assertion error (_elements.contains)
              // that flashes red when a remote user deletes content and the
              // current cursor position is now out of bounds.
              final rawSelection = _controller.selection;
              final safeBase = rawSelection.baseOffset
                  .clamp(0, docLength - 1)
                  .toInt();
              final safeExtent = rawSelection.extentOffset
                  .clamp(0, docLength - 1)
                  .toInt();

              final newController = QuillController(
                document: newDoc,
                selection: TextSelection(
                  baseOffset: safeBase,
                  extentOffset: safeExtent,
                ),
              );

              newController.document.changes.listen((_) => _onTyping());

              setState(() {
                _controller.dispose();
                _controller = newController;
              });

              _lastSavedBody = newBodyJson;
            } catch (_) {}
          }
        });
  }

  Future<void> _initPresence() async {
    _currentUid = _auth.currentUser?.uid;
    if (_currentUid == null) return;

    final userDoc = await _firestore.collection('users').doc(_currentUid).get();
    _currentUsername = userDoc.data()?['username'] as String? ?? 'Unknown';

    final presenceRef = _firestore
        .collection('notes')
        .doc(widget.noteId)
        .collection('presence')
        .doc(_currentUid);

    await presenceRef.set({
      'username': _currentUsername,
      'isTyping': false,
      'lastSeen': FieldValue.serverTimestamp(),
    });

    _presenceSub = _firestore
        .collection('notes')
        .doc(widget.noteId)
        .collection('presence')
        .snapshots()
        .listen((snapshot) {
          final map = <String, Map<String, dynamic>>{};
          for (final doc in snapshot.docs) {
            if (doc.id == _currentUid) continue;
            final data = doc.data();
            map[doc.id] = {
              'username': data['username'] as String? ?? '?',
              'isTyping': data['isTyping'] as bool? ?? false,
            };
          }
          if (mounted) setState(() => _presenceMap = map);
        });
  }

  void _onTyping() {
    if (_currentUid == null) return;

    if (!_isTyping) {
      _isTyping = true;
      _firestore
          .collection('notes')
          .doc(widget.noteId)
          .collection('presence')
          .doc(_currentUid)
          .update({'isTyping': true, 'lastSeen': FieldValue.serverTimestamp()});
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 1), () {
      _isTyping = false;
      if (_currentUid != null) {
        _firestore
            .collection('notes')
            .doc(widget.noteId)
            .collection('presence')
            .doc(_currentUid)
            .update({'isTyping': false});
      }
    });

    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 800), _saveNote);
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

      final index = _controller.selection.baseOffset;
      final safeIndex = index < 0 ? 0 : index;

      _controller.document.insert(
        safeIndex,
        BlockEmbed.custom(CustomBlockEmbed('base64image', base64Str)),
      );

      _autoSaveTimer?.cancel();
      _autoSaveTimer = Timer(const Duration(milliseconds: 800), _saveNote);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to insert image: $e')));
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

  void _showSaveOptions() {
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
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'Save Options',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.save_rounded,
                color: Color.fromARGB(255, 172, 202, 255),
              ),
              title: const Text(
                'Save Note',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Save changes to the cloud',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _saveNote();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.picture_as_pdf_rounded,
                color: Color.fromARGB(255, 172, 202, 255),
              ),
              title: const Text(
                'Export as PDF',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Preview, share or download as PDF',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(ctx);
                NotePdfExporter.export(
                  context: context,
                  controller: _controller,
                  title: _titleController.text.trim(),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_currentUid != null) {
      _firestore
          .collection('notes')
          .doc(widget.noteId)
          .collection('presence')
          .doc(_currentUid)
          .delete();
    }
    _typingTimer?.cancel();
    _autoSaveTimer?.cancel();
    _presenceSub?.cancel();
    _noteSub?.cancel();
    _controller.dispose();
    _titleController.dispose();
    _editorScrollController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    // No setState — avoid triggering rebuilds during auto-save
    _isSaving = true;
    _isSavingLocal = true;

    try {
      final bodyJson = jsonEncode(_controller.document.toDelta().toJson());
      final sizeInKB = utf8.encode(bodyJson).length / 1024;

      if (sizeInKB > 900) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Note is too large to save! Try removing some images.',
              ),
              backgroundColor: Colors.redAccent,
              duration: Duration(seconds: 4),
            ),
          );
        }
        _isSaving = false;
        _isSavingLocal = false;
        return;
      }

      if (sizeInKB > 700) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Warning: Note is getting large. Avoid adding more images.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }

      final titleToSave = _titleController.text.trim();

      await _firestore.collection('notes').doc(widget.noteId).update({
        'title': titleToSave,
        'body': bodyJson,
        'noteColor': colorToHex(_noteColor),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _lastSavedBody = bodyJson;
      _lastSavedTitle = titleToSave;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      _isSaving = false;
      Future.delayed(const Duration(milliseconds: 600), () {
        _isSavingLocal = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final typingUsers = _presenceMap.entries
        .where((e) => e.value['isTyping'] == true)
        .map((e) => e.value['username'] as String)
        .toList();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _noteColor,
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
          if (_presenceMap.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: _presenceMap.entries
                    .map((e) => PresenceAvatar(uid: e.key, data: e.value))
                    .toList(),
              ),
            ),
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
            onPressed: () => NotePdfExporter.export(
              context: context,
              controller: _controller,
              title: _titleController.text.trim(),
            ),
            icon: const Icon(
              Icons.picture_as_pdf_rounded,
              color: Color.fromARGB(255, 172, 202, 255),
              size: 30,
            ),
          ),
          IconButton(
            onPressed: () => openShareDialog(
              context,
              _sharedWith,
              () {
                setState(() {});
                _saveSharedWith();
              },
              noteId: widget.noteId,
              noteTitle: _titleController.text.trim(),
            ),
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
      body: Stack(
        children: [
          Column(
            children: [
              NoteColorPicker(
                selectedColor: _noteColor,
                onColorSelected: (color) {
                  setState(() => _noteColor = color);
                  _firestore.collection('notes').doc(widget.noteId).update({
                    'noteColor': colorToHex(color),
                  });
                },
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: typingUsers.isNotEmpty
                    ? Container(
                        key: const ValueKey('typing'),
                        width: double.infinity,
                        color: const Color.fromARGB(255, 38, 47, 66),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: Text(
                          typingUsers.length == 1
                              ? '${typingUsers[0]} is typing...'
                              : '${typingUsers.join(', ')} are typing...',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    : const SizedBox(key: ValueKey('empty')),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: QuillEditor(
                    controller: _controller,
                    scrollController: _editorScrollController,
                    focusNode: _editorFocusNode,
                    config: QuillEditorConfig(
                      padding: const EdgeInsets.all(10),
                      embedBuilders: [Base64ImageEmbedBuilder()],
                    ),
                  ),
                ),
              ),
              const Divider(
                color: Color.fromARGB(121, 0, 14, 43),
                thickness: 5,
              ),
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
          NoteCommentsPanel(noteId: widget.noteId),
        ],
      ),
    );
  }
}
