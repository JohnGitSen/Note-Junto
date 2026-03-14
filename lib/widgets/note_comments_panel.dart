import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notesharingapp/widgets/user_color.dart';

class NoteCommentsPanel extends StatefulWidget {
  final String noteId;

  const NoteCommentsPanel({super.key, required this.noteId});

  @override
  State<NoteCommentsPanel> createState() => _NoteCommentsPanelState();
}

class _NoteCommentsPanelState extends State<NoteCommentsPanel>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String _currentUsername = '';
  String? _currentUid;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    _currentUid = _auth.currentUser?.uid;
    if (_currentUid == null) return;
    final doc = await _firestore.collection('users').doc(_currentUid).get();
    if (doc.exists && mounted) {
      setState(() {
        _currentUsername = doc.data()?['username'] as String? ?? 'Unknown';
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _currentUid == null) return;
    setState(() => _isSending = true);
    try {
      await _firestore
          .collection('notes')
          .doc(widget.noteId)
          .collection('comments')
          .add({
            'uid': _currentUid,
            'username': _currentUsername,
            'text': text,
            'createdAt': FieldValue.serverTimestamp(),
          });
      _commentController.clear();
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Floating panel
        if (_isOpen)
          Positioned(
            right: 28,
            top: 0,
            bottom: 0,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 220,
                    height: 320,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 28, 35, 50),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                          decoration: const BoxDecoration(
                            color: Color.fromARGB(255, 38, 47, 66),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(18),
                              topRight: Radius.circular(18),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: Color.fromARGB(255, 177, 206, 255),
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Comments',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: _toggle,
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Color.fromARGB(255, 130, 150, 180),
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Comments list
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: _firestore
                                .collection('notes')
                                .doc(widget.noteId)
                                .collection('comments')
                                .orderBy('createdAt', descending: false)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: Color.fromARGB(255, 177, 206, 255),
                                    strokeWidth: 1.5,
                                  ),
                                );
                              }

                              final docs = snapshot.data?.docs ?? [];

                              if (docs.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'No comments yet.\nBe the first!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 100, 120, 160),
                                      fontSize: 11,
                                    ),
                                  ),
                                );
                              }

                              return ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 8,
                                ),
                                itemCount: docs.length,
                                itemBuilder: (context, index) {
                                  final data =
                                      docs[index].data()
                                          as Map<String, dynamic>;
                                  final uid = data['uid'] as String? ?? '';
                                  final username =
                                      data['username'] as String? ?? '?';
                                  final text = data['text'] as String? ?? '';
                                  final ts = data['createdAt'] as Timestamp?;
                                  final date = ts != null
                                      ? DateFormat(
                                          'MMM d, h:mm a',
                                        ).format(ts.toDate())
                                      : '';
                                  final isMe = uid == _currentUid;
                                  final color = userColor(uid);
                                  final initials = username.trim().isNotEmpty
                                      ? username.trim()[0].toUpperCase()
                                      : '?';

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Column(
                                      crossAxisAlignment: isMe
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: isMe
                                              ? MainAxisAlignment.end
                                              : MainAxisAlignment.start,
                                          children: [
                                            if (!isMe) ...[
                                              CircleAvatar(
                                                radius: 8,
                                                backgroundColor: color,
                                                child: Text(
                                                  initials,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 7,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 3),
                                            ],
                                            Flexible(
                                              child: Text(
                                                isMe ? 'You' : username,
                                                style: TextStyle(
                                                  color: isMe
                                                      ? const Color.fromARGB(
                                                          255,
                                                          177,
                                                          206,
                                                          255,
                                                        )
                                                      : color,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isMe
                                                ? const Color.fromARGB(
                                                    255,
                                                    50,
                                                    70,
                                                    110,
                                                  )
                                                : const Color.fromARGB(
                                                    255,
                                                    38,
                                                    47,
                                                    66,
                                                  ),
                                            borderRadius: BorderRadius.only(
                                              topLeft: const Radius.circular(
                                                10,
                                              ),
                                              topRight: const Radius.circular(
                                                10,
                                              ),
                                              bottomLeft: isMe
                                                  ? const Radius.circular(10)
                                                  : const Radius.circular(2),
                                              bottomRight: isMe
                                                  ? const Radius.circular(2)
                                                  : const Radius.circular(10),
                                            ),
                                          ),
                                          child: Text(
                                            text,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          date,
                                          style: const TextStyle(
                                            color: Color.fromARGB(
                                              255,
                                              80,
                                              100,
                                              130,
                                            ),
                                            fontSize: 8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),

                        // Input row
                        Container(
                          padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
                          decoration: const BoxDecoration(
                            color: Color.fromARGB(255, 38, 47, 66),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(18),
                              bottomRight: Radius.circular(18),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _commentController,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                  cursorColor: const Color.fromARGB(
                                    255,
                                    177,
                                    206,
                                    255,
                                  ),
                                  maxLines: 2,
                                  minLines: 1,
                                  textInputAction: TextInputAction.send,
                                  onSubmitted: (_) => _sendComment(),
                                  decoration: InputDecoration(
                                    hintText: 'Add a comment...',
                                    hintStyle: const TextStyle(
                                      color: Color.fromARGB(255, 90, 110, 140),
                                      fontSize: 11,
                                    ),
                                    filled: true,
                                    fillColor: const Color.fromARGB(
                                      255,
                                      22,
                                      28,
                                      42,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              GestureDetector(
                                onTap: _isSending ? null : _sendComment,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: _isSending
                                        ? const Color.fromARGB(255, 60, 75, 100)
                                        : const Color.fromARGB(
                                            255,
                                            99,
                                            136,
                                            255,
                                          ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: _isSending
                                      ? const Padding(
                                          padding: EdgeInsets.all(6),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.send_rounded,
                                          color: Colors.white,
                                          size: 13,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Tab button — vertically centered, stuck to right edge
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: Center(
            child: GestureDetector(
              onTap: _toggle,
              child: Container(
                width: 24,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 38, 47, 66),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(-2, 0),
                    ),
                  ],
                ),
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      _isOpen ? '›' : 'Comments',
                      style: const TextStyle(
                        color: Color.fromARGB(255, 177, 206, 255),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
