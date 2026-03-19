// ── share_dialog.dart ─────────────────────────────────────────────────────────
// Updated to send a share invite instead of directly adding to sharedWith.
// The noteId and noteTitle are now required so the invite can reference them.

import 'package:flutter/material.dart';
import 'package:notesharingapp/services/share_invite_service.dart';

void openShareDialog(
  BuildContext context,
  List<String> sharedWith,
  VoidCallback onChanged, {
  required String noteId,
  required String noteTitle,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color.fromARGB(255, 38, 47, 66),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _ShareDialog(
      sharedWith: sharedWith,
      onChanged: onChanged,
      noteId: noteId,
      noteTitle: noteTitle,
    ),
  );
}

class _ShareDialog extends StatefulWidget {
  final List<String> sharedWith;
  final VoidCallback onChanged;
  final String noteId;
  final String noteTitle;

  const _ShareDialog({
    required this.sharedWith,
    required this.onChanged,
    required this.noteId,
    required this.noteTitle,
  });

  @override
  State<_ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<_ShareDialog> {
  final _emailController = TextEditingController();
  bool _sending = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendInvite() async {
    final email = _emailController.text.trim().toLowerCase();

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter an email.');
      return;
    }

    if (!email.contains('@')) {
      setState(() => _errorMessage = 'Enter a valid email address.');
      return;
    }

    setState(() {
      _sending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await ShareInviteService.sendInvite(
        noteId: widget.noteId,
        noteTitle: widget.noteTitle,
        toEmail: email,
      );

      if (mounted) {
        setState(() {
          _successMessage = 'Invite sent to $email!';
          _sending = false;
          _emailController.clear();
        });
        widget.onChanged();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to send invite. Try again.';
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, keyboard + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color.fromARGB(80, 177, 206, 255),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Share Note',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'An invite will be sent — they can accept or decline.',
            style: TextStyle(
              color: Color.fromARGB(255, 100, 120, 150),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),

          // Email input row
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 22, 28, 42),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _errorMessage != null
                          ? const Color(0xFFFF5C5C).withOpacity(0.6)
                          : const Color.fromARGB(60, 177, 206, 255),
                    ),
                  ),
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Enter email address',
                      hintStyle: TextStyle(
                        color: Color.fromARGB(255, 80, 100, 130),
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: Color.fromARGB(255, 100, 120, 150),
                        size: 18,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (_) {
                      if (_errorMessage != null) {
                        setState(() => _errorMessage = null);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _sending ? null : _sendInvite,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 177, 206, 255),
                    foregroundColor: const Color.fromARGB(255, 14, 17, 22),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color.fromARGB(255, 14, 17, 22),
                          ),
                        )
                      : const Text(
                          'Send',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),

          // Error / success message
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFFF5C5C),
                  size: 13,
                ),
                const SizedBox(width: 5),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Color(0xFFFF5C5C),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
          if (_successMessage != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Color(0xFF64DC96),
                  size: 13,
                ),
                const SizedBox(width: 5),
                Text(
                  _successMessage!,
                  style: const TextStyle(
                    color: Color(0xFF64DC96),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],

          // Already shared with list
          if (widget.sharedWith.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'CURRENTLY SHARED WITH',
              style: TextStyle(
                color: Color.fromARGB(255, 80, 100, 130),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            ...widget.sharedWith.map(
              (email) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      color: Color.fromARGB(255, 100, 120, 150),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        email,
                        style: const TextStyle(
                          color: Color.fromARGB(255, 150, 170, 200),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
